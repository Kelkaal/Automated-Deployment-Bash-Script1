# Automated Server Deployment Script
This is a Bash script that automatically deploys a Dockerized web application to a remote Linux server over SSH.  
It clones your repository, installs Docker, builds the image, runs the container, and configures Nginx as a reverse proxy — all in one go.

## Overview
This script simplifies the process of deploying applications to a remote Linux server.  
Instead of manually installing Docker, transferring files, and setting up Nginx, this script automates the entire flow using SSH commands.

It is useful for:
- Developers who want quick deployment without CI/CD setup
- Testing Docker apps on a remote VPS or EC2 instance
- Automating app delivery using shell scripting

  ## Features
  - Interactive prompts for all required inputs
- Automatic Git clone or pull from your repository
- SSH connection verification
- Remote installation of Docker, Docker Compose, and Nginx
- File transfer to `/var/www/app`
- Docker image build and container run
- Automatic Nginx reverse proxy setup
- Detailed logging for each step

## Requirements
### Local Machine
- Linux, macOS, or Git Bash on Windows
- Git installed
- SSH key with access to your remote server

### Remote Server
- Ubuntu/Debian-based OS
- Sudo privileges for the SSH user
- Port 80 open (for HTTP access)

## Setup and Usage
1. **Save the script**

   Save the file as `deploy.sh` in your project folder.

2. **Make it executable**

   ```bash
   chmod +x deploy.sh

## Run the script
  ./deploy.sh



## You’ll be asked to enter:
| Prompt                      | Description              | Example                              |
| --------------------------- | ------------------------ | ------------------------------------ |
| Git Repository URL          | HTTPS repo link          | `https://github.com/user/my-app.git` |
| Personal Access Token (PAT) | GitHub token             | `ghp_ABC123xyz`                      |
| Branch name                 | Branch to deploy         | `main`                               |
| Server username             | Remote SSH username      | `ubuntu`                             |
| Server IP address           | Remote server IP         | `54.211.32.10`                       |
| SSH key path                | Path to your private key | `~/.ssh/id_rsa`                      |
| Application port            | Port your app runs on    | `3000`                               |

<img width="1741" height="937" alt="image" src="https://github.com/user-attachments/assets/af4d0b9b-37c2-44b4-b985-78e87279363c" />

## Notes
- Ensure your GitHub Personal Access Token (PAT) has **repo read access**.
- Do **not** expose or commit your PAT or SSH key.
- Your repository **must include a Dockerfile** in the root directory.
- Re-running the script automatically pulls latest changes and redeploys.

