#!/bin/sh

set -eu

LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

log() {
  printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

error_exit() {
  log "ERROR: $1"
  exit 1
}

# --- Collect Parameters ---
log "INFO: Starting deployment process"

printf "Git Repository URL: "
read -r REPO_URL || error_exit "Repository URL is required."

printf "Personal Access Token (PAT): "
read -r PAT || error_exit "PAT is required."

printf "Branch name [default: main]: "
read -r BRANCH
BRANCH=${BRANCH:-main}

printf "Server username: "
read -r USERNAME || error_exit "Server username is required."

printf "Server IP address: "
read -r SERVER_IP || error_exit "Server IP address is required."

printf "SSH key path: "
read -r SSH_KEY_PATH || error_exit "SSH key path is required."

printf "Application port [default: 3000]: "
read -r APP_PORT
APP_PORT=${APP_PORT:-3000}

[ ! -f "$SSH_KEY_PATH" ] && error_exit "SSH key file not found: $SSH_KEY_PATH"
chmod 400 "$SSH_KEY_PATH"

# --- Clone Repository ---
WORKDIR=$(basename "$REPO_URL" .git)
if [ -d "$WORKDIR" ]; then
  log "INFO: Repository already exists, pulling latest changes..."
  cd "$WORKDIR" || error_exit "Cannot access directory."
  git pull || error_exit "Failed to pull repository."
else
  log "INFO: Cloning repository..."
  git clone "https://${PAT}@${REPO_URL#https://}" || error_exit "Git clone failed."
  cd "$WORKDIR" || error_exit "Failed to enter repo directory."
fi

git checkout "$BRANCH" || error_exit "Branch checkout failed."

# --- Validate Dockerfile ---
if [ -f "Dockerfile" ]; then
  log "SUCCESS: Dockerfile found."
else
  error_exit "No Dockerfile found in repository."
fi

# --- Remote SSH Connection Test ---
log "INFO: Testing SSH connection to $SERVER_IP..."
ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i "$SSH_KEY_PATH" "$USERNAME@$SERVER_IP" "echo 'SSH connection OK.'" || error_exit "SSH connection failed."

# --- Remote Setup ---
log "INFO: Setting up remote environment..."
ssh -i "$SSH_KEY_PATH" "$USERNAME@$SERVER_IP" <<EOF
set -eu
echo "Updating system..."
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose nginx curl

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USERNAME || true

echo "Checking Docker..."
docker --version || exit 1
docker-compose --version || exit 1

echo "Preparing app directory..."
sudo mkdir -p /var/www/app
sudo chown -R $USERNAME:$USERNAME /var/www/app
EOF

# --- Transfer Project Files ---
log "INFO: Copying files to remote server..."
scp -i "$SSH_KEY_PATH" -r . "$USERNAME@$SERVER_IP:/var/www/app" || error_exit "File transfer failed."

# --- Build and Run Docker Container ---
log "INFO: Running container on remote host..."
ssh -i "$SSH_KEY_PATH" "$USERNAME@$SERVER_IP" <<EOF
set -eu
cd /var/www/app

echo "Stopping old container (if any)..."
docker stop app_container 2>/dev/null || true
docker rm app_container 2>/dev/null || true

echo "Building new image..."
docker build -t app_image .

echo "Running new container on port $APP_PORT..."
docker run -d --name app_container -p $APP_PORT:$APP_PORT app_image

echo "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/app.conf > /dev/null <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:__APP_PORT__;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX

# Replace placeholder with actual port
sudo sed -i "s/__APP_PORT__/$APP_PORT/g" /etc/nginx/sites-available/app.conf

sudo ln -sf /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t || exit 1
sudo systemctl reload nginx


sudo nginx -t || exit 1
sudo systemctl reload nginx

echo "Verifying container and proxy..."
docker ps
curl -I http://localhost || echo "App not responding yet."
EOF

log "SUCCESS: Deployment completed successfully!"
log "Access your app via: http://$SERVER_IP"
