FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.6.2

# Copy package files first to leverage Docker caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install

# Copy the rest of the project files
COPY . .

# Build the TypeScript project
RUN pnpm build

# Expose port
EXPOSE 7777

# Run the application
CMD ["pnpm", "start"]