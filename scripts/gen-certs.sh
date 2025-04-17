#!/usr/bin/env bash
set -e

# Create SSL directory if it doesn't exist
mkdir -p nginx/ssl

# Generate private key
openssl genrsa -out nginx/ssl/server.key 2048

# Generate certificate signing request (CSR)
openssl req -new \
  -key nginx/ssl/server.key \
  -out nginx/ssl/server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=127.0.0.1"

# Generate self-signed certificate
openssl x509 -req -days 365 \
  -in nginx/ssl/server.csr \
  -signkey nginx/ssl/server.key \
  -out nginx/ssl/server.crt

# Secure the private key
chmod 600 nginx/ssl/server.key

echo "✳︎ Certificates written to nginx/ssl/"
