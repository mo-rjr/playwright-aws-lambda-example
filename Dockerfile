# Define custom function directory
ARG FUNCTION_DIR="/function"

# chose a sha from before change to Node 16 to get Node 14 container
# dockerfile of this sha https://github.com/microsoft/playwright/blob/7927920c35290aa038f4052bc22c3ac1edf74993/utils/docker/Dockerfile.focal
FROM mcr.microsoft.com/playwright:sha-7927920c35290aa038f4052bc22c3ac1edf74993 as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Install aws-lambda-ric build dependencies
RUN apt-get update && apt-get install -y \
    g++ \
    make \
    cmake \
    unzip \
    libcurl4-openssl-dev \
    autoconf \
    libtool

# Create function dir and set it as WORKDIR
RUN mkdir -p ${FUNCTION_DIR}
WORKDIR ${FUNCTION_DIR}

# Install npm packages
# COPY will invalidate the cache for following instructions if the contents of <src> have changed,
# so in order to optimize the build we'll copy only package.json and run npm install first
COPY function/package.json ${FUNCTION_DIR}
RUN npm install

# Install AWS Lambda Node.js Runtime Interface Client API
RUN npm install aws-lambda-ric --save

# Copy the rest of the function directory
COPY function/ ${FUNCTION_DIR}

# Multi-stage build: Get a fresh slim copy of base image to reduce final size
FROM mcr.microsoft.com/playwright:sha-7927920c35290aa038f4052bc22c3ac1edf74993

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# I removed the Remove Firefox line because it was failing for me

# Add Lambda Runtime Interface Emulator and use a script in the ENTRYPOINT for simpler local runs
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/local/bin/aws-lambda-rie
RUN chmod 755 /usr/local/bin/aws-lambda-rie
COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Set function handler
CMD ["index.handler"]
#CMD ["simple.handler"]