#!/bin/bash
# Example: Full enrollment process

# Configuration
SCEP_URL="https://emsign-server1.qa.emudhra.net:444/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea"
CA_CERT="ca.pem"
PRIVATE_KEY="local.key"
CSR="local.csr"
ISSUED_CERT="local.crt"

# Step 1: Get CA certificate (if you don't have it)
if [ ! -f "$CA_CERT" ]; then
    echo "==> Getting CA certificate..."
    ./sscep getca -v \
      -u "$SCEP_URL" \
      -c "$CA_CERT"
fi

# Step 2: Generate private key and CSR (if you don't have them)
if [ ! -f "$PRIVATE_KEY" ]; then
    echo ""
    echo "==> Generating private key and certificate request..."
    openssl genrsa -out "$PRIVATE_KEY" 2048
    openssl req -new -key "$PRIVATE_KEY" -out "$CSR" \
      -subj "/C=IN/ST=Karnataka/L=Bangalore/O=YourOrg/CN=test.example.com"
fi

# Step 3: Enroll
echo ""
echo "==> Enrolling certificate..."
./sscep enroll -v \
  -u "$SCEP_URL" \
  -c "$CA_CERT" \
  -k "$PRIVATE_KEY" \
  -r "$CSR" \
  -l "$ISSUED_CERT" \
  -S sha256 \
  -E aes256

echo ""
echo "Certificate enrollment complete!"
echo "Issued certificate: $ISSUED_CERT"
