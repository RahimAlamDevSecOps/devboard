
# Stage 1: Build the frontend application
FROM dhi.io/node:26-dev AS build

WORKDIR /app

# Copy package files from the frontend directory
COPY frontend/package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Ensure Vite is installed
RUN npm list vite > /dev/null 2>&1 || npm install --no-save vite@5.4.11

# Copy frontend source code
COPY frontend/ ./

# Build-time environment variables
ARG VITE_OTEL_ENABLED=false
ARG VITE_OTEL_ENVIRONMENT=dev
ARG VITE_APP_VERSION=dev

ENV VITE_OTEL_ENABLED=$VITE_OTEL_ENABLED \
    VITE_OTEL_ENVIRONMENT=$VITE_OTEL_ENVIRONMENT \
    VITE_APP_VERSION=$VITE_APP_VERSION

# Build the production frontend
RUN npm run build


# Stage 2: Run the frontend application
FROM dhi.io/node:26

WORKDIR /app

# Copy production build from the build stage
COPY --from=build /app/dist ./dist

# Copy Node dependencies
COPY --from=build /app/node_modules ./node_modules

# Copy Vite preview configuration
COPY frontend/vite.preview.config.js ./vite.config.js

EXPOSE 4173

ENTRYPOINT ["node", "--no-warnings"]

CMD ["./node_modules/.bin/vite", "preview", "--host", "0.0.0.0", "--port", "4173"]
