# Node.js 24 Upgrade TODO

This document outlines the steps needed to upgrade the Nexus web app to be fully compatible with Node.js 24.

## Current Issues with Node.js 24

- ❌ OpenSSL legacy provider errors (`error:0308010C:digital envelope routines::unsupported`)
- ❌ React Scripts 5.0.1 incompatibility
- ❌ ESLint configuration conflicts
- ❌ TypeScript version peer dependency conflicts

## Upgrade Path

### Phase 1: Framework Updates

- [ ] **Upgrade React Scripts** to v5.0.1+ (done) or migrate to Vite
- [ ] **Update React** from v17 to v18
  ```bash
  npm install react@18 react-dom@18 --legacy-peer-deps
  ```
- [ ] **Update TypeScript** configuration for Node.js 24 compatibility
- [ ] **Resolve ESLint** peer dependency conflicts

### Phase 2: Build Tool Migration (Recommended)

- [ ] **Migrate from Create React App to Vite**
  - Better Node.js 24 support
  - Faster builds
  - Modern toolchain
  ```bash
  npm install vite @vitejs/plugin-react --save-dev
  ```
- [ ] **Create vite.config.js**
- [ ] **Update package.json scripts**
- [ ] **Migrate public assets**

### Phase 3: Dependency Updates

- [ ] **Update all dependencies** to Node.js 24 compatible versions
  ```bash
  npm audit
  npm update
  ```
- [ ] **Replace deprecated packages**:
  - `babel-eslint` → `@babel/eslint-parser`
  - `eslint@7` → `eslint@8+`
  - Various webpack loaders

### Phase 4: Configuration Updates

- [ ] **Remove OpenSSL legacy provider** workarounds
- [ ] **Update .env variables**
- [ ] **Fix ESLint configuration**
- [ ] **Update TypeScript config** for modern Node.js

### Phase 5: Testing & Validation

- [ ] **Test app startup** with Node.js 24
- [ ] **Verify hot reload** functionality
- [ ] **Test production build**
- [ ] **Validate all features** work correctly
- [ ] **Update Docker** configuration if needed

## Alternative: Quick Fix (Current Workaround)

Until full upgrade is complete, use these temporary fixes:

```bash
# .env file
NODE_OPTIONS=--openssl-legacy-provider
ESLINT_NO_DEV_ERRORS=true
SKIP_PREFLIGHT_CHECK=true

# Or use Node.js 18 LTS
nvm use 18.19.0
```

## Dependencies to Update

### Critical Updates
- `react-scripts`: 5.0.1 → latest or migrate to Vite
- `react`: 17.x → 18.x
- `eslint`: 7.x → 8.x+
- `typescript`: Resolve peer dependency conflicts

### Secondary Updates
- `@testing-library/*`: Update to latest
- `react-router-dom`: Update to v6+ (already done)
- Webpack-related dependencies (if staying with CRA)

## Migration Timeline

**Immediate (Workaround)**: Use legacy OpenSSL provider
**Short-term (1-2 weeks)**: Update React and dependencies
**Long-term (1 month)**: Full Vite migration for modern toolchain

## Resources

- [React 18 Upgrade Guide](https://react.dev/blog/2022/03/08/react-18-upgrade-guide)
- [Vite Migration Guide](https://vitejs.dev/guide/migration.html)
- [Node.js 24 Breaking Changes](https://nodejs.org/en/blog/release/v24.0.0)
- [ESLint v8 Migration Guide](https://eslint.org/docs/latest/use/migrate-to-8.0.0)

## Notes

- The OpenSSL error is due to Node.js 24's stricter cryptographic policies
- React Scripts 4.x is incompatible with Node.js 24
- Vite migration provides the best long-term solution
- Consider this an opportunity to modernize the entire build pipeline