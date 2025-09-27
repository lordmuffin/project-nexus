// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MeetingsTable extends Meetings with TableInfo<$MeetingsTable, Meeting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptMeta =
      const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionItemsMeta =
      const VerificationMeta('actionItems');
  @override
  late final GeneratedColumn<String> actionItems = GeneratedColumn<String>(
      'action_items', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        audioPath,
        transcript,
        summary,
        actionItems,
        startTime,
        endTime,
        duration,
        tags,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meetings';
  @override
  VerificationContext validateIntegrity(Insertable<Meeting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('transcript')) {
      context.handle(
          _transcriptMeta,
          transcript.isAcceptableOrUnknown(
              data['transcript']!, _transcriptMeta));
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('action_items')) {
      context.handle(
          _actionItemsMeta,
          actionItems.isAcceptableOrUnknown(
              data['action_items']!, _actionItemsMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meeting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meeting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript']),
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary']),
      actionItems: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_items']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MeetingsTable createAlias(String alias) {
    return $MeetingsTable(attachedDatabase, alias);
  }
}

class Meeting extends DataClass implements Insertable<Meeting> {
  final int id;
  final String title;
  final String? audioPath;
  final String? transcript;
  final String? summary;
  final String? actionItems;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Meeting(
      {required this.id,
      required this.title,
      this.audioPath,
      this.transcript,
      this.summary,
      this.actionItems,
      required this.startTime,
      this.endTime,
      this.duration,
      this.tags,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || actionItems != null) {
      map['action_items'] = Variable<String>(actionItems);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MeetingsCompanion toCompanion(bool nullToAbsent) {
    return MeetingsCompanion(
      id: Value(id),
      title: Value(title),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      actionItems: actionItems == null && nullToAbsent
          ? const Value.absent()
          : Value(actionItems),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Meeting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meeting(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      summary: serializer.fromJson<String?>(json['summary']),
      actionItems: serializer.fromJson<String?>(json['actionItems']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      duration: serializer.fromJson<int?>(json['duration']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'audioPath': serializer.toJson<String?>(audioPath),
      'transcript': serializer.toJson<String?>(transcript),
      'summary': serializer.toJson<String?>(summary),
      'actionItems': serializer.toJson<String?>(actionItems),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'duration': serializer.toJson<int?>(duration),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Meeting copyWith(
          {int? id,
          String? title,
          Value<String?> audioPath = const Value.absent(),
          Value<String?> transcript = const Value.absent(),
          Value<String?> summary = const Value.absent(),
          Value<String?> actionItems = const Value.absent(),
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Meeting(
        id: id ?? this.id,
        title: title ?? this.title,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        transcript: transcript.present ? transcript.value : this.transcript,
        summary: summary.present ? summary.value : this.summary,
        actionItems: actionItems.present ? actionItems.value : this.actionItems,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        duration: duration.present ? duration.value : this.duration,
        tags: tags.present ? tags.value : this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Meeting copyWithCompanion(MeetingsCompanion data) {
    return Meeting(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
      summary: data.summary.present ? data.summary.value : this.summary,
      actionItems:
          data.actionItems.present ? data.actionItems.value : this.actionItems,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      duration: data.duration.present ? data.duration.value : this.duration,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meeting(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('summary: $summary, ')
          ..write('actionItems: $actionItems, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('duration: $duration, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, audioPath, transcript, summary,
      actionItems, startTime, endTime, duration, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meeting &&
          other.id == this.id &&
          other.title == this.title &&
          other.audioPath == this.audioPath &&
          other.transcript == this.transcript &&
          other.summary == this.summary &&
          other.actionItems == this.actionItems &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.duration == this.duration &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MeetingsCompanion extends UpdateCompanion<Meeting> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> audioPath;
  final Value<String?> transcript;
  final Value<String?> summary;
  final Value<String?> actionItems;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int?> duration;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MeetingsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.summary = const Value.absent(),
    this.actionItems = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MeetingsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.audioPath = const Value.absent(),
    this.transcript = const Value.absent(),
    this.summary = const Value.absent(),
    this.actionItems = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : title = Value(title),
        startTime = Value(startTime);
  static Insertable<Meeting> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? audioPath,
    Expression<String>? transcript,
    Expression<String>? summary,
    Expression<String>? actionItems,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? duration,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (audioPath != null) 'audio_path': audioPath,
      if (transcript != null) 'transcript': transcript,
      if (summary != null) 'summary': summary,
      if (actionItems != null) 'action_items': actionItems,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (duration != null) 'duration': duration,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MeetingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? audioPath,
      Value<String?>? transcript,
      Value<String?>? summary,
      Value<String?>? actionItems,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int?>? duration,
      Value<String?>? tags,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MeetingsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      actionItems: actionItems ?? this.actionItems,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (actionItems.present) {
      map['action_items'] = Variable<String>(actionItems.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('audioPath: $audioPath, ')
          ..write('transcript: $transcript, ')
          ..write('summary: $summary, ')
          ..write('actionItems: $actionItems, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('duration: $duration, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<int> meetingId = GeneratedColumn<int>(
      'meeting_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES meetings (id)'));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        content,
        tags,
        meetingId,
        isPinned,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meeting_id']),
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String content;
  final String? tags;
  final int? meetingId;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note(
      {required this.id,
      required this.title,
      required this.content,
      this.tags,
      this.meetingId,
      required this.isPinned,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || meetingId != null) {
      map['meeting_id'] = Variable<int>(meetingId);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      meetingId: meetingId == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingId),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      tags: serializer.fromJson<String?>(json['tags']),
      meetingId: serializer.fromJson<int?>(json['meetingId']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'tags': serializer.toJson<String?>(tags),
      'meetingId': serializer.toJson<int?>(meetingId),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith(
          {int? id,
          String? title,
          String? content,
          Value<String?> tags = const Value.absent(),
          Value<int?> meetingId = const Value.absent(),
          bool? isPinned,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags.present ? tags.value : this.tags,
        meetingId: meetingId.present ? meetingId.value : this.meetingId,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      tags: data.tags.present ? data.tags.value : this.tags,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('meetingId: $meetingId, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, tags, meetingId, isPinned,
      isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.tags == this.tags &&
          other.meetingId == this.meetingId &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> tags;
  final Value<int?> meetingId;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.tags = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    this.tags = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : title = Value(title),
        content = Value(content);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? tags,
    Expression<int>? meetingId,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (meetingId != null) 'meeting_id': meetingId,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? content,
      Value<String?>? tags,
      Value<int?>? meetingId,
      Value<bool>? isPinned,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      meetingId: meetingId ?? this.meetingId,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<int>(meetingId.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('tags: $tags, ')
          ..write('meetingId: $meetingId, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, content, role, conversationId, metadata, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      conversationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}conversation_id'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int id;
  final String content;
  final String role;
  final int conversationId;
  final String? metadata;
  final DateTime createdAt;
  const ChatMessage(
      {required this.id,
      required this.content,
      required this.role,
      required this.conversationId,
      this.metadata,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['role'] = Variable<String>(role);
    map['conversation_id'] = Variable<int>(conversationId);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      content: Value(content),
      role: Value(role),
      conversationId: Value(conversationId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      role: serializer.fromJson<String>(json['role']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'role': serializer.toJson<String>(role),
      'conversationId': serializer.toJson<int>(conversationId),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessage copyWith(
          {int? id,
          String? content,
          String? role,
          int? conversationId,
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt}) =>
      ChatMessage(
        id: id ?? this.id,
        content: content ?? this.content,
        role: role ?? this.role,
        conversationId: conversationId ?? this.conversationId,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      role: data.role.present ? data.role.value : this.role,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('role: $role, ')
          ..write('conversationId: $conversationId, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, content, role, conversationId, metadata, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.content == this.content &&
          other.role == this.role &&
          other.conversationId == this.conversationId &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> id;
  final Value<String> content;
  final Value<String> role;
  final Value<int> conversationId;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.role = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required String role,
    required int conversationId,
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : content = Value(content),
        role = Value(role),
        conversationId = Value(conversationId);
  static Insertable<ChatMessage> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? role,
    Expression<int>? conversationId,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (role != null) 'role': role,
      if (conversationId != null) 'conversation_id': conversationId,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<int>? id,
      Value<String>? content,
      Value<String>? role,
      Value<int>? conversationId,
      Value<String?>? metadata,
      Value<DateTime>? createdAt}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      conversationId: conversationId ?? this.conversationId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('role: $role, ')
          ..write('conversationId: $conversationId, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ChatConversationsTable extends ChatConversations
    with TableInfo<$ChatConversationsTable, ChatConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemPromptMeta =
      const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
      'system_prompt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, systemPrompt, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_conversations';
  @override
  VerificationContext validateIntegrity(Insertable<ChatConversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
          _systemPromptMeta,
          systemPrompt.isAcceptableOrUnknown(
              data['system_prompt']!, _systemPromptMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatConversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      systemPrompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_prompt']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatConversationsTable createAlias(String alias) {
    return $ChatConversationsTable(attachedDatabase, alias);
  }
}

class ChatConversation extends DataClass
    implements Insertable<ChatConversation> {
  final int id;
  final String? title;
  final String? systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatConversation(
      {required this.id,
      this.title,
      this.systemPrompt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || systemPrompt != null) {
      map['system_prompt'] = Variable<String>(systemPrompt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatConversationsCompanion toCompanion(bool nullToAbsent) {
    return ChatConversationsCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      systemPrompt: systemPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPrompt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatConversation(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      systemPrompt: serializer.fromJson<String?>(json['systemPrompt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'systemPrompt': serializer.toJson<String?>(systemPrompt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatConversation copyWith(
          {int? id,
          Value<String?> title = const Value.absent(),
          Value<String?> systemPrompt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChatConversation(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        systemPrompt:
            systemPrompt.present ? systemPrompt.value : this.systemPrompt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChatConversation copyWithCompanion(ChatConversationsCompanion data) {
    return ChatConversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatConversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, systemPrompt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatConversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.systemPrompt == this.systemPrompt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatConversationsCompanion extends UpdateCompanion<ChatConversation> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String?> systemPrompt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChatConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChatConversationsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<ChatConversation> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? systemPrompt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChatConversationsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? title,
      Value<String?>? systemPrompt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ChatConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MeetingsTable meetings = $MeetingsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ChatConversationsTable chatConversations =
      $ChatConversationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [meetings, notes, chatMessages, chatConversations];
}

typedef $$MeetingsTableCreateCompanionBuilder = MeetingsCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> audioPath,
  Value<String?> transcript,
  Value<String?> summary,
  Value<String?> actionItems,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int?> duration,
  Value<String?> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MeetingsTableUpdateCompanionBuilder = MeetingsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> audioPath,
  Value<String?> transcript,
  Value<String?> summary,
  Value<String?> actionItems,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int?> duration,
  Value<String?> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$MeetingsTableReferences
    extends BaseReferences<_$AppDatabase, $MeetingsTable, Meeting> {
  $$MeetingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.notes,
          aliasName: $_aliasNameGenerator(db.meetings.id, db.notes.meetingId));

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager($_db, $_db.notes)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MeetingsTableFilterComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionItems => $composableBuilder(
      column: $table.actionItems, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> notesRefs(
      Expression<bool> Function($$NotesTableFilterComposer f) f) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.notes,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotesTableFilterComposer(
              $db: $db,
              $table: $db.notes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionItems => $composableBuilder(
      column: $table.actionItems, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MeetingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeetingsTable> {
  $$MeetingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(
      column: $table.transcript, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get actionItems => $composableBuilder(
      column: $table.actionItems, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> notesRefs<T extends Object>(
      Expression<T> Function($$NotesTableAnnotationComposer a) f) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.notes,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotesTableAnnotationComposer(
              $db: $db,
              $table: $db.notes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, $$MeetingsTableReferences),
    Meeting,
    PrefetchHooks Function({bool notesRefs})> {
  $$MeetingsTableTableManager(_$AppDatabase db, $MeetingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> actionItems = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MeetingsCompanion(
            id: id,
            title: title,
            audioPath: audioPath,
            transcript: transcript,
            summary: summary,
            actionItems: actionItems,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> audioPath = const Value.absent(),
            Value<String?> transcript = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> actionItems = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MeetingsCompanion.insert(
            id: id,
            title: title,
            audioPath: audioPath,
            transcript: transcript,
            summary: summary,
            actionItems: actionItems,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MeetingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({notesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notesRefs) db.notes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notesRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable, Note>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._notesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0).notesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MeetingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, $$MeetingsTableReferences),
    Meeting,
    PrefetchHooks Function({bool notesRefs})>;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String title,
  required String content,
  Value<String?> tags,
  Value<int?> meetingId,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<String?> tags,
  Value<int?> meetingId,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDatabase db) => db.meetings
      .createAlias($_aliasNameGenerator(db.notes.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager? get meetingId {
    final $_column = $_itemColumn<int>('meeting_id');
    if ($_column == null) return null;
    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, $$NotesTableReferences),
    Note,
    PrefetchHooks Function({bool meetingId})> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<int?> meetingId = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            title: title,
            content: content,
            tags: tags,
            meetingId: meetingId,
            isPinned: isPinned,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required String content,
            Value<String?> tags = const Value.absent(),
            Value<int?> meetingId = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NotesCompanion.insert(
            id: id,
            title: title,
            content: content,
            tags: tags,
            meetingId: meetingId,
            isPinned: isPinned,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$NotesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable: $$NotesTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$NotesTableReferences._meetingIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, $$NotesTableReferences),
    Note,
    PrefetchHooks Function({bool meetingId})>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  required String content,
  required String role,
  required int conversationId,
  Value<String?> metadata,
  Value<DateTime> createdAt,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  Value<String> content,
  Value<String> role,
  Value<int> conversationId,
  Value<String?> metadata,
  Value<DateTime> createdAt,
});

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get conversationId => $composableBuilder(
      column: $table.conversationId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int> conversationId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            content: content,
            role: role,
            conversationId: conversationId,
            metadata: metadata,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
            required String role,
            required int conversationId,
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            content: content,
            role: role,
            conversationId: conversationId,
            metadata: metadata,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()>;
typedef $$ChatConversationsTableCreateCompanionBuilder
    = ChatConversationsCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String?> systemPrompt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ChatConversationsTableUpdateCompanionBuilder
    = ChatConversationsCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String?> systemPrompt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ChatConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChatConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChatConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatConversationsTable,
    ChatConversation,
    $$ChatConversationsTableFilterComposer,
    $$ChatConversationsTableOrderingComposer,
    $$ChatConversationsTableAnnotationComposer,
    $$ChatConversationsTableCreateCompanionBuilder,
    $$ChatConversationsTableUpdateCompanionBuilder,
    (
      ChatConversation,
      BaseReferences<_$AppDatabase, $ChatConversationsTable, ChatConversation>
    ),
    ChatConversation,
    PrefetchHooks Function()> {
  $$ChatConversationsTableTableManager(
      _$AppDatabase db, $ChatConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatConversationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChatConversationsCompanion(
            id: id,
            title: title,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ChatConversationsCompanion.insert(
            id: id,
            title: title,
            systemPrompt: systemPrompt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatConversationsTable,
    ChatConversation,
    $$ChatConversationsTableFilterComposer,
    $$ChatConversationsTableOrderingComposer,
    $$ChatConversationsTableAnnotationComposer,
    $$ChatConversationsTableCreateCompanionBuilder,
    $$ChatConversationsTableUpdateCompanionBuilder,
    (
      ChatConversation,
      BaseReferences<_$AppDatabase, $ChatConversationsTable, ChatConversation>
    ),
    ChatConversation,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MeetingsTableTableManager get meetings =>
      $$MeetingsTableTableManager(_db, _db.meetings);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ChatConversationsTableTableManager get chatConversations =>
      $$ChatConversationsTableTableManager(_db, _db.chatConversations);
}
