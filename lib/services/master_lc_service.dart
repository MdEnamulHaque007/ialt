import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_lc.dart';
import 'activity_log_service.dart';

class MasterLCService {
  final ActivityLogService _logger = ActivityLogService();
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'master_lc',
  );

  // সব MasterLC এর Stream (realtime)
  Stream<List<MasterLC>> streamAll() {
    return _col.orderBy('sl_no').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MasterLC.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // পরের sl_no নিন
  Future<int> getNextSlNo() async {
    try {
      final snapshot = await _col
          .orderBy('sl_no', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return 1;
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return ((data['sl_no'] as num?)?.toInt() ?? 0) + 1;
    } catch (e) {
      return 1;
    }
  }

  // নতুন MasterLC যোগ করুন
  Future<void> add(MasterLC lc) async {
    try {
      await _col.add(lc.toFirestore());
      await _logger.logCreate(
        module: 'MasterLC',
        details: 'Added Tag: ${lc.tagNo}, Project: ${lc.project}',
      );
    } catch (e) {
      throw Exception('MasterLC add failed: $e');
    }
  }

  // MasterLC update করুন
  Future<void> update(MasterLC lc) async {
    try {
      await _col.doc(lc.id).update(lc.toFirestore());
      await _logger.logUpdate(
        module: 'MasterLC',
        details: 'Updated Tag: ${lc.tagNo}, Project: ${lc.project}',
      );
    } catch (e) {
      throw Exception('MasterLC update failed: $e');
    }
  }

  // MasterLC delete করুন
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
      await _logger.logDelete(module: 'MasterLC', details: 'Deleted ID: $id');
    } catch (e) {
      throw Exception('MasterLC delete failed: $e');
    }
  }

  // Statistics নিন
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _col.get();
      final list = snapshot.docs.map((doc) {
        return MasterLC.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
      final count = list.length;
      final totalValue = list.fold<double>(
        0,
        (total, lc) => total + lc.masterLcValue,
      );
      final totalQty = list.fold<double>(
        0,
        (total, lc) => total + lc.masterLcQty,
      );
      return {'count': count, 'totalValue': totalValue, 'totalQty': totalQty};
    } catch (e) {
      throw Exception('Stats failed: $e');
    }
  }
}
