# The `RUBY_VER` is defined by reference to an environment variable in `compose.yml`,
# but the Docker specification requires a specific default value for the ARG referenced by the image name.
# However, in the end, the 3.3.5 (default) defined in the env file takes precedence.
ARG RUBY_VER=3.3.0

# --- Common base stage for development and production ---
# Specify the base image by full name to make sure it from Docker Hub
FROM docker.io/library/ruby:${RUBY_VER}-slim AS base-common

ARG USER_ID \
    GROUP_ID \
    BUNDLE_BIN \
    BUNDLE_PATH \
    PORT

# Install packages needed common to each environment
# - libjemalloc2 is a memory allocator that can be used to reduce memory fragmentation
# - libvips is an image processing library
RUN apt-get update -qq && \
    apt-get install \
      --no-install-recommends -y \
      curl \
      postgresql-client \
      libjemalloc2 \
      libvips

# (Before switching the container user from root to a non-root user,)
# Change the owner of /usr/local/bundle (default), where gems is installed, from root to a general user.
RUN chown -R $USER_ID:$GROUP_ID $BUNDLE_PATH

# Inform container's OS the binary path of gems to be installed, specifing BUNDLE_BIN
#   This is optional, if do not setup as follow, alternatively, you should always use the command bundle exec to run the gem command.
RUN mkdir -p $BUNDLE_BIN && \
    chown -R $USER_ID:$GROUP_ID $BUNDLE_BIN
ENV PATH="$BUNDLE_BIN:$PATH" \
    BUNDLE_PATH=$BUNDLE_PATH

ENV PORT=$PORT


# --- Base stage for development ---
FROM base-common AS base-development

ARG USER_NAME \
    GROUP_NAME

# Rails app lives here
RUN mkdir -p /home/$USER_NAME/api && \
    chown -R $USER_ID:$GROUP_ID /home/$USER_NAME
WORKDIR /home/$USER_NAME/api

# Install packages needed for development
RUN apt-get update -qq \
    && \
    apt-get install \
      --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      pkg-config

# --- Build stage for development ---
# FROM base-development AS build-development
# Nothing to do here, just a placeholder for now

# --- Final stage for development ---
FROM base-development AS development

# Run and own only the runtime files as a non-root user for security
RUN groupadd --gid $GROUP_ID $GROUP_NAME && \
    useradd $USER_NAME --uid $USER_ID --gid $GROUP_ID --create-home --shell /bin/bash

# Login as the non-root user
USER $USER_NAME

# Install application gems
COPY --chown=$USER_NAME Gemfile Gemfile.lock ./
RUN bundle install

# Set entrypoint to delete the server.pid file if it exists
COPY ./bin ./bin
ENTRYPOINT [ "./bin/docker-entrypoint.dev.sh" ]

CMD ["./bin/rails", "server", "--port", "3000", "--binding", "0.0.0.0"]



# --- Base stage for production ---
FROM base-common AS base-production

ARG USER_NAME_PROD="rails" \
    GROUP_NAME_PROD="rails"

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development"
    # BUNDLE_PATH=${BUNDLE_PATH}

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid $GROUP_ID $GROUP_NAME_PROD && \
    useradd $USER_NAME_PROD --uid $USER_ID --gid $GROUP_ID --create-home --shell /bin/bash

# Move to user's home directory
WORKDIR /home/$USER_NAME_PROD

# Rails app lives here; Give user authority to edit user's home directory
RUN mkdir ./api && \
    chown -R $USER_ID:$GROUP_ID .


# --- Build stage for production ---
FROM base-production AS build-production

# Install packages needed to build gems
RUN apt-get update -qq \
    && \
    apt-get install \
      --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      pkg-config \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Move to project directory
WORKDIR /home/$USER_NAME_PROD/api

# Install application gems
COPY --chown=$USER_NAME_PROD Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY --chown=$USER_NAME_PROD . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/


# --- Final stage for production ---
FROM base-production AS production

# Log in as the non-root user, created in base-production
USER $USER_NAME_PROD

WORKDIR /home/$USER_NAME_PROD/api

# Copy built artifacts
#   * gems in $BUNDLE_PATH
COPY --from=build-production "${BUNDLE_PATH}" "${BUNDLE_PATH}"
#   * precompiled application code
COPY --from=build-production /home/$USER_NAME_PROD/api .

# Entrypoint prepares the database.
ENTRYPOINT ["./bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 8080
CMD ["./bin/rails", "server"]
