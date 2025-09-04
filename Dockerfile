# Use an official Node.js image
FROM node:18

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and install deps
COPY package*.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose port
EXPOSE 80

# Start the app
CMD ["node", "server.js"]
