# Project Nexus Flutter Migration - Sprint Technical Implementation Guide

## Sprint 1: Project Bootstrap & Core Architecture

### Technical Setup

#### Project Initialization
```bash
# Create Flutter project with specific configuration
flutter create nexus_app \
  --org com.nexus \
  --project-name nexus_app \
  --platform android \
  --template app \
  --description "Privacy-first AI productivity suite"

cd nexus_app
```

#### Folder Structure Setup
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   └── validators.dart
│   └── errors/
│       └── exceptions.dart
├── features/
│   ├── chat/
│   ├── meetings/
│   ├── notes/
│   └── settings/
├── shared/
│   ├── widgets/
│   └── providers/
└── main.dart
```

#### Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  
  # Utilities
  logger: ^2.0.0
  uuid: ^4.3.0
  intl: ^0.19.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  riverpod_lint: ^2.3.0
  mockito: ^5.4.0
  golden_toolkit: ^0.15.0
```

#### Linting Configuration (analysis_options.yaml)
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - riverpod_lint

linter:
  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - avoid_web_libraries_in_flutter
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - control_flow_in_finally
    - empty_statements
    - hash_and_equals
    - invariant_booleans
    - iterable_contains_unrelated_type
    - list_remove_unrelated_type
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - no_logic_in_create_state
    - prefer_void_to_null
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_statements
    - unrelated_type_equality_checks
    - unsafe_html
    - use_build_context_synchronously
    - use_key_in_widget_constructors
    - valid_regexps
```

#### Main App Setup (lib/main.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/theme/app_theme.dart';
import 'package:nexus_app/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init();
  
  runApp(
    const ProviderScope(
      child: NexusApp(),
    ),
  );
}

class NexusApp extends ConsumerWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Nexus',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
```

#### Test Setup (test/widget_test.dart)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NexusApp(),
      ),
    );
    
    expect(find.byType(NexusApp), findsOneWidget);
  });
}
```

#### CI/CD Setup (.github/workflows/flutter.yml)
```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
    
    - name: Build APK
      run: flutter build apk --release
      
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

---

## Sprint 2: Navigation & Core UI Components

### Navigation Setup with GoRouter

#### Router Configuration (lib/core/navigation/app_router.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/chat',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ChatScreen(),
            ),
          ),
          GoRoute(
            path: '/meetings',
            name: 'meetings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const MeetingsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'meeting-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MeetingDetailScreen(meetingId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notes',
            name: 'notes',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const NotesScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});
```

#### App Shell with Bottom Navigation (lib/shared/widgets/app_shell.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: 'Meetings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/chat')) return 0;
    if (location.startsWith('/meetings')) return 1;
    if (location.startsWith('/notes')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.goNamed('chat');
        break;
      case 1:
        context.goNamed('meetings');
        break;
      case 2:
        context.goNamed('notes');
        break;
      case 3:
        context.goNamed('settings');
        break;
    }
  }
}
```

#### Component Library (lib/shared/widgets/components.dart)
```dart
import 'package:flutter/material.dart';

// Primary Button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

// Custom Text Field
class NexusTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  
  const NexusTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
      ),
    );
  }
}

// Card Component
class NexusCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  
  const NexusCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// Loading Indicator
class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

// Error Widget
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Theme Configuration (lib/core/theme/app_theme.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';
  
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key) ?? ThemeMode.system.index;
    state = ThemeMode.values[themeIndex];
  }
  
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

---

## Sprint 3: Offline Database Foundation

### Drift Database Setup

#### Dependencies Update (pubspec.yaml)
```yaml
dependencies:
  # Database
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  
  # Mock Data
  faker: ^2.1.0
  
dev_dependencies:
  # Drift code generation
  drift_dev: ^2.15.0
  build_runner: ^2.4.0
```

#### Database Schema (lib/core/database/database.dart)
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// Meetings table
class Meetings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get audioPath => text().nullable()();
  TextColumn get transcript => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get actionItems => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get duration => integer().nullable()(); // in seconds
  TextColumn get tags => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Notes table
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  TextColumn get tags => text().nullable()(); // JSON array
  IntColumn get meetingId => integer().nullable().references(Meetings, #id)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Chat messages table
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get role => text().withLength(min: 1, max: 20)(); // 'user' or 'assistant'
  IntColumn get conversationId => integer()();
  TextColumn get metadata => text().nullable()(); // JSON object
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Chat conversations table
class ChatConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get systemPrompt => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Meetings, Notes, ChatMessages, ChatConversations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Add initial data if needed
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations
      },
    );
  }
  
  // Meeting queries
  Future<List<Meeting>> getAllMeetings() => select(meetings).get();
  
  Stream<List<Meeting>> watchMeetings() {
    return (select(meetings)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();
  }
  
  Future<Meeting> getMeeting(int id) {
    return (select(meetings)..where((t) => t.id.equals(id))).getSingle();
  }
  
  Future<int> insertMeeting(MeetingsCompanion meeting) {
    return into(meetings).insert(meeting);
  }
  
  Future<bool> updateMeeting(MeetingsCompanion meeting) {
    return update(meetings).replace(meeting);
  }
  
  Future<int> deleteMeeting(int id) {
    return (delete(meetings)..where((t) => t.id.equals(id))).go();
  }
  
  // Note queries
  Stream<List<Note>> watchNotes() {
    return (select(notes)
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.updatedAt),
      ])
      ..where((t) => t.isArchived.equals(false)))
      .watch();
  }
  
  // Chat queries
  Stream<List<ChatMessage>> watchConversation(int conversationId) {
    return (select(chatMessages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();
  }
  
  // Full-text search setup
  Future<List<Meeting>> searchMeetings(String query) {
    return (select(meetings)
      ..where((t) => t.title.contains(query) | t.transcript.contains(query)))
      .get();
  }
  
  Future<List<Note>> searchNotes(String query) {
    return (select(notes)
      ..where((t) => t.title.contains(query) | t.content.contains(query)))
      .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'nexus.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

#### Repository Pattern (lib/core/repositories/meeting_repository.dart)
```dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/database/database.dart';

final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(databaseProvider));
});

class MeetingRepository {
  final AppDatabase _db;
  
  MeetingRepository(this._db);
  
  // Create
  Future<int> createMeeting({
    required String title,
    DateTime? startTime,
  }) async {
    return await _db.insertMeeting(
      MeetingsCompanion(
        title: Value(title),
        startTime: Value(startTime ?? DateTime.now()),
      ),
    );
  }
  
  // Read
  Stream<List<Meeting>> watchAllMeetings() {
    return _db.watchMeetings();
  }
  
  Future<Meeting?> getMeetingById(int id) async {
    try {
      return await _db.getMeeting(id);
    } catch (e) {
      return null;
    }
  }
  
  // Update
  Future<bool> updateMeeting(Meeting meeting) async {
    return await _db.updateMeeting(
      meeting.toCompanion(true).copyWith(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  
  Future<void> updateTranscript(int meetingId, String transcript) async {
    final meeting = await getMeetingById(meetingId);
    if (meeting != null) {
      await _db.updateMeeting(
        meeting.toCompanion(true).copyWith(
          transcript: Value(transcript),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
  
  // Delete
  Future<void> deleteMeeting(int id) async {
    await _db.deleteMeeting(id);
  }
  
  // Search
  Future<List<Meeting>> searchMeetings(String query) async {
    if (query.isEmpty) return [];
    return await _db.searchMeetings(query);
  }
  
  // Bulk operations
  Future<void> deleteAllMeetings() async {
    await _db.delete(_db.meetings).go();
  }
  
  Future<int> getMeetingCount() async {
    final count = await _db.meetings.count().getSingle();
    return count;
  }
}
```

#### Mock Data Generator (lib/core/utils/mock_data_generator.dart)
```dart
import 'package:faker/faker.dart';
import 'package:drift/drift.dart';
import 'package:nexus_app/core/database/database.dart';

class MockDataGenerator {
  final AppDatabase db;
  final faker = Faker();
  
  MockDataGenerator(this.db);
  
  Future<void> generateMockData({
    int meetingCount = 20,
    int noteCount = 30,
    int conversationCount = 5,
  }) async {
    // Generate meetings
    for (int i = 0; i < meetingCount; i++) {
      final startTime = faker.date.dateTime(
        minYear: 2024,
        maxYear: 2024,
      );
      final duration = faker.randomGenerator.integer(3600, min: 300);
      
      await db.insertMeeting(
        MeetingsCompanion(
          title: Value(faker.company.name() + ' Meeting'),
          startTime: Value(startTime),
          endTime: Value(startTime.add(Duration(seconds: duration))),
          duration: Value(duration),
          transcript: Value(_generateMockTranscript()),
          summary: Value(faker.lorem.sentences(3).join(' ')),
          actionItems: Value(_generateActionItems()),
          tags: Value('["${faker.lorem.word()}", "${faker.lorem.word()}"]'),
        ),
      );
    }
    
    // Generate notes
    final meetings = await db.getAllMeetings();
    for (int i = 0; i < noteCount; i++) {
      await db.into(db.notes).insert(
        NotesCompanion(
          title: Value(faker.lorem.sentence()),
          content: Value(faker.lorem.sentences(10).join(' ')),
          meetingId: Value(
            i % 3 == 0 && meetings.isNotEmpty
                ? meetings[i % meetings.length].id
                : null,
          ),
          isPinned: Value(faker.randomGenerator.boolean()),
          tags: Value('["${faker.lorem.word()}"]'),
        ),
      );
    }
    
    // Generate chat conversations
    for (int i = 0; i < conversationCount; i++) {
      final conversationId = await db.into(db.chatConversations).insert(
        ChatConversationsCompanion(
          title: Value(faker.lorem.sentence()),
          systemPrompt: const Value('You are a helpful AI assistant.'),
        ),
      );
      
      // Generate messages for each conversation
      final messageCount = faker.randomGenerator.integer(20, min: 5);
      for (int j = 0; j < messageCount; j++) {
        await db.into(db.chatMessages).insert(
          ChatMessagesCompanion(
            content: Value(faker.lorem.sentences(2).join(' ')),
            role: Value(j % 2 == 0 ? 'user' : 'assistant'),
            conversationId: Value(conversationId),
          ),
        );
      }
    }
  }
  
  String _generateMockTranscript() {
    final sentences = <String>[];
    final speakerCount = faker.randomGenerator.integer(3, min: 1);
    
    for (int i = 0; i < 20; i++) {
      final speaker = 'Speaker ${(i % speakerCount) + 1}';
      sentences.add('$speaker: ${faker.lorem.sentence()}');
    }
    
    return sentences.join('\n');
  }
  
  String _generateActionItems() {
    final items = <String>[];
    final count = faker.randomGenerator.integer(5, min: 1);
    
    for (int i = 0; i < count; i++) {
      items.add('- ${faker.lorem.sentence()}');
    }
    
    return items.join('\n');
  }
  
  Future<void> clearAllData() async {
    await db.delete(db.chatMessages).go();
    await db.delete(db.chatConversations).go();
    await db.delete(db.notes).go();
    await db.delete(db.meetings).go();
  }
}
```

#### Database Provider (lib/core/providers/database_provider.dart)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus_app/core/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository providers
final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(databaseProvider));
});

final noteRepositoryProvider = Provider((ref) {
  return NoteRepository(ref.watch(databaseProvider));
});

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(ref.watch(databaseProvider));
});
```

---

## Sprint 4: Data Synchronization & Caching

### Offline Queue System

#### Queue Implementation (lib/core/sync/offline_queue.dart)
```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OperationType { create, update, delete }

class QueuedOperation {
  final String id;
  final OperationType type;
  final String entityType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;
  
  QueuedOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'entityType': entityType,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };
  
  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'],
      type: OperationType.values[json['type']],
      entityType: json['entityType'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

class OfflineQueue {
  static const String _queueKey = 'offline_queue';
  final SharedPreferences _prefs;
  
  OfflineQueue(this._prefs);
  
  Future<void> enqueue(QueuedOperation operation) async {
    final queue = await getQueue();
    queue.add(operation);
    await _saveQueue(queue);
  }
  
  Future<List<QueuedOperation>> getQueue() async {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null) return [];
    
    final jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((json) => QueuedOperation.fromJson(json))
        .toList();
  }
  
  Future<void> _saveQueue(List<QueuedOperation> queue) async {
    final jsonList = queue.map((op) => op.toJson()).toList();
    await _prefs.setString(_queueKey, json.encode(jsonList));
  }
  
  Future<void> removeOperation(String id) async {
    final queue = await getQueue();
    queue.removeWhere((op) => op.id == id);
    await _saveQueue(queue);
  }
  
  Future<void> processQueue() async {
    final queue = await getQueue();
    
    for (final operation in queue) {
      try {
        await _processOperation(operation);
        await removeOperation(operation.id);
      } catch (e) {
        operation.retryCount++;
        if (operation.retryCount >= 3) {
          // Move to dead letter queue or notify user
          await removeOperation(operation.id);
        }
      }
    }
  }
  
  Future<void> _processOperation(QueuedOperation operation) async {
    // This will be implemented when we add sync capability
    // For now, operations are stored locally only
    switch (operation.type) {
      case OperationType.create:
        // Process create
        break;
      case OperationType.update:
        // Process update
        break;
      case OperationType.delete:
        // Process delete
        break;
    }
  }
}
```

#### Cache Manager (lib/core/cache/cache_manager.dart)
```dart
import 'dart:collection';
import 'package:flutter/foundation.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl = const Duration(minutes: 5),
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

class CacheManager<K, V> {
  final int maxSize;
  final LinkedHashMap<K, CacheEntry<V>> _cache = LinkedHashMap();
  
  CacheManager({this.maxSize = 100});
  
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    // Move to end (LRU)
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.data;
  }
  
  void put(K key, V value, {Duration? ttl}) {
    // Remove oldest if at capacity
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = CacheEntry(
      data: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(minutes: 5),
    );
  }
  
  void remove(K key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
  
  void evictExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
  
  @visibleForTesting
  int get size => _cache.length;
}

// Specific cache instances
class MeetingCache extends CacheManager<int, Meeting> {
  MeetingCache() : super(maxSize: 50);
}

class NoteCache extends CacheManager<int, Note> {
  NoteCache() : super(maxSize: 100);
}

// Provider
final meetingCacheProvider = Provider((ref) => MeetingCache());
final noteCacheProvider = Provider((ref) => NoteCache());
```

#### Full-Text Search (lib/core/search/search_engine.dart)
```dart
import 'package:drift/drift.dart';
import 'package:nexus_app/core/database/database.dart';

class SearchEngine {
  final AppDatabase db;
  
  SearchEngine(this.db);
  
  Future<SearchResults> search(String query) async {
    if (query.isEmpty) {
      return SearchResults.empty();
    }
    
    // Normalize query
    final normalizedQuery = query.toLowerCase().trim();
    
    // Search in parallel
    final results = await Future.wait([
      _searchMeetings(normalizedQuery),
      _searchNotes(normalizedQuery),
      _searchChats(normalizedQuery),
    ]);
    
    return SearchResults(
      meetings: results[0] as List<Meeting>,
      notes: results[1] as List<Note>,
      messages: results[2] as List<ChatMessage>,
    );
  }
  
  Future<List<Meeting>> _searchMeetings(String query) async {
    return await (db.select(db.meetings)
      ..where((t) => 
        t.title.lower().contains(query) |
        t.transcript.lower().contains(query) |
        t.summary.lower().contains(query)
      ))
      .get();
  }
  
  Future<List<Note>> _searchNotes(String query) async {
    return await (db.select(db.notes)
      ..where((t) => 
        t.title.lower().contains(query) |
        t.content.lower().contains(query)
      ))
      .get();
  }
  
  Future<List<ChatMessage>> _searchChats(String query) async {
    return await (db.select(db.chatMessages)
      ..where((t) => t.content.lower().contains(query)))
      .get();
  }
  
  // Search with highlighting
  List<TextSpan> highlightText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return spans;
  }
}

class SearchResults {
  final List<Meeting> meetings;
  final List<Note> notes;
  final List<ChatMessage> messages;
  
  SearchResults({
    required this.meetings,
    required this.notes,
    required this.messages,
  });
  
  factory SearchResults.empty() {
    return SearchResults(
      meetings: [],
      notes: [],
      messages: [],
    );
  }
  
  int get totalCount => meetings.length + notes.length + messages.length;
  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => !isEmpty;
}
```

---

## Sprint 5: Audio Recording Foundation

### Audio Recording Implementation

#### Dependencies (pubspec.yaml)
```yaml
dependencies:
  # Audio
  record: ^5.0.0
  just_audio: ^0.9.0
  permission_handler: ^11.0.0
  path_provider: ^2.1.0
```

#### Audio Recorder Service (lib/features/meetings/services/audio_recorder.dart)
```dart
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioRecorderProvider = Provider((ref) => AudioRecorderService());

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<RecordingState>? _stateController;
  StreamController<Amplitude>? _amplitudeController;
  Timer? _amplitudeTimer;
  
  Stream<RecordingState> get stateStream => 
      _stateController?.stream ?? const Stream.empty();
  
  Stream<Amplitude> get amplitudeStream => 
      _amplitudeController?.stream ?? const Stream.empty();
  
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }
  
  Future<void> startRecording() async {
    try {
      // Check permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }
      
      // Setup streams
      _stateController = StreamController<RecordingState>.broadcast();
      _amplitudeController = StreamController<Amplitude>.broadcast();
      
      // Get path for audio file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/recording_$timestamp.m4a';
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      _stateController?.add(RecordingState.recording);
      
      // Start amplitude monitoring
      _amplitudeTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) async {
          final amplitude = await _recorder.getAmplitude();
          _amplitudeController?.add(amplitude);
        },
      );
      
    } catch (e) {
      _stateController?.addError(e);
      rethrow;
    }
  }
  
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      _amplitudeTimer?.cancel();
      _stateController?.add(RecordingState.stopped);
      
      // Clean up streams
      await _stateController?.close();
      await _amplitudeController?.close();
      _stateController = null;
      _amplitudeController = null;
      
      return path;
    } catch (e) {
      _stateController?.addError(e);
      rethrow;
    }
  }
  
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _amplitudeTimer?.cancel();
    _stateController?.add(RecordingState.paused);
  }
  
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _stateController?.add(RecordingState.recording);
    
    // Resume amplitude monitoring
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        final amplitude = await _recorder.getAmplitude();
        _amplitudeController?.add(amplitude);
      },
    );
  }
  
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }
  
  void dispose() {
    _amplitudeTimer?.cancel();
    _stateController?.close();
    _amplitudeController?.close();
    _recorder.dispose();
  }
}

enum RecordingState {
  idle,
  recording,
  paused,
  stopped,
}
```

#### Recording UI (lib/features/meetings/screens/recording_screen.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    
    // Request permission
    final hasPermission = await recorder.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required'),
          ),
        );
      }
      return;
    }
    
    await recorder.startRecording();
    
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    
    _animationController.repeat();
    
    // Start duration timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }
  
  void _stopRecording() async {
    final recorder = ref.read(audioRecorderProvider);
    final path = await recorder.stopRecording();
    
    _timer?.cancel();
    _animationController.stop();
    _animationController.reset();
    
    setState(() {
      _isRecording = false;
    });
    
    if (path != null && mounted) {
      // Save to database
      final meetingRepo = ref.read(meetingRepositoryProvider);
      final meetingId = await meetingRepo.createMeeting(
        title: 'Recording ${DateTime.now().toString()}',
      );
      
      await meetingRepo.updateAudioPath(meetingId, path);
      
      // Navigate to meeting detail
      context.go('/meetings/$meetingId');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(audioRecorderProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Recording'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recording indicator
            if (_isRecording)
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Recording...'),
                ],
              ),
            
            const SizedBox(height: 48),
            
            // Amplitude visualization
            if (_isRecording)
              StreamBuilder<Amplitude>(
                stream: recorder.amplitudeStream,
                builder: (context, snapshot) {
                  final amplitude = snapshot.data;
                  final level = amplitude?.current ?? -40.0;
                  final normalizedLevel = (level + 40) / 40;
                  
                  return Container(
                    height: 100,
                    width: 300,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomPaint(
                      painter: WaveformPainter(level: normalizedLevel),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 48),
            
            // Record button
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _isRecording ? 'Tap to stop' : 'Tap to record',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class WaveformPainter extends CustomPainter {
  final double level;
  
  WaveformPainter({required this.level});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final midY = size.height / 2;
    final amplitude = size.height * level * 0.4;
    
    path.moveTo(0, midY);
    
    for (double x = 0; x <= size.width; x += 5) {
      final y = midY + amplitude * (x / size.width - 0.5) * 2;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
```

#### Audio Player (lib/features/meetings/widgets/audio_player.dart)
```dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  
  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
  });
  
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }
  
  Future<void> _initPlayer() async {
    try {
      await _player.setAudioSource(
        AudioSource.file(widget.audioPath),
      );
      
      _player.durationStream.listen((duration) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      });
      
      _player.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });
      
      _player.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
      });
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }
  
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  
  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }
  
  void _changeSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    
    setState(() {
      _speed = speeds[nextIndex];
    });
    
    _player.setSpeed(_speed);
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: Slider(
                value: _position.inSeconds.toDouble(),
                min: 0,
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  _player.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            
            // Time display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Speed control
                TextButton(
                  onPressed: _changeSpeed,
                  child: Text('${_speed}x'),
                ),
                
                const SizedBox(width: 16),
                
                // Skip backward
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 32,
                  onPressed: () {
                    _player.seek(
                      _position - const Duration(seconds: 10),
                    );
                  },
                ),
                
                // Play/pause
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  iconSize: 48,
                  onPressed: _togglePlayPause,
                ),
                
                // Skip forward
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 32,
                  onPressed: () {
                    _player.seek(
                      _position + const Duration(seconds: 10),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Sprint 6: ML Kit Speech-to-Text Integration

### Google ML Kit Integration

#### Dependencies (pubspec.yaml)
```yaml
dependencies:
  # ML Kit
  google_mlkit_speech_to_text: ^0.1.0  # Note: This is hypothetical
  google_mlkit_language_id: ^0.5.0
  google_mlkit_translation: ^0.5.0
  
  # For custom models
  tflite_flutter: ^0.10.0
```

#### ML Service (lib/core/ml/ml_service.dart)
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final mlServiceProvider = Provider((ref) => MLService());

class MLService {
  LanguageIdentifier? _languageIdentifier;
  Interpreter? _customModel;
  
  Future<void> initialize() async {
    // Initialize language identifier
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    
    // Load custom model if needed
    await _loadCustomModel();
  }
  
  Future<void> _loadCustomModel() async {
    try {
      // Load model from assets
      _customModel = await Interpreter.fromAsset('assets/models/custom_model.tflite');
    } catch (e) {
      debugPrint('Failed to load custom model: $e');
    }
  }
  
  Future<String> identifyLanguage(String text) async {
    if (_languageIdentifier == null) {
      await initialize();
    }
    
    try {
      final language = await _languageIdentifier!.identifyLanguage(text);
      return language;
    } catch (e) {
      return 'en'; // Default to English
    }
  }
  
  void dispose() {
    _languageIdentifier?.close();
    _customModel?.close();
  }
}

// Speech-to-text service using on-device recognition
class SpeechToTextService {
  final StreamController<TranscriptionResult> _transcriptionController =
      StreamController.broadcast();
  
  Stream<TranscriptionResult> get transcriptionStream =>
      _transcriptionController.stream;
  
  // Using platform channels for native implementation
  static const platform = MethodChannel('com.nexus.speech');
  
  Future<void> startListening({
    required String audioPath,
    String languageCode = 'en-US',
  }) async {
    try {
      // Start native speech recognition
      platform.setMethodCallHandler(_handleMethod);
      
      await platform.invokeMethod('startTranscription', {
        'audioPath': audioPath,
        'languageCode': languageCode,
      });
    } catch (e) {
      _transcriptionController.addError(e);
    }
  }
  
  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onTranscriptionResult':
        final text = call.arguments['text'] as String;
        final isFinal = call.arguments['isFinal'] as bool;
        final confidence = call.arguments['confidence'] as double;
        
        _transcriptionController.add(
          TranscriptionResult(
            text: text,
            isFinal: isFinal,
            confidence: confidence,
          ),
        );
        break;
        
      case 'onTranscriptionError':
        final error = call.arguments['error'] as String;
        _transcriptionController.addError(Exception(error));
        break;
    }
  }
  
  Future<void> stopListening() async {
    await platform.invokeMethod('stopTranscription');
  }
  
  void dispose() {
    _transcriptionController.close();
  }
}

class TranscriptionResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;
  
  TranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.confidence,
  }) : timestamp = DateTime.now();
}
```

#### Native Android Implementation (android/app/src/main/kotlin/.../SpeechRecognitionHandler.kt)
```kotlin
package com.nexus.app

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.MethodChannel
import java.util.*

class SpeechRecognitionHandler(private val channel: MethodChannel) : RecognitionListener {
    private var speechRecognizer: SpeechRecognizer? = null
    
    fun startListening(languageCode: String) {
        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            speechRecognizer?.setRecognitionListener(this)
        }
        
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, 
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageCode)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        
        speechRecognizer?.startListening(intent)
    }
    
    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(
            SpeechRecognizer.RESULTS_RECOGNITION
        )
        
        matches?.firstOrNull()?.let { text ->
            channel.invokeMethod("onTranscriptionResult", mapOf(
                "text" to text,
                "isFinal" to false,
                "confidence" to 0.8
            ))
        }
    }
    
    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(
            SpeechRecognizer.RESULTS_RECOGNITION
        )
        val scores = results?.getFloatArray(
            SpeechRecognizer.CONFIDENCE_SCORES
        )
        
        matches?.firstOrNull()?.let { text ->
            channel.invokeMethod("onTranscriptionResult", mapOf(
                "text" to text,
                "isFinal" to true,
                "confidence" to (scores?.firstOrNull() ?: 0.9)
            ))
        }
    }
    
    override fun onError(error: Int) {
        val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
        }
        
        channel.invokeMethod("onTranscriptionError", mapOf(
            "error" to errorMessage
        ))
    }
    
    // Other RecognitionListener methods...
}
```

#### Real-time Transcription UI (lib/features/meetings/widgets/transcription_view.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranscriptionView extends ConsumerWidget {
  final int meetingId;
  
  const TranscriptionView({
    super.key,
    required this.meetingId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechService = ref.watch(speechToTextServiceProvider);
    
    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.transcribe, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Transcription',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                // Confidence indicator
                StreamBuilder<TranscriptionResult>(
                  stream: speechService.transcriptionStream,
                  builder: (context, snapshot) {
                    final confidence = snapshot.data?.confidence ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(confidence * 100).toInt()}%',
                        style: TextStyle(
                          color: _getConfidenceColor(confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<TranscriptionResult>(
                stream: speechService.transcriptionStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Waiting for speech...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  
                  final result = snapshot.data!;
                  
                  return ListView(
                    children: [
                      // Current transcription
                      if (!result.isFinal)
                        Text(
                          result.text,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      // Final transcriptions
                      if (result.isFinal)
                        Text(
                          result.text,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }
}
```

---

## Sprint 7-16: Comprehensive Implementation Guide

Due to length constraints, I'll provide a structured overview of the remaining sprints with key implementation patterns:

### Sprint 7: Meeting Management UI
- **ListView with Dismissible**: Swipe-to-delete meetings
- **Search/Filter**: Using Drift's dynamic queries
- **Tags**: JSON storage with custom widget
- **Export**: Platform channels for native share

### Sprint 8: Meeting Analytics
- **TensorFlow Lite**: Custom summarization model
- **Statistics**: Drift aggregation queries
- **Charts**: fl_chart package integration
- **PDF Export**: pdf package with custom templates

### Sprint 9: Chat Interface
- **Message Bubbles**: Custom painter for tail
- **Emoji Support**: emoji_picker_flutter package
- **Draft Persistence**: SharedPreferences for drafts
- **Pagination**: Drift's limit/offset queries

### Sprint 10: Local AI Processing
- **TFLite Models**: 
  ```dart
  final interpreter = await Interpreter.fromAsset('model.tflite');
  interpreter.run(input, output);
  ```
- **Response Streaming**: Character-by-character display
- **Context Management**: Sliding window approach
- **Hardware Acceleration**: GPU delegate setup

### Sprint 11: Chat Enhancement
- **Search Highlighting**: RichText with TextSpan
- **Export**: Markdown generation with custom formatter
- **Templates**: YAML storage with hot reload
- **Quick Actions**: BottomSheet with GridView

### Sprint 12: Notes Core
- **Rich Text Editor**: flutter_quill package
- **Auto-save**: Debounced saves with RxDart
- **Markdown**: markdown package for parsing
- **Folders**: Tree structure in database

### Sprint 13: Notes Advanced
- **Bi-directional Links**: Junction table in Drift
- **Templates**: Mustache-style variable replacement
- **Share**: Platform channels for native sharing
- **Print**: printing package integration

### Sprint 14: Calendar Integration
- **OAuth 2.0**: google_sign_in package
- **Token Storage**: flutter_secure_storage
- **Calendar Views**: table_calendar package
- **Event Linking**: Foreign key relationships

### Sprint 15: Performance Optimization
- **Profiling**: Flutter DevTools integration
- **Lazy Loading**: ListView.builder everywhere
- **Image Caching**: cached_network_image
- **Battery**: workmanager for background tasks

### Sprint 16: Polish & Release
- **Animations**: Hero, AnimatedContainer, Lottie
- **Empty States**: Custom illustrations
- **Settings**: Nested preference screens
- **Release**: Fastlane automation setup

## Testing Strategy for All Sprints

### Unit Test Template
```dart
void main() {
  group('Repository Tests', () {
    late AppDatabase database;
    late MeetingRepository repository;
    
    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = MeetingRepository(database);
    });
    
    tearDown(() async {
      await database.close();
    });
    
    test('should create meeting', () async {
      final id = await repository.createMeeting(title: 'Test');
      expect(id, greaterThan(0));
    });
  });
}
```

### Widget Test Template
```dart
void main() {
  testWidgets('Component renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyWidget(),
        ),
      ),
    );
    
    expect(find.text('Expected Text'), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    expect(find.byType(Dialog), findsOneWidget);
  });
}
```

### Integration Test Template
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('End-to-end flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    
    // Verify
    expect(find.text('Recording'), findsOneWidget);
  });
}
```

This comprehensive guide provides the technical foundation for implementing all 16 sprints of the Flutter migration, with specific code examples, patterns, and best practices for each major component.