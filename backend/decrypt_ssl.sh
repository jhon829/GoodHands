#!/bin/bash
echo "hwang0609!" | openssl rsa -in /tmp/ssl_encrypted.key -out /etc/nginx/ssl/ssl_decrypted.key -passin stdin
chmod 600 /etc/nginx/ssl/ssl_decrypted.key
