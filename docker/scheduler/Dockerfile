# Scheduler Service (Node.js)
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY modules/scheduler/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy TypeScript config and source code
COPY modules/scheduler/tsconfig.json ./
COPY modules/scheduler/src/ ./src/

# Install TypeScript globally and build
RUN npm install -g typescript ts-node
RUN npm run build

# Expose port (if needed)
EXPOSE 3000

# Run the application
CMD ["npm", "run", "prod"]
