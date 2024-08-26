# ---------------
# Install Dependencies
# ---------------
    FROM node:18.18.2-alpine AS deps

    WORKDIR /app
    
    # Install dependencies neccesary for node-gyp on node alpine
    RUN apk add --update --no-cache \
      libc6-compat \
      python3 \
      make \
      g++ \
      git
    
    # Clone repository
    RUN git clone https://github.com/apotdevin/thunderhub.git .
    #Preconfigure
    RUN npm ci
    
    # ---------------
    # Build App
    # ---------------
    FROM deps AS build
    
    WORKDIR /app
    
    # Set env variables
    ARG BASE_PATH=""
    ENV BASE_PATH=${BASE_PATH}
    ARG NODE_ENV="production"
    ENV NODE_ENV=${NODE_ENV}
    ENV NEXT_TELEMETRY_DISABLED=1
    
    # Build the NestJS and NextJS application
    RUN npm run build:nest
    RUN npm run build:next
    
    # Remove non production necessary modules
    RUN npm prune --production
    
    # ---------------
    # Release App
    # ---------------
    FROM node:18.18.2-alpine AS final
    
    WORKDIR /app
    
    # Set env variables
    ARG BASE_PATH=""
    ENV BASE_PATH=${BASE_PATH}
    ARG NODE_ENV="production"
    ENV NODE_ENV=${NODE_ENV}
    ENV NEXT_TELEMETRY_DISABLED=1
    
    COPY --from=build /app/package.json ./
    COPY --from=build /app/node_modules/ ./node_modules
    
    # Copy NextJS files
    COPY --from=build /app/src/client/public ./src/client/public
    COPY --from=build /app/src/client/next.config.js ./src/client/
    COPY --from=build /app/src/client/.next/ ./src/client/.next
    
    # Copy NestJS files
    COPY --from=build /app/dist/ ./dist
    
    EXPOSE 3000
    
    CMD [ "npm", "run", "start:prod" ]