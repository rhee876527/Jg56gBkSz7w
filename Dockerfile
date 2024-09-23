# Use a Rust base image for building
FROM rust:alpine3.19 AS builder

ARG TARGET

# Install necessary dependencies
RUN apk add --no-cache musl-dev

# Set the working directory
WORKDIR /repo

# Copy only the Cargo.toml and Cargo.lock files first to leverage caching
COPY Cargo.toml Cargo.lock ./

# Create a new empty directory for the source code
RUN mkdir -v src && \
    echo 'fn main() {}' > src/main.rs && \
    cargo build --release --target ${TARGET} && \
    rm -Rvf src

# Copy the actual source code into the image 
COPY . . 

# Build the application with the actual source code
RUN cargo build --release --target ${TARGET}

# Create the final image
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
