import 'package:faker/faker.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:math';
import 'package:nexus_app/core/database/database.dart';

class MockDataGenerator {
  final AppDatabase db;
  final Faker faker = Faker();
  final Random random = Random();
  
  MockDataGenerator(this.db);
  
  Future<void> generateMockData({
    int meetingCount = 20,
    int noteCount = 30,
    int conversationCount = 5,
  }) async {
    await _generateMockMeetings(meetingCount);
    await _generateMockNotes(noteCount);
    await _generateMockConversations(conversationCount);
  }
  
  // Generate realistic meetings
  Future<void> _generateMockMeetings(int count) async {
    final meetingTypes = [
      'Team Standup',
      'Project Planning',
      'Client Review',
      'Sprint Retrospective',
      'Design Review',
      'Strategy Session',
      'All Hands',
      'Product Demo',
      'Stakeholder Update',
      '1:1 Meeting'
    ];
    
    for (int i = 0; i < count; i++) {
      final meetingType = meetingTypes[random.nextInt(meetingTypes.length)];
      final startTime = faker.date.dateTime(
        minYear: 2024,
        maxYear: 2024,
      );
      final duration = 300 + random.nextInt(3300); // 5 min to 1 hour
      final endTime = startTime.add(Duration(seconds: duration));
      
      // Generate tags
      final possibleTags = ['important', 'urgent', 'weekly', 'client', 'internal', 'review', 'planning'];
      final tagCount = random.nextInt(3) + 1;
      final tags = List.generate(tagCount, (i) => possibleTags[random.nextInt(possibleTags.length)]);
      
      await db.insertMeeting(
        MeetingsCompanion(
          title: Value('$meetingType - ${faker.company.name()}'),
          startTime: Value(startTime),
          endTime: Value(endTime),
          duration: Value(duration),
          transcript: Value(_generateMockTranscript()),
          summary: Value(_generateMeetingSummary()),
          actionItems: Value(_generateActionItems()),
          tags: Value(jsonEncode(tags)),
        ),
      );
    }
  }
  
  // Generate realistic notes
  Future<void> _generateMockNotes(int count) async {
    final meetings = await db.getAllMeetings();
    
    final noteTypes = [
      'Meeting Notes',
      'Project Ideas',
      'Research Notes',
      'TODO List',
      'Decision Log',
      'Quick Thoughts',
      'Reference Material',
      'Code Snippets',
      'Design Specs',
      'User Feedback'
    ];
    
    for (int i = 0; i < count; i++) {
      final noteType = noteTypes[random.nextInt(noteTypes.length)];
      
      // Sometimes link to a meeting (30% chance)
      int? meetingId;
      if (meetings.isNotEmpty && random.nextDouble() < 0.3) {
        meetingId = meetings[random.nextInt(meetings.length)].id;
      }
      
      // Generate tags
      final possibleTags = ['important', 'draft', 'personal', 'work', 'ideas', 'urgent', 'reference'];
      final tagCount = random.nextInt(4);
      final tags = List.generate(tagCount, (i) => possibleTags[random.nextInt(possibleTags.length)]);
      
      await db.insertNote(
        NotesCompanion(
          title: Value('$noteType: ${faker.lorem.sentence()}'),
          content: Value(_generateNoteContent()),
          meetingId: Value(meetingId),
          isPinned: Value(random.nextDouble() < 0.2), // 20% chance of being pinned
          tags: Value(tags.isNotEmpty ? jsonEncode(tags) : null),
        ),
      );
    }
  }
  
  // Generate realistic chat conversations
  Future<void> _generateMockConversations(int count) async {
    final conversationTopics = [
      'Help with Flutter development',
      'Code review questions',
      'Design system discussion',
      'Database schema planning',
      'API integration help',
      'Performance optimization',
      'Testing strategies',
      'Deployment questions',
      'UI/UX feedback',
      'Technical documentation'
    ];
    
    for (int i = 0; i < count; i++) {
      final topic = conversationTopics[random.nextInt(conversationTopics.length)];
      
      final conversationId = await db.insertConversation(
        ChatConversationsCompanion(
          title: Value(topic),
          systemPrompt: Value(_getRandomSystemPrompt()),
        ),
      );
      
      // Generate messages for each conversation
      await _generateMessagesForConversation(conversationId, topic);
    }
  }
  
  Future<void> _generateMessagesForConversation(int conversationId, String topic) async {
    final messageCount = 4 + random.nextInt(12); // 4-15 messages
    
    for (int i = 0; i < messageCount; i++) {
      final isUserMessage = i % 2 == 0; // Alternate between user and assistant
      
      String content;
      if (isUserMessage) {
        content = _generateUserMessage(topic, i == 0);
      } else {
        content = _generateAssistantMessage(topic);
      }
      
      await db.insertMessage(
        ChatMessagesCompanion(
          content: Value(content),
          role: Value(isUserMessage ? 'user' : 'assistant'),
          conversationId: Value(conversationId),
        ),
      );
      
      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }
  
  String _generateMockTranscript() {
    final speakers = ['Alice', 'Bob', 'Charlie', 'Diana'];
    final sentences = <String>[];
    
    final sentenceCount = 15 + random.nextInt(20);
    
    for (int i = 0; i < sentenceCount; i++) {
      final speaker = speakers[random.nextInt(speakers.length)];
      final sentence = faker.lorem.sentence();
      sentences.add('[$speaker]: $sentence');
    }
    
    return sentences.join('\n');
  }
  
  String _generateMeetingSummary() {
    final summaries = [
      'Discussed project timeline and key deliverables. Identified potential risks and mitigation strategies.',
      'Reviewed current progress and addressed blocking issues. Planned next sprint priorities.',
      'Analyzed user feedback and decided on feature improvements. Set implementation timeline.',
      'Evaluated technical architecture options and made final decision. Assigned implementation tasks.',
      'Conducted comprehensive project review with stakeholders. Gathered requirements for next phase.',
    ];
    
    return summaries[random.nextInt(summaries.length)];
  }
  
  String _generateActionItems() {
    final items = <String>[];
    final actionCount = 2 + random.nextInt(4);
    
    final possibleActions = [
      'Update project documentation',
      'Schedule follow-up meeting',
      'Review and approve design mockups',
      'Implement database changes',
      'Test new features',
      'Prepare presentation for stakeholders',
      'Research technical solutions',
      'Coordinate with external team',
      'Update project timeline',
      'Review code changes'
    ];
    
    for (int i = 0; i < actionCount; i++) {
      final action = possibleActions[random.nextInt(possibleActions.length)];
      final assignee = faker.person.name();
      items.add('- $action [@$assignee]');
    }
    
    return items.join('\n');
  }
  
  String _generateNoteContent() {
    final contentTypes = [
      () => _generateBulletPoints(),
      () => _generateParagraphContent(),
      () => _generateCodeSnippet(),
      () => _generateChecklistContent(),
    ];
    
    return contentTypes[random.nextInt(contentTypes.length)]();
  }
  
  String _generateBulletPoints() {
    final points = <String>[];
    final pointCount = 3 + random.nextInt(6);
    
    for (int i = 0; i < pointCount; i++) {
      points.add('• ${faker.lorem.sentence()}');
    }
    
    return points.join('\n');
  }
  
  String _generateParagraphContent() {
    return faker.lorem.sentences(3 + random.nextInt(4)).join(' ');
  }
  
  String _generateCodeSnippet() {
    final codeSnippets = [
      '''```dart
class Example {
  final String name;
  final int value;
  
  Example(this.name, this.value);
}
```''',
      '''```javascript
function processData(data) {
  return data.map(item => ({
    ...item,
    processed: true
  }));
}
```''',
      '''```sql
SELECT * FROM users 
WHERE created_at > '2024-01-01' 
ORDER BY last_login DESC;
```''',
    ];
    
    return codeSnippets[random.nextInt(codeSnippets.length)];
  }
  
  String _generateChecklistContent() {
    final tasks = <String>[];
    final taskCount = 3 + random.nextInt(5);
    
    for (int i = 0; i < taskCount; i++) {
      final isDone = random.nextDouble() < 0.3;
      final checkbox = isDone ? '[x]' : '[ ]';
      tasks.add('$checkbox ${faker.lorem.sentence()}');
    }
    
    return tasks.join('\n');
  }
  
  String _generateUserMessage(String topic, bool isFirst) {
    if (isFirst) {
      final starters = [
        'Can you help me with $topic?',
        'I have a question about $topic.',
        'I need assistance with $topic.',
        'Could you explain $topic to me?',
      ];
      return starters[random.nextInt(starters.length)];
    } else {
      final followUps = [
        'That makes sense. Can you give me more details?',
        'Thanks! How would I implement this in practice?',
        'What are the best practices for this?',
        'Are there any common pitfalls I should avoid?',
        'Can you show me an example?',
      ];
      return followUps[random.nextInt(followUps.length)];
    }
  }
  
  String _generateAssistantMessage(String topic) {
    final responses = [
      'I\'d be happy to help you with that. Let me break this down for you step by step.',
      'Great question! Here\'s what I recommend based on best practices.',
      'That\'s a common scenario. Here are a few approaches you can consider.',
      'I can definitely help with that. Let me provide some detailed guidance.',
      'This is an interesting challenge. Here\'s how I would approach it.',
    ];
    
    final response = responses[random.nextInt(responses.length)];
    final details = faker.lorem.sentences(2 + random.nextInt(3)).join(' ');
    
    return '$response\n\n$details';
  }
  
  String _getRandomSystemPrompt() {
    final prompts = [
      'You are a helpful AI assistant specializing in software development.',
      'You are an expert in Flutter and mobile app development.',
      'You are a technical advisor focused on best practices and clean code.',
      'You are a knowledgeable assistant for database design and architecture.',
      'You are a helpful AI assistant with expertise in UI/UX design.',
    ];
    
    return prompts[random.nextInt(prompts.length)];
  }
  
  Future<void> clearAllData() async {
    await db.delete(db.chatMessages).go();
    await db.delete(db.chatConversations).go();
    await db.delete(db.notes).go();
    await db.delete(db.meetings).go();
  }
  
  Future<Map<String, int>> getDataCounts() async {
    final meetingCount = await db.meetings.count().getSingle();
    final noteCount = await db.notes.count().getSingle();
    final conversationCount = await db.chatConversations.count().getSingle();
    final messageCount = await db.chatMessages.count().getSingle();
    
    return {
      'meetings': meetingCount,
      'notes': noteCount,
      'conversations': conversationCount,
      'messages': messageCount,
    };
  }
}