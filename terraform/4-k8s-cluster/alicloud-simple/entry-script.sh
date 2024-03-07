#!/bin/bash
apt update -y && apt install -y docker.io
systemctl start docker 
docker run -p 8080:80 nginx
