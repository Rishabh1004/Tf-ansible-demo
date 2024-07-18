# Use the official Nginx image as the base image
FROM nginx:latest

# Dockerfile Maintainer
LABEL maintainer="Rutwik Dadgal"

# Copy custom configuration file (if needed)
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose HTTP port
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
