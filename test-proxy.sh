#!/bin/bash
# Test if the TLS proxy is working correctly

LOCAL_PORT="8080"
SCEP_PATH="/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea"

echo "=== Testing TLS Proxy ==="
echo ""

# Check if proxy is running
echo "[1/3] Checking if proxy is running on port $LOCAL_PORT..."
if netstat -tln 2>/dev/null | grep -q ":$LOCAL_PORT "; then
    echo "✓ Proxy is running on port $LOCAL_PORT"
elif ss -tln 2>/dev/null | grep -q ":$LOCAL_PORT "; then
    echo "✓ Proxy is running on port $LOCAL_PORT"
else
    echo "✗ No proxy detected on port $LOCAL_PORT"
    echo ""
    echo "Start the proxy first:"
    echo "  ./start-tls-proxy.sh"
    echo "  OR"
    echo "  ./start-stunnel-proxy.sh"
    exit 1
fi

echo ""

# Test connection with curl
echo "[2/3] Testing HTTP connection to proxy..."
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$LOCAL_PORT$SCEP_PATH?operation=GetCACaps" 2>/dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Proxy is working! Got HTTP 200 response"
    else
        echo "⚠ Got HTTP $RESPONSE (may be normal depending on server)"
    fi
else
    echo "⚠ curl not found, skipping HTTP test"
fi

echo ""

# Test with sscep
echo "[3/3] Testing with sscep client..."
if [ -f ./sscep ]; then
    if ./sscep getca -u "http://localhost:$LOCAL_PORT$SCEP_PATH" -c /tmp/test-ca.pem 2>&1 | grep -q "CA certificate"; then
        echo "✓ sscep successfully got CA certificate via proxy!"
        rm -f /tmp/test-ca.pem
    else
        echo "⚠ sscep test had issues (check above output)"
    fi
else
    echo "⚠ sscep binary not found in current directory"
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "If all tests passed, you can now use:"
echo "  ./sscep getca -u http://localhost:$LOCAL_PORT$SCEP_PATH -c ca.pem"
