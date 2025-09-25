# Nexus Flutter App

Privacy-first AI productivity suite built with Flutter.

## Getting Started

### Prerequisites

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extension
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. Navigate to the Flutter app directory:
   ```bash
   cd apps/nexus_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Available Commands

From the project root:

```bash
# Development
npm run flutter              # Run the Flutter app
npm run flutter:pub         # Install Flutter dependencies

# Building
npm run flutter:build       # Build release APK
npm run flutter:clean       # Clean build artifacts

# Code Quality
npm run flutter:test        # Run tests
npm run flutter:analyze     # Analyze code
npm run flutter:format     # Format code
```

### Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── theme/             # Theme and styling
│   ├── utils/             # Utility functions
│   └── errors/            # Exception classes
├── features/
│   ├── chat/              # Chat functionality
│   ├── meetings/          # Meeting management
│   ├── notes/             # Note taking
│   └── settings/          # App settings
├── shared/
│   ├── widgets/           # Reusable widgets
│   └── providers/         # Riverpod providers
└── main.dart              # App entry point
```

## Architecture

This Flutter app follows Clean Architecture principles with:

- **State Management**: Riverpod for reactive state management
- **Navigation**: GoRouter for type-safe navigation
- **Theme**: Material 3 design system with light/dark modes
- **Local Storage**: SharedPreferences + Secure Storage
- **Testing**: Unit, widget, and integration tests

## Features (Sprint 1)

✅ Project setup and structure
✅ Theme system with light/dark modes
✅ State management with Riverpod
✅ Linting and code quality
✅ Testing framework
✅ CI/CD pipeline
✅ Monorepo integration

## Development

### Code Style

This project follows Flutter and Dart best practices:
- Use `dart format` for formatting
- Follow linting rules in `analysis_options.yaml`
- Write tests for new features
- Use meaningful commit messages

### Testing

Run tests with:
```bash
flutter test
flutter test --coverage  # With coverage
```

### Building

For Android:
```bash
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```

## Contributing

1. Follow the existing code style
2. Write tests for new features
3. Update documentation as needed
4. Ensure CI checks pass

## Next Steps (Sprint 2+)

- [ ] Navigation system with GoRouter
- [ ] Core UI components
- [ ] Database integration with Drift
- [ ] Audio recording functionality
- [ ] Real-time transcription
- [ ] Chat interface
- [ ] Meeting management
- [ ] Notes system