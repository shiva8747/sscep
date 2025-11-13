# SSCEP Client Setup Guide

This guide explains how to configure and use the latest sscep client with HTTPS/TLS support.

## Features

✅ **HTTPS/TLS Support** - Connect to SCEP servers over encrypted connections
✅ **Better Error Messages** - See actual HTTP status codes and server responses
✅ **Backward Compatible** - Still works with HTTP URLs

## Installation

### Option 1: Use from Current Directory
```bash
# Add to PATH temporarily
export PATH=$PATH:$(pwd)

# Or create an alias
alias sscep="$(pwd)/sscep"
```

### Option 2: Install to User Directory
```bash
# Copy to local bin
mkdir -p ~/.local/bin
cp ./sscep ~/.local/bin/
chmod +x ~/.local/bin/sscep

# Add to PATH in ~/.bashrc
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Option 3: System-Wide Installation
```bash
sudo cp ./sscep /usr/local/bin/
sudo chmod +x /usr/local/bin/sscep
```

## Quick Start

### 1. Get CA Certificate (HTTPS)
```bash
./sscep getca -v \
  -u https://your-server:443/scep \
  -c ca.pem
```

### 2. Generate Key and CSR
```bash
# Generate private key
openssl genrsa -out local.key 2048

# Generate certificate signing request
openssl req -new -key local.key -out local.csr \
  -subj "/C=IN/ST=Karnataka/L=Bangalore/O=YourCompany/CN=your.domain.com"
```

### 3. Enroll Certificate
```bash
./sscep enroll -v \
  -u https://your-server:443/scep \
  -c ca.pem \
  -k local.key \
  -r local.csr \
  -l local.crt \
  -S sha256 \
  -E aes256
```

## Configuration Methods

### Method 1: Command Line (Flexible)

**Pros:** Easy to test, flexible
**Cons:** Long command lines

See `example-getca.sh` and `example-enroll.sh` for examples.

### Method 2: Configuration File (Recommended for Production)

**Pros:** Clean, reusable, version controllable
**Cons:** Less flexible

1. Copy the example config:
```bash
cp sscep.conf.example sscep.conf
```

2. Edit `sscep.conf` with your settings

3. Use it:
```bash
./sscep getca -f sscep.conf
./sscep enroll -f sscep.conf
```

## Common Operations

### Get CA Certificate
```bash
./sscep getca -v -u https://server/scep -c ca.pem
```

### Get CA Capabilities
```bash
./sscep getcaps -v -u https://server/scep
```

### Enroll Certificate
```bash
./sscep enroll -v \
  -u https://server/scep \
  -c ca.pem \
  -k private.key \
  -r request.csr \
  -l certificate.crt
```

### Get CRL (Certificate Revocation List)
```bash
./sscep getcrl -v \
  -u https://server/scep \
  -c ca.pem \
  -k local.key \
  -l local.crt \
  -w crl.pem
```

### Query Certificate by Serial Number
```bash
./sscep getcert -v \
  -u https://server/scep \
  -c ca.pem \
  -k local.key \
  -l local.crt \
  -s 123456789 \
  -w queried.crt
```

## Important Options

| Option | Description | Example |
|--------|-------------|---------|
| `-u <url>` | SCEP server URL | `https://server:443/scep` |
| `-c <file>` | CA certificate file | `ca.pem` |
| `-k <file>` | Private key file | `local.key` |
| `-r <file>` | Certificate request (CSR) | `local.csr` |
| `-l <file>` | Local certificate file | `local.crt` |
| `-S <alg>` | Signature algorithm | `sha256`, `sha512` |
| `-E <alg>` | Encryption algorithm | `aes256`, `aes128` |
| `-v` | Verbose output | - |
| `-f <file>` | Configuration file | `sscep.conf` |

## HTTPS vs HTTP

### Use HTTPS when:
- Server requires TLS (you'll see "requires TLS" error with HTTP)
- Security is important
- Server is on the internet

```bash
-u https://server:443/scep
```

### Use HTTP when:
- Internal testing
- Server doesn't support TLS
- Using a local proxy

```bash
-u http://server:80/scep
```

## Troubleshooting

### Error: "This combination of host and port requires TLS"
**Solution:** Use `https://` instead of `http://` in your URL

### Error: "SSL connection failed"
**Possible causes:**
- Wrong port (try 443 for HTTPS)
- Server doesn't support TLS
- Firewall blocking connection

**Debug:**
```bash
# Test with curl first
curl -v https://your-server:443/scep

# Try with verbose mode
./sscep getca -v -u https://your-server:443/scep -c ca.pem
```

### Error: "cannot connect"
**Possible causes:**
- Server is down
- Wrong hostname/port
- Network issues

**Debug:**
```bash
# Test network connectivity
ping your-server
telnet your-server 443
```

### Error: "wrong (or missing) MIME content type"
This usually means the server returned an error page. Check:
- Correct URL path
- Server is a SCEP server
- HTTP status code in error message

## Testing Your Setup

1. **Test with your eMudhra server:**
```bash
./sscep getca -v \
  -u https://emsign-server1.qa.emudhra.net:444/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea \
  -c ca.pem
```

2. **Verify CA certificate:**
```bash
openssl x509 -in ca.pem -text -noout
```

3. **Check capabilities:**
```bash
./sscep getcaps -v \
  -u https://emsign-server1.qa.emudhra.net:444/hubWrapperAPI/scep/9f483eb9-dbdc-4648-bb20-e8feb15a0aea
```

## Example Scripts

I've created example scripts for you:

- `example-getca.sh` - Get CA certificate
- `example-enroll.sh` - Complete enrollment workflow

Edit them with your server details and run:
```bash
./example-getca.sh
```

## Differences from Old Version

| Feature | Old Version | New Version |
|---------|-------------|-------------|
| HTTPS Support | ❌ No | ✅ Yes |
| Error Messages | Generic | Detailed with HTTP status |
| URL Format | `http://` only | `http://` or `https://` |
| Default Port | 80 | 80 for HTTP, 443 for HTTPS |

## Security Notes

1. **Always use HTTPS in production** - Protects credentials and certificates in transit
2. **Verify CA certificate fingerprint** - Use `-F sha256` option
3. **Protect private keys** - Use `chmod 600 private.key`
4. **Use strong algorithms** - Prefer `sha256`/`sha512` and `aes256`

## Next Steps

1. Test `getca` operation
2. Generate your key and CSR
3. Test `enroll` operation
4. Integrate into your automation/scripts

## Support

For issues with this version, check:
- Commits: `5492eae` (Error messages) and `50adc4f` (HTTPS support)
- GitHub: https://github.com/certnanny/sscep
