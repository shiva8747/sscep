#!/bin/bash
# TLS Proxy Script - Allows HTTP client to connect to HTTPS server
# This creates a local HTTP endpoint that forwards to the HTTPS server

SERVER="emsign-server1.qa.emudhra.net"
SERVER_PORT="444"
LOCAL_PORT="8080"

echo "Starting TLS proxy..."
echo "Local endpoint: http://localhost:$LOCAL_PORT"
echo "Remote server: https://$SERVER:$SERVER_PORT"
echo ""
echo "Now you can use: ./sscep getca -u http://localhost:$LOCAL_PORT/hubWrapperAPI/scep/... -c ca.pem"
echo ""
echo "Press Ctrl+C to stop the proxy"
echo ""

# Start socat proxy
socat TCP-LISTEN:$LOCAL_PORT,fork,reuseaddr SSL:$SERVER:$SERVER_PORT,verify=0
