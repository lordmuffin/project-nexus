#!/bin/bash
# Validate Flutter Setup for Cross-Environment Testing

set -e

echo "🔍 Validating Flutter Setup for Cross-Environment Testing"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success_count=0
total_checks=8

check_passed() {
    success_count=$((success_count + 1))
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

check_failed() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    echo -e "${YELLOW}   Solution: $2${NC}"
}

check_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    echo -e "${YELLOW}   Note: $2${NC}"
}

echo -e "${BLUE}Checking Flutter Environment...${NC}"

# Check 1: Flutter installation
if command -v flutter &> /dev/null; then
    check_passed "Flutter is installed ($(flutter --version | head -1))"
else
    check_failed "Flutter not found" "Install Flutter SDK"
fi

# Check 2: Java environment
java_version=$(java -version 2>&1 | head -1)
if echo "$java_version" | grep -q "21.0"; then
    check_passed "Java version is compatible ($java_version)"
elif echo "$java_version" | grep -q "24.0"; then
    check_warning "Using system Java 24 instead of Android Studio JDK" "Set JAVA_HOME to Android Studio JDK"
else
    check_failed "Java version issue ($java_version)" "Install OpenJDK 21 or use Android Studio JDK"
fi

# Check 3: Android SDK
if [ -d "/home/lordmuffin/Android/Sdk" ]; then
    check_passed "Android SDK found"
else
    check_failed "Android SDK not found" "Install Android SDK via Android Studio"
fi

# Check 4: ADB available
if command -v adb &> /dev/null; then
    check_passed "ADB is available"
else
    check_failed "ADB not found" "Add Android SDK platform-tools to PATH"
fi

# Get script directory to check relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check 5: Main Flutter project structure
if [ -f "$SCRIPT_DIR/apps/nexus_app/pubspec.yaml" ] && grep -q "name: nexus_app" "$SCRIPT_DIR/apps/nexus_app/pubspec.yaml"; then
    check_passed "Main Flutter project (nexus_app) found"
else
    check_failed "Main Flutter project not found" "Check repository structure"
fi

# Check 6: Android v2 embedding configuration
if [ -f "$SCRIPT_DIR/apps/nexus_app/android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q "flutterEmbedding" "$SCRIPT_DIR/apps/nexus_app/android/app/src/main/AndroidManifest.xml" && \
       grep -q "android:value=\"2\"" "$SCRIPT_DIR/apps/nexus_app/android/app/src/main/AndroidManifest.xml"; then
        check_passed "Android v2 embedding correctly configured"
    else
        check_failed "Android v2 embedding not configured" "Check AndroidManifest.xml"
    fi
else
    check_failed "AndroidManifest.xml not found" "Check Flutter project structure"
fi

# Check 7: MainActivity configuration
mainactivity_file="$SCRIPT_DIR/apps/nexus_app/android/app/src/main/kotlin/com/nexus/nexus_app/MainActivity.kt"
if [ -f "$mainactivity_file" ]; then
    if grep -q "FlutterActivity" "$mainactivity_file"; then
        check_passed "MainActivity extends FlutterActivity"
    else
        check_failed "MainActivity doesn't extend FlutterActivity" "Update MainActivity to extend FlutterActivity"
    fi
else
    check_failed "MainActivity.kt not found" "Check Flutter Android project structure"
fi

# Check 8: Deployment script
if [ -f "$SCRIPT_DIR/apps/nexus_app/deploy-remote.sh" ] && [ -x "$SCRIPT_DIR/apps/nexus_app/deploy-remote.sh" ]; then
    check_passed "Deployment script is ready"
else
    check_failed "Deployment script missing or not executable" "Run setup script to create deployment files"
fi

echo ""
echo -e "${BLUE}Summary: $success_count/$total_checks checks passed${NC}"

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 All checks passed! Ready for cross-environment testing${NC}"
    echo ""
    echo -e "${BLUE}Next steps for remote PC:${NC}"
    echo "1. git pull origin main"
    echo "2. ./validate-flutter-setup.sh"
    echo "3. cd apps/nexus_app"
    echo "4. ./deploy-remote.sh 45301FDAP003JE"
    exit 0
elif [ $success_count -ge 6 ]; then
    echo -e "${YELLOW}⚠️  Most checks passed. Fix warnings for best results${NC}"
    exit 0
else
    echo -e "${RED}❌ Critical issues found. Fix failed checks before deployment${NC}"
    exit 1
fi