# iOS CI/CD Setup TODO

This document tracks the tasks needed to set up iOS deployment and validation workflows.

## iOS Deployment Workflow (`ios-deploy.yml`)

### Prerequisites
- [ ] **Apple Developer Account Setup**
  - [ ] Configure Apple Developer Team ID
  - [ ] Set up provisioning profiles for different environments (Dev/Staging/Production)
  - [ ] Create distribution certificates

- [ ] **GitHub Secrets Configuration**
  - [ ] `APPLE_TEAM_ID` - Your Apple Developer Team ID
  - [ ] `MATCH_PASSWORD` - Password for fastlane match repository
  - [ ] `MATCH_GIT_URL` - Git repository URL for certificates/profiles storage
  - [ ] `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API key ID
  - [ ] `APP_STORE_CONNECT_API_ISSUER_ID` - App Store Connect API issuer ID
  - [ ] `APP_STORE_CONNECT_API_KEY` - App Store Connect API private key (base64 encoded)

### Workflow Features to Implement
- [ ] **Xcode Project Validation**
  - [ ] Validate project file integrity
  - [ ] Check scheme configurations
  - [ ] Verify Swift Package Manager dependencies
  
- [ ] **Build Process**
  - [ ] Support for multiple build configurations (Debug/Release)
  - [ ] Code signing with fastlane match
  - [ ] Archive generation for App Store/TestFlight
  
- [ ] **Testing**
  - [ ] Unit test execution
  - [ ] UI test execution (if applicable)
  - [ ] Code coverage reporting
  
- [ ] **Deployment Options**
  - [ ] TestFlight deployment for beta testing
  - [ ] App Store deployment for production releases
  - [ ] Ad-hoc distribution for internal testing

### File Structure
```
.github/workflows/ios-deploy.yml
fastlane/
├── Fastfile
├── Appfile
└── Matchfile
```

## iOS Validation in Setup Workflow

### Features to Add Back
- [ ] **Xcode Environment Setup**
  - [ ] Flexible Xcode version selection
  - [ ] Proper error handling for different macOS runners
  
- [ ] **Project Validation**
  - [ ] Xcode project file integrity checks
  - [ ] Swift Package dependency resolution
  - [ ] Build validation without code signing
  
- [ ] **Integration with Main Validation**
  - [ ] Add iOS validation job back to `validate-setup.yml`
  - [ ] Ensure it runs only when iOS files change

## Implementation Steps

1. **Phase 1: Basic Validation**
   - Add iOS project validation back to `validate-setup.yml`
   - Focus on project file integrity and dependency resolution
   
2. **Phase 2: Build Setup**
   - Create basic `ios-deploy.yml` workflow
   - Implement build without signing for validation
   
3. **Phase 3: Fastlane Integration**
   - Set up fastlane for certificate management
   - Configure match for code signing
   
4. **Phase 4: Deployment**
   - Add TestFlight deployment
   - Configure App Store deployment for releases

## References
- [GitHub Actions for iOS](https://docs.github.com/en/actions/guides/building-and-testing-swift)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

## Notes
- iOS workflows were temporarily removed due to Xcode project validation issues
- The project uses manual code signing currently (`CODE_SIGN_STYLE = Manual`)
- Bundle identifier: `co.coveapp.CoveApp`
- Minimum iOS version: 17.0 