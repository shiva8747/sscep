#!/bin/bash
# Example: Get CA certificate using HTTPS

# Configuration
SCEP_URL="https://emsign-server1.qa.emudhra.net:444/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea"
CA_CERT="ca.pem"

# Get CA certificate
./sscep getca -v \
  -u "$SCEP_URL" \
  -c "$CA_CERT"

echo ""
echo "CA certificate saved to: $CA_CERT"
