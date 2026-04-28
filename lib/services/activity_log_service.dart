import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'activity_log',
  );

  // Auto serial number নিন
  Future<String> _getNextSlNo() async {
    try {
      final snapshot = await _col
          .orderBy('slNo', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return '1';
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final lastSl = int.tryParse(data['slNo']?.toString() ?? '0') ?? 0;
      return (lastSl + 1).toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Log entry যোগ করুন
  Future<void> log({
    required String action,
    required String details,
    required String module,
    String user = 'System',
  }) async {
    try {
      final slNo = await _getNextSlNo();
      final entry = ActivityLog(
        id: '',
        action: action,
        details: details,
        user: user,
        module: module,
        slNo: slNo,
        timestamp: DateTime.now(),
      );
      await _col.add(entry.toFirestore());
    } catch (e) {
      // Log failure should not break main operation
      debugPrint('ActivityLog error: $e');
    }
  }

  // Shortcut methods
  Future<void> logCreate({
    required String module,
    required String details,
    String user = 'System',
  }) => log(action: 'CREATE', details: details, module: module, user: user);

  Future<void> logUpdate({
    required String module,
    required String details,
    String user = 'System',
  }) => log(action: 'UPDATE', details: details, module: module, user: user);

  Future<void> logDelete({
    required String module,
    required String details,
    String user = 'System',
  }) => log(action: 'DELETE', details: details, module: module, user: user);

  // সব logs এর Stream
  Stream<List<ActivityLog>> streamAll() {
    return _col.orderBy('timestamp', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return ActivityLog.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}
