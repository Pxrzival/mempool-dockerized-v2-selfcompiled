FROM node:22.7-alpine3.19 AS base

# Install git
RUN apk add --no-cache git

# Clone repository
RUN git clone https://github.com/apotdevin/thunderhub.git

# Change working directory
WORKDIR /thunderhub

# Install dependencies
RUN npm install

# Build Thunderhub
RUN npm run build

# Run the application
ENTRYPOINT [ "npm", "start" ]