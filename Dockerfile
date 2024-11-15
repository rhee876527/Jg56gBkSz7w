# Use a Rust base image for building
FROM rust:alpine3.19 AS builder

ARG TARGET

# Install necessary dependencies
RUN apk add --no-cache musl-dev

# Set the working directory
WORKDIR /repo

# Copy only the Cargo files to leverage caching
COPY Cargo.toml Cargo.lock ./

# Init cache for the build 
RUN mkdir -v src && \
    echo 'fn main() {}' > src/main.rs

# Build cache from dummy main.rs
COPY src src
RUN touch src/main.rs
RUN cargo build --release --target ${TARGET} || true

# Copy the source code for the build 
COPY . . 

# Compile & build application using dummy cache
RUN cargo build --release --target ${TARGET} 

# Create the final image for running application
FROM alpine:3.20 AS runtime

ARG TARGET

# Copy the built binary from the builder stage
COPY --from=builder /repo/target/${TARGET}/release/redlib /usr/local/bin/redlib

# Create the redlib user
RUN adduser --home /nonexistent --no-create-home --disabled-password redlib
USER redlib

EXPOSE 8080

HEALTHCHECK --interval=1m --timeout=3s CMD wget --spider -q http://localhost:8080/settings || exit 1

CMD ["redlib"]
