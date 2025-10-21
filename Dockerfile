# Use official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package.json (if any)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Expose port 3000
EXPOSE 3000

# Start app
CMD ["npm", "start"]

