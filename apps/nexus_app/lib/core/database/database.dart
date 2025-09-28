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
  
  Stream<Meeting?> watchMeeting(int id) {
    return (select(meetings)..where((t) => t.id.equals(id))).watchSingleOrNull();
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
  
  Future<List<Note>> getAllNotes() => select(notes).get();
  
  Future<Note> getNote(int id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingle();
  }
  
  Future<int> insertNote(NotesCompanion note) {
    return into(notes).insert(note);
  }
  
  Future<bool> updateNote(NotesCompanion note) {
    return update(notes).replace(note);
  }
  
  Future<int> deleteNote(int id) {
    return (delete(notes)..where((t) => t.id.equals(id))).go();
  }
  
  // Chat queries
  Stream<List<ChatMessage>> watchConversation(int conversationId) {
    return (select(chatMessages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();
  }
  
  Future<List<ChatConversation>> getAllConversations() {
    return (select(chatConversations)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .get();
  }
  
  Stream<List<ChatConversation>> watchConversations() {
    return (select(chatConversations)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();
  }
  
  Future<ChatConversation> getConversation(int id) {
    return (select(chatConversations)..where((t) => t.id.equals(id))).getSingle();
  }
  
  Future<int> insertConversation(ChatConversationsCompanion conversation) {
    return into(chatConversations).insert(conversation);
  }
  
  Future<int> insertMessage(ChatMessagesCompanion message) {
    return into(chatMessages).insert(message);
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
  
  Future<List<ChatMessage>> searchMessages(String query) {
    return (select(chatMessages)
      ..where((t) => t.content.contains(query)))
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