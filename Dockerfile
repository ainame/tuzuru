# Build stage
FROM docker.io/swift:6.2 as builder

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire project
COPY . .

# Build the project
RUN swift build --configuration release

# Runtime stage
FROM docker.io/swift:6.2

# Install necessary system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the built binary and resources
COPY --from=builder /app/.build/release/tuzuru /usr/local/bin/tuzuru
COPY --from=builder /app/.build/release/tuzuru_TuzuruLib.resources /usr/local/bin/tuzuru_TuzuruLib.resources

# Create a test blog directory
WORKDIR /test-blog

# Initialize git (required for Tuzuru)
RUN git init && \
    git config user.name "Test User" && \
    git config user.email "test@example.com"

# Default command
CMD ["bash"]
