# Z-Ant-Server

# Requirements

- Docker
- Docker-Compose

# How to run

1. Docker project runs with: `docker-compose up --build`. It'll take a while to build the image.

!!! Make sure to create the certificates with this script for development only:

```bash
#!/bin/bash
# Script to generate self-signed SSL certificates

# Create directory for SSL certificates
mkdir -p nginx/ssl

# Generate private key
openssl genrsa -out nginx/ssl/server.key 2048

# Generate CSR (Certificate Signing Request)
openssl req -new -key nginx/ssl/server.key -out nginx/ssl/server.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Generate self-signed certificate (valid for 365 days)
openssl x509 -req -days 365 -in nginx/ssl/server.csr -signkey nginx/ssl/server.key -out nginx/ssl/server.crt

# Set proper permissions
chmod 600 nginx/ssl/server.key

echo "Self-signed SSL certificates generated in ./nginx/ssl/"
```
