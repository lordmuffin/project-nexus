# Project Nexus Documentation

Welcome to the Project Nexus documentation. This directory contains comprehensive guides for testing, troubleshooting, and understanding the QR code pairing system.

## QR Code Pairing Documentation

The QR code pairing system allows mobile devices to connect to the Project Nexus desktop application by scanning a QR code. This documentation covers all aspects of testing and troubleshooting this system.

### 📚 Documentation Index

| Document | Purpose | Audience |
|----------|---------|----------|
| [QR Pairing Testing Guide](./QR-PAIRING-TESTING.md) | Complete end-to-end testing procedures | Developers, QA |
| [Troubleshooting Guide](./QR-PAIRING-TROUBLESHOOTING.md) | Step-by-step problem diagnosis | Developers, Support |
| [Common Issues](./QR-PAIRING-COMMON-ISSUES.md) | Frequently encountered problems and solutions | All users |
| [API Reference](./QR-PAIRING-API.md) | Detailed API specifications | Developers |

### 🚀 Quick Start

If you're experiencing QR pairing issues, start here:

1. **Is the backend healthy?**
   ```bash
   curl -s http://localhost:3001/api/health | jq '.status'
   ```

2. **Can you generate QR codes?**
   ```bash
   curl -X POST http://localhost:3001/api/pairing/generate-qr -H "Content-Type: application/json" -s | jq '.success'
   ```

3. **Can mobile devices reach the backend?**
   ```bash
   curl -s http://192.168.1.61:3001/api/health
   ```

If any of these fail, see the [Troubleshooting Guide](./QR-PAIRING-TROUBLESHOOTING.md).

### 🧪 Testing

For comprehensive testing of the QR pairing system:

1. **Follow the complete testing guide**: [QR Pairing Testing Guide](./QR-PAIRING-TESTING.md)
2. **Use the provided test scripts** for automated validation
3. **Check the API reference** for detailed endpoint specifications

### 🐛 Troubleshooting

When QR pairing doesn't work:

1. **Check common issues first**: [Common Issues](./QR-PAIRING-COMMON-ISSUES.md)
2. **Follow the diagnostic flowchart**: [Troubleshooting Guide](./QR-PAIRING-TROUBLESHOOTING.md)
3. **Use the quick diagnostic script** for rapid problem identification

### 📖 API Documentation

For developers working with the pairing system:

- **Complete API reference**: [API Reference](./QR-PAIRING-API.md)
- **Request/response examples**
- **Error handling guidelines**
- **WebSocket event specifications**

### 🔧 Most Common Issues

Based on troubleshooting experience, these are the most frequent issues:

1. **Multiple Backend Servers** (50% of issues)
   - Docker + local node servers conflict
   - Solution: Use only Docker backend

2. **CORS Blocking Mobile Requests** (25% of issues)
   - Mobile origins not allowed
   - Solution: Update CORS configuration

3. **Network Connectivity** (15% of issues)
   - Mobile device can't reach backend
   - Solution: Check firewall and network setup

4. **Missing Dependencies** (10% of issues)
   - Mobile app missing required packages
   - Solution: Install expo-network and socket.io-client

### 📋 Quick Diagnostic Checklist

Before diving into detailed troubleshooting:

- [ ] Backend health check passes
- [ ] Only one backend instance running
- [ ] Mobile device on same network as backend
- [ ] QR generation works
- [ ] Mobile device can reach 192.168.1.61:3001
- [ ] CORS allows mobile requests
- [ ] Mobile app has required dependencies

### 🔄 Testing Workflow

1. **Pre-deployment Testing**:
   - Run end-to-end test script
   - Verify all curl commands pass
   - Test with actual mobile device

2. **Issue Investigation**:
   - Start with quick diagnostic script
   - Check most common issues first
   - Follow troubleshooting flowchart

3. **Resolution Verification**:
   - Re-run failed tests
   - Test complete user workflow
   - Document any new issues found

### 📞 Support

For additional support:

1. **Check existing documentation** in this directory
2. **Run diagnostic scripts** to gather information
3. **Review backend logs** for detailed error messages
4. **Test with provided curl commands** to isolate issues

### 🚀 Contributing

When adding new features or fixing issues:

1. **Update relevant documentation** in this directory
2. **Add new test cases** to the testing guide
3. **Document any new error conditions** in common issues
4. **Update API reference** for any endpoint changes

---

*Last updated: 2025-09-22*
*Documentation version: 1.0*