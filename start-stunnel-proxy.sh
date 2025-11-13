#!/bin/bash
# Start stunnel TLS proxy

echo "Starting stunnel TLS proxy..."
echo "Local endpoint: http://localhost:8080"
echo "Remote server: https://emsign-server1.qa.emudhra.net:444"
echo ""
echo "Now you can use: ./sscep getca -u http://localhost:8080/hubWrapperAPI/scep/... -c ca.pem"
echo ""
echo "Press Ctrl+C to stop the proxy"
echo ""

# Check if stunnel is installed
if ! command -v stunnel &> /dev/null; then
    echo "Error: stunnel is not installed"
    echo "Install it with: sudo apt-get install stunnel4"
    exit 1
fi

# Start stunnel
stunnel stunnel-scep.conf
