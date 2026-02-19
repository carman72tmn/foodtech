# Security Advisory - Dependency Updates

## Date: 2026-02-19

## Summary

Three critical security vulnerabilities were identified in project dependencies and have been patched.

## Vulnerabilities Fixed

### 1. python-multipart (Backend)

**CVE**: Arbitrary File Write via Non-Default Configuration
- **Affected Version**: 0.0.9
- **Fixed Version**: 0.0.22
- **Severity**: High
- **Impact**: Could allow arbitrary file write in certain configurations
- **Status**: ✅ PATCHED

**CVE**: Denial of Service (DoS) via deformed multipart/form-data boundary
- **Affected Version**: 0.0.9
- **Fixed Version**: 0.0.18 (updated to 0.0.22)
- **Severity**: Medium
- **Impact**: DoS attack possible through malformed multipart data
- **Status**: ✅ PATCHED

### 2. aiohttp (Telegram Bot)

**CVE**: HTTP Parser auto_decompress vulnerable to zip bomb
- **Affected Version**: 3.10.5
- **Fixed Version**: 3.13.3
- **Severity**: High
- **Impact**: Zip bomb attack could cause resource exhaustion
- **Status**: ✅ PATCHED

## Changes Made

### Backend (`backend/requirements.txt`)
```diff
- python-multipart==0.0.9
+ python-multipart==0.0.22
```

### Bot (`bot/requirements.txt`)
```diff
- aiohttp==3.10.5
+ aiohttp==3.13.3
```

## Recommended Actions

### For New Deployments
No action needed - the updated versions are already in the requirements.txt files.

### For Existing Deployments

1. **Update Backend Dependencies:**
```bash
cd /opt/foodtech/backend
source venv/bin/activate
pip install --upgrade python-multipart==0.0.22
sudo systemctl restart foodtech-api
```

2. **Update Bot Dependencies:**
```bash
cd /opt/foodtech/bot
source venv/bin/activate
pip install --upgrade aiohttp==3.13.3
sudo systemctl restart foodtech-bot
```

3. **Verify Updates:**
```bash
# Check backend
cd /opt/foodtech/backend
source venv/bin/activate
pip show python-multipart | grep Version

# Check bot
cd /opt/foodtech/bot
source venv/bin/activate
pip show aiohttp | grep Version
```

## Testing

After updating, verify that all systems are functioning correctly:

1. Check Backend API health: `curl http://localhost:8000/health`
2. Test Telegram Bot: Send `/start` command
3. Review logs for any errors:
   - `sudo journalctl -u foodtech-api -n 50`
   - `sudo journalctl -u foodtech-bot -n 50`

## Prevention

### Regular Dependency Updates

Add to monthly maintenance schedule:
```bash
# Check for outdated packages
cd /opt/foodtech/backend
source venv/bin/activate
pip list --outdated

cd /opt/foodtech/bot
source venv/bin/activate
pip list --outdated
```

### Automated Security Scanning

Consider implementing:
- Dependabot for automated dependency updates
- Safety check: `pip install safety && safety check`
- Snyk or similar security scanning tools

## References

- [python-multipart Security Advisory](https://github.com/advisories/GHSA-2jv5-9r88-3w3p)
- [aiohttp Security Advisory](https://github.com/aio-libs/aiohttp/security/advisories)

## Contact

For security concerns, please open an issue on the GitHub repository or contact the maintainers directly.

---

**Status**: All vulnerabilities patched as of 2026-02-19
