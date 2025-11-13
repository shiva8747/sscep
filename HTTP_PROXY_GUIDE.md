# Using HTTP Client with HTTPS Server

This guide shows you how to connect to an HTTPS SCEP server using HTTP in your client, without modifying the client code.

## Why Use This?

- **Use older sscep client** - Doesn't support HTTPS
- **Simplify client configuration** - No SSL/TLS code needed
- **Debugging** - Easier to inspect traffic
- **Compatibility** - Works with any HTTP-only client

## Architecture

```
[sscep client] --HTTP--> [Local Proxy] --HTTPS--> [SCEP Server]
  localhost:8080           stunnel/socat         server:444
```

## Method 1: Using socat (Quick & Simple)

### Install socat
```bash
sudo apt-get update
sudo apt-get install socat
```

### Start the Proxy
```bash
# Terminal 1: Start the proxy
./start-tls-proxy.sh

# Or manually:
socat TCP-LISTEN:8080,fork,reuseaddr SSL:emsign-server1.qa.emudhra.net:444,verify=0
```

### Use the Client
```bash
# Terminal 2: Use sscep with HTTP
./sscep getca -v \
  -u http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea \
  -c ca.pem
```

### Pros & Cons
✅ Easy one-liner
✅ No configuration files
❌ Less robust for production
❌ No automatic restart

## Method 2: Using stunnel (Recommended for Production)

### Install stunnel
```bash
sudo apt-get update
sudo apt-get install stunnel4
```

### Start the Proxy
```bash
# Terminal 1: Start stunnel
./start-stunnel-proxy.sh

# Or manually:
stunnel stunnel-scep.conf
```

### Use the Client
```bash
# Terminal 2: Use sscep with HTTP
./sscep getca -v \
  -u http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea \
  -c ca.pem
```

### Pros & Cons
✅ More robust and reliable
✅ Better logging
✅ Can run as service
✅ Certificate verification options
❌ Requires configuration file

## Method 3: Using nginx (If Already Installed)

### nginx Configuration
```nginx
# /etc/nginx/sites-available/scep-proxy
server {
    listen 8080;
    server_name localhost;

    location / {
        proxy_pass https://emsign-server1.qa.emudhra.net:444;
        proxy_ssl_verify off;
        proxy_set_header Host emsign-server1.qa.emudhra.net;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Enable and Start
```bash
sudo ln -s /etc/nginx/sites-available/scep-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Configuration

### Custom Port
Edit the proxy script or config and change `8080` to your preferred port:

**socat:**
```bash
socat TCP-LISTEN:9000,fork,reuseaddr SSL:server:444,verify=0
```

**stunnel.conf:**
```
accept = 127.0.0.1:9000
```

### Different Server
Change the server hostname/port in:
- `start-tls-proxy.sh` → `SERVER` and `SERVER_PORT` variables
- `stunnel-scep.conf` → `connect` line

### Certificate Verification
By default, certificate verification is disabled (`verify=0`). For production:

**socat:**
```bash
socat TCP-LISTEN:8080,fork,reuseaddr \
  SSL:server:444,cafile=/etc/ssl/certs/ca-certificates.crt,verify=1
```

**stunnel:**
```
verify = 2
CAfile = /etc/ssl/certs/ca-certificates.crt
```

## Running as Background Service

### systemd Service (stunnel)

Create `/etc/systemd/system/scep-proxy.service`:
```ini
[Unit]
Description=SCEP TLS Proxy
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/stunnel /home/user/sscep/stunnel-scep.conf
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable scep-proxy
sudo systemctl start scep-proxy
sudo systemctl status scep-proxy
```

## Complete Example Workflow

### 1. Start the Proxy (Choose One)

**Option A - socat:**
```bash
./start-tls-proxy.sh &
```

**Option B - stunnel:**
```bash
./start-stunnel-proxy.sh &
```

### 2. Test Connection
```bash
# Test with curl
curl -v http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea?operation=GetCACaps
```

### 3. Use SSCEP Client
```bash
# Get CA certificate
./sscep getca -v \
  -u http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea \
  -c ca.pem

# Get capabilities
./sscep getcaps -v \
  -u http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea

# Enroll certificate
./sscep enroll -v \
  -u http://localhost:8080/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea \
  -c ca.pem \
  -k local.key \
  -r local.csr \
  -l local.crt
```

## Troubleshooting

### Proxy Won't Start

**Check if port is already in use:**
```bash
sudo netstat -tlnp | grep 8080
# or
sudo lsof -i :8080
```

**Kill existing process:**
```bash
sudo kill $(sudo lsof -t -i:8080)
```

### Connection Refused

**Verify proxy is running:**
```bash
ps aux | grep -E 'socat|stunnel'
```

**Test locally:**
```bash
curl http://localhost:8080
```

### SSL/TLS Errors

**Check server connectivity:**
```bash
openssl s_client -connect emsign-server1.qa.emudhra.net:444
```

**Enable debug mode in stunnel:**
```
debug = 7
```

## Comparison: Direct HTTPS vs HTTP Proxy

| Method | Client Changes | Performance | Security | Complexity |
|--------|---------------|-------------|----------|------------|
| **Direct HTTPS** | Use new client | Best | Best | Low |
| **HTTP Proxy (socat)** | None needed | Good | Good* | Very Low |
| **HTTP Proxy (stunnel)** | None needed | Good | Good* | Low |
| **HTTP Proxy (nginx)** | None needed | Good | Good* | Medium |

*Security note: The connection between client and proxy is unencrypted (localhost only). The proxy-to-server connection is encrypted.

## Security Considerations

### Localhost Only
The proxy binds to `127.0.0.1` (localhost), so:
- ✅ Only local processes can connect
- ✅ No network exposure
- ⚠️ Traffic between client and proxy is unencrypted (but local)

### Network Binding (Not Recommended)
If you need to bind to all interfaces:
```bash
# socat - INSECURE, allows network access
socat TCP-LISTEN:8080,fork,reuseaddr,bind=0.0.0.0 SSL:server:444

# stunnel - INSECURE
accept = 0.0.0.0:8080
```

**⚠️ WARNING:** This exposes unencrypted HTTP to your network!

### Production Recommendations
1. Use stunnel (more reliable than socat)
2. Enable certificate verification (`verify=2`)
3. Run as systemd service
4. Use firewall rules to restrict access
5. Monitor logs regularly

## Example: Using Old Client with New Server

```bash
# Terminal 1: Start proxy
./start-tls-proxy.sh

# Terminal 2: Use ANY HTTP-only SCEP client
# Old sscep without HTTPS support:
/path/to/old-sscep getca \
  -u http://localhost:8080/hubWrapperAPI/scep/ID \
  -c ca.pem

# Or even use curl for testing:
curl http://localhost:8080/hubWrapperAPI/scep/ID?operation=GetCACaps
```

## Stopping the Proxy

### socat
```bash
# If running in foreground: Ctrl+C

# If running in background:
killall socat
# or
pkill -f "socat.*8080"
```

### stunnel
```bash
# If running in foreground: Ctrl+C

# If running in background:
killall stunnel
# or
pkill stunnel
```

### systemd service
```bash
sudo systemctl stop scep-proxy
```

## Summary

**Quick Testing:** Use socat with the provided script
```bash
./start-tls-proxy.sh
```

**Production Use:** Use stunnel with systemd service
```bash
sudo systemctl start scep-proxy
```

**Client Command:** Always use `http://localhost:8080`
```bash
./sscep getca -u http://localhost:8080/path -c ca.pem
```
