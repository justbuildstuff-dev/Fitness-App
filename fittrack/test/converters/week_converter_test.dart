import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/converters/week_converter.dart';
import 'package:fittrack/models/week.dart';

void main() {
  group('WeekConverter', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('fromFirestore - field parsing', () {
      test('parses all fields correctly from DocumentSnapshot', () async {
        final createdAt = DateTime(2026, 1, 10, 9, 0);
        final updatedAt = DateTime(2026, 1, 15, 12, 30);

        final docRef = fakeFirestore.collection('weeks').doc('week_1');
        await docRef.set({
          'name': 'Week 1',
          'order': 1,
          'notes': 'Foundation week',
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(updatedAt),
          'userId': 'user_abc',
          'programId': 'program_xyz',
        });

        final doc = await docRef.get();
        final week = WeekConverter.fromFirestore(doc);

        expect(week.id, 'week_1');
        expect(week.name, 'Week 1');
        expect(week.order, 1);
        expect(week.notes, 'Foundation week');
        expect(week.createdAt, createdAt);
        expect(week.updatedAt, updatedAt);
        expect(week.userId, 'user_abc');
        expect(week.programId, 'program_xyz');
      });

      test('uses default name based on order when name field is missing', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_no_name');
        await docRef.set({
          'order': 3,
          'userId': 'user_abc',
          'programId': 'program_xyz',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        });

        final doc = await docRef.get();
        final week = WeekConverter.fromFirestore(doc);

        expect(week.name, 'Week 3');
      });

      test('uses programId parameter as fallback when not stored in document', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_no_program');
        await docRef.set({
          'name': 'Week 5',
          'order': 5,
          'userId': 'user_abc',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
          // programId deliberately omitted
        });

        final doc = await docRef.get();
        final week = WeekConverter.fromFirestore(doc, programId: 'fallback_program');

        expect(week.programId, 'fallback_program');
      });

      test('notes field is null when not present', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_no_notes');
        await docRef.set({
          'name': 'Week 1',
          'order': 1,
          'userId': 'user_abc',
          'programId': 'program_xyz',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        });

        final doc = await docRef.get();
        final week = WeekConverter.fromFirestore(doc);

        expect(week.notes, isNull);
      });
    });

    group('fromFirestore - null Timestamp handling', () {
      test('handles null createdAt without crashing, falls back to DateTime', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_null_created');
        await docRef.set({
          'name': 'Week 2',
          'order': 2,
          'userId': 'user_abc',
          'programId': 'program_xyz',
          // createdAt deliberately omitted — simulates FieldValue.serverTimestamp() race condition
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 15)),
        });

        final doc = await docRef.get();

        expect(() => WeekConverter.fromFirestore(doc), returnsNormally);

        final week = WeekConverter.fromFirestore(doc);
        expect(week.createdAt, isA<DateTime>());
      });

      test('handles null updatedAt without crashing, falls back to DateTime', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_null_updated');
        await docRef.set({
          'name': 'Week 3',
          'order': 3,
          'userId': 'user_abc',
          'programId': 'program_xyz',
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
          // updatedAt deliberately omitted — simulates FieldValue.serverTimestamp() race condition
        });

        final doc = await docRef.get();

        expect(() => WeekConverter.fromFirestore(doc), returnsNormally);

        final week = WeekConverter.fromFirestore(doc);
        expect(week.updatedAt, isA<DateTime>());
      });

      test('handles both createdAt and updatedAt null without crashing', () async {
        final docRef = fakeFirestore.collection('weeks').doc('week_no_timestamps');
        await docRef.set({
          'name': 'Week 4',
          'order': 4,
          'userId': 'user_abc',
          'programId': 'program_xyz',
          // Both timestamps omitted — simulates newly created doc before server resolves timestamps
        });

        final doc = await docRef.get();

        expect(() => WeekConverter.fromFirestore(doc), returnsNormally);

        final week = WeekConverter.fromFirestore(doc);
        expect(week.createdAt, isA<DateTime>());
        expect(week.updatedAt, isA<DateTime>());
      });
    });

    group('toFirestore', () {
      test('serializes week fields to Firestore map', () {
        final createdAt = DateTime(2026, 1, 10, 9, 0);
        final updatedAt = DateTime(2026, 1, 15, 12, 30);
        final week = _buildWeek(
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final map = WeekConverter.toFirestore(week);

        expect(map['name'], 'Week 1');
        expect(map['order'], 1);
        expect(map['notes'], 'Foundation week');
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['updatedAt'], isA<Timestamp>());
        expect(map['userId'], 'user_abc');
        expect(map['programId'], 'program_xyz');
      });

      test('Timestamp values round-trip back to original dates', () {
        final createdAt = DateTime(2026, 1, 10, 9, 0);
        final updatedAt = DateTime(2026, 1, 15, 12, 30);
        final week = _buildWeek(createdAt: createdAt, updatedAt: updatedAt);

        final map = WeekConverter.toFirestore(week);

        expect((map['createdAt'] as Timestamp).toDate(), createdAt);
        expect((map['updatedAt'] as Timestamp).toDate(), updatedAt);
      });

      test('does not include document id in map', () {
        final week = _buildWeek();

        final map = WeekConverter.toFirestore(week);

        expect(map.containsKey('id'), isFalse);
      });

      test('null notes is preserved in map', () {
        final week = _buildWeek(notes: null);

        final map = WeekConverter.toFirestore(week);

        expect(map['notes'], isNull);
      });
    });

    group('round-trip', () {
      test('toFirestore then fromFirestore preserves all fields', () async {
        final createdAt = DateTime(2026, 1, 10, 9, 0);
        final updatedAt = DateTime(2026, 1, 15, 12, 30);
        final original = _buildWeek(createdAt: createdAt, updatedAt: updatedAt);

        final docRef = fakeFirestore.collection('weeks').doc(original.id);
        await docRef.set(WeekConverter.toFirestore(original));

        final doc = await docRef.get();
        final restored = WeekConverter.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.order, original.order);
        expect(restored.notes, original.notes);
        expect(restored.createdAt, createdAt);
        expect(restored.updatedAt, updatedAt);
        expect(restored.userId, original.userId);
        expect(restored.programId, original.programId);
      });
    });
  });
}

Week _buildWeek({
  DateTime? createdAt,
  DateTime? updatedAt,
  String? notes = 'Foundation week',
}) {
  return Week(
    id: 'week_1',
    name: 'Week 1',
    order: 1,
    notes: notes,
    createdAt: createdAt ?? DateTime(2026, 1, 10),
    updatedAt: updatedAt ?? DateTime(2026, 1, 10),
    userId: 'user_abc',
    programId: 'program_xyz',
  );
}
