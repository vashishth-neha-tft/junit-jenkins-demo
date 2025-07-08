# Dummy Dockerfile for Snyk Compliance Check
FROM alpine:3.18

LABEL maintainer="test@example.com"
LABEL version="1.0"
LABEL description="Dummy image for Snyk Docker compliance test"

# Set environment variables
ENV APP_HOME=/app

# Create app directory
RUN mkdir -p $APP_HOME

# Add a dummy file
RUN echo "This is a test file" > $APP_HOME/test.txt

# Set working directory
WORKDIR $APP_HOME

# Default command
CMD ["sh"]
