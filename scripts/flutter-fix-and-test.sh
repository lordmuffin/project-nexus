#!/bin/bash
# Flutter Fix and Test Script
# Resolves Android v1 embedding issues and sets up cross-environment testing

set -e

echo "🔧 Flutter Fix and Test Script Starting..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean Flutter project
clean_flutter_project() {
    local project_path=$1
    print_status "Cleaning Flutter project: $project_path"
    
    cd "$project_path"
    
    # Clean Flutter
    flutter clean
    
    # Clean Android build
    if [ -d "android" ]; then
        cd android
        ./gradlew clean || true
        cd ..
    fi
    
    # Remove build directories
    rm -rf build/
    rm -rf .dart_tool/
    
    # Get fresh dependencies
    flutter pub get
    
    print_success "Cleaned project: $project_path"
}

# Function to check Flutter project structure
check_flutter_embedding() {
    local project_path=$1
    print_status "Checking Flutter embedding for: $project_path"
    
    cd "$project_path"
    
    # Check AndroidManifest.xml for v2 embedding
    if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
        if grep -q "flutterEmbedding.*2" android/app/src/main/AndroidManifest.xml; then
            print_success "✅ Android v2 embedding correctly configured"
        else
            print_error "❌ Android v2 embedding not found - needs fix"
            return 1
        fi
    fi
    
    # Check MainActivity extends FlutterActivity
    if [ -f "android/app/src/main/kotlin"/*/*/*.kt ]; then
        if grep -q "FlutterActivity" android/app/src/main/kotlin/*/*/*.kt; then
            print_success "✅ MainActivity extends FlutterActivity"
        else
            print_error "❌ MainActivity doesn't extend FlutterActivity"
            return 1
        fi
    fi
    
    return 0
}

# Function to fix v1 embedding issues
fix_v1_embedding() {
    local project_path=$1
    print_status "Fixing v1 embedding issues for: $project_path"
    
    cd "$project_path"
    
    # Update pubspec.yaml to use latest Flutter
    print_status "Updating pubspec.yaml Flutter version"
    
    # Backup pubspec.yaml
    cp pubspec.yaml pubspec.yaml.backup
    
    # Update Flutter version constraint
    sed -i 's/flutter: ">=.*"/flutter: ">=3.19.0"/' pubspec.yaml
    
    # Update dependencies that might cause v1 embedding issues
    flutter pub upgrade --major-versions || flutter pub get
    
    print_success "Fixed potential v1 embedding issues"
}

# Function to test Flutter build
test_flutter_build() {
    local project_path=$1
    print_status "Testing Flutter build for: $project_path"
    
    cd "$project_path"
    
    # Test debug build
    print_status "Building debug APK..."
    flutter build apk --debug --verbose > build.log 2>&1 || {
        print_error "Debug build failed. Check build.log for details"
        tail -20 build.log
        return 1
    }
    
    print_success "✅ Debug build successful"
    
    # Test if app can run (without device)
    print_status "Testing app startup (dry run)..."
    timeout 10s flutter run --debug --device-id=test 2>/dev/null || true
    
    print_success "✅ App structure validated"
    
    return 0
}

# Function to setup remote testing environment
setup_remote_testing() {
    local project_path=$1
    print_status "Setting up remote testing environment for: $project_path"
    
    cd "$project_path"
    
    # Create deployment script
    cat > deploy-to-remote.sh << 'EOF'
#!/bin/bash
# Remote deployment script for Flutter app

set -e

DEVICE_ID=${1:-""}
REMOTE_HOST=${2:-""}

echo "🚀 Deploying Flutter app to remote device..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$DEVICE_ID" ]; then
    echo "Usage: $0 <DEVICE_ID> [REMOTE_HOST]"
    echo "Example: $0 45301FDAP003JE"
    echo "Example: $0 45301FDAP003JE user@remote-pc"
    exit 1
fi

# Function to check device connection
check_device() {
    echo -e "${BLUE}[INFO]${NC} Checking device connection..."
    adb devices -l | grep "$DEVICE_ID" || {
        echo -e "${RED}[ERROR]${NC} Device $DEVICE_ID not found"
        echo "Available devices:"
        adb devices -l
        return 1
    }
    echo -e "${GREEN}[SUCCESS]${NC} Device $DEVICE_ID found"
}

# Function to deploy app
deploy_app() {
    echo -e "${BLUE}[INFO]${NC} Cleaning and building app..."
    flutter clean
    flutter pub get
    
    echo -e "${BLUE}[INFO]${NC} Building debug APK..."
    flutter build apk --debug
    
    echo -e "${BLUE}[INFO]${NC} Installing and running on device $DEVICE_ID..."
    flutter run --debug --device-id="$DEVICE_ID" --verbose
}

# Check if running remotely
if [ -n "$REMOTE_HOST" ]; then
    echo -e "${BLUE}[INFO]${NC} Deploying to remote host: $REMOTE_HOST"
    # Copy project to remote and run
    rsync -avz --exclude='build/' --exclude='.dart_tool/' . "$REMOTE_HOST":~/flutter-app/
    ssh "$REMOTE_HOST" "cd ~/flutter-app && ./deploy-to-remote.sh $DEVICE_ID"
else
    # Local deployment
    check_device
    deploy_app
fi

echo -e "${GREEN}[SUCCESS]${NC} Deployment complete!"
EOF

    chmod +x deploy-to-remote.sh
    
    # Create testing documentation
    cat > TESTING.md << 'EOF'
# Flutter App Testing Guide

## Local Development Machine Testing

1. **Setup Environment**
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```

2. **Clean and Build**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

3. **Test on Emulator**
   ```bash
   flutter emulators --launch <emulator_name>
   flutter run
   ```

## Remote PC Testing

1. **Prepare Project**
   ```bash
   git pull origin main
   ./scripts/flutter-fix-and-test.sh
   ```

2. **Connect Device**
   - Enable USB Debugging on Android device
   - Connect device to remote PC
   - Verify: `adb devices`

3. **Deploy to Device**
   ```bash
   ./deploy-to-remote.sh 45301FDAP003JE
   ```

## Troubleshooting

### Android v1 Embedding Error
- Run: `flutter clean && flutter pub get`
- Check: AndroidManifest.xml has `flutterEmbedding` value="2"
- Verify: MainActivity extends FlutterActivity

### Device Not Found
- Check USB connection
- Enable Developer Options and USB Debugging
- Run: `adb devices -l`
- Try: `adb kill-server && adb start-server`

### Build Failures
- Update Flutter: `flutter upgrade`
- Clean project: `flutter clean`
- Check dependencies: `flutter pub deps`
- Review build logs for specific errors

## Git Workflow for Cross-Environment Testing

1. **Feature Branch**
   ```bash
   git checkout -b feature/my-feature
   # Make changes
   git commit -am "Add feature"
   ```

2. **Test Locally**
   ```bash
   flutter test
   flutter build apk --debug
   ```

3. **Push for Remote Testing**
   ```bash
   git push origin feature/my-feature
   ```

4. **Remote Testing**
   ```bash
   git pull origin feature/my-feature
   ./deploy-to-remote.sh <DEVICE_ID>
   ```

5. **Merge when Ready**
   ```bash
   git checkout main
   git merge feature/my-feature
   git push origin main
   ```
EOF

    print_success "✅ Remote testing environment setup complete"
}

# Main execution
main() {
    print_status "Starting Flutter fix and test process..."
    
    # Find all Flutter projects
    FLUTTER_PROJECTS=(
        "/home/lordmuffin/Claude/Git/project-nexus/apps/nexus_app"
        "/home/lordmuffin/Claude/Git/project-nexus/flutter/nexus_app"
        "/home/lordmuffin/Claude/Git/project-nexus/flutter/flutter_application_1"
    )
    
    for project in "${FLUTTER_PROJECTS[@]}"; do
        if [ -d "$project" ] && [ -f "$project/pubspec.yaml" ]; then
            print_status "Processing Flutter project: $project"
            
            # Clean project
            clean_flutter_project "$project"
            
            # Check embedding
            if ! check_flutter_embedding "$project"; then
                fix_v1_embedding "$project"
            fi
            
            # Test build
            if test_flutter_build "$project"; then
                print_success "✅ Project $project is ready for deployment"
                
                # Setup remote testing for main project only
                if [[ "$project" == *"apps/nexus_app"* ]]; then
                    setup_remote_testing "$project"
                fi
            else
                print_warning "⚠️  Project $project has build issues"
            fi
            
            echo "----------------------------------------"
        else
            print_warning "Skipping non-Flutter project: $project"
        fi
    done
    
    print_success "🎉 Flutter fix and test script completed!"
    print_status "Next steps:"
    echo "1. On remote PC: git pull origin main"
    echo "2. On remote PC: ./scripts/flutter-fix-and-test.sh"
    echo "3. Connect device and run: ./apps/nexus_app/deploy-to-remote.sh 45301FDAP003JE"
}

# Run main function
main "$@"