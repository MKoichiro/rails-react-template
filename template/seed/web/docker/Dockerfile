# docker.io/library/node:22.11.0-slim
# Following version of npm and yarn have been installed in the base-image layer
# https://github.com/nodejs/docker-node/blob/b0de582b8d4627cc9d65a89bf3af1bfcf67d2bef/versions.json
#   npm: 10.9.0
#   yarn: 1.22.22

# Use default user
# Non-root user has been set as below in the base-image layer
#     uid=1000(node) gid=1000(node) groups=1000(node)

# The `NODE_VER` is defined by reference to an environment variable in `compose.yml`,
# but the Docker specification requires a specific default value for the ARG referenced by the image name.
# However, in the end, the 22.11.0 (default) defined in the env file takes precedence.
ARG NODE_VER_ARG=20
FROM docker.io/library/node:${NODE_VER_ARG}-slim AS development
USER node
WORKDIR /home/node/web
CMD ["npm", "run", "dev"]

# Build stage
FROM development AS build
ARG API_SERVER
COPY --chown=node:node . .
RUN npm ci && npm run build

# preview stage
FROM nginx:latest AS preview
COPY --from=build /home/node/web/dist /var/www
COPY nginx/conf.d/prev.conf /etc/nginx/conf.d/default.conf

# Production stage
FROM nginx:latest AS production
COPY --from=build /home/node/web/dist /var/www
COPY nginx/conf.d/prod.conf /etc/nginx/conf.d/default.conf
