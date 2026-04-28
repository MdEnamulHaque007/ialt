import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_order.dart';

class PurchaseOrderService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'purchase_order',
  );

  // সব PO এর Stream (realtime)
  Stream<List<PurchaseOrder>> streamAll() {
    return _col.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PurchaseOrder.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // সব PO একবার get করুন
  Future<List<PurchaseOrder>> getAll() async {
    try {
      final snapshot = await _col.get();
      return snapshot.docs.map((doc) {
        return PurchaseOrder.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw Exception('PurchaseOrder getAll failed: $e');
    }
  }

  // নতুন PO যোগ করুন
  Future<void> add(PurchaseOrder po) async {
    try {
      await _col.add(po.toFirestore());
    } catch (e) {
      throw Exception('PurchaseOrder add failed: $e');
    }
  }

  // PO update করুন
  Future<void> update(PurchaseOrder po) async {
    try {
      await _col.doc(po.id).update(po.toFirestore());
    } catch (e) {
      throw Exception('PurchaseOrder update failed: $e');
    }
  }

  // PO delete করুন
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw Exception('PurchaseOrder delete failed: $e');
    }
  }

  // Statistics নিন
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _col.get();
      final list = snapshot.docs.map((doc) {
        return PurchaseOrder.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      final totalValue = list.fold<double>(
        0,
        (total, po) => total + po.totalValue,
      );
      final totalQty = list.fold<int>(
        0,
        (total, po) => total + po.totalQuantity,
      );

      return {
        'count': list.length,
        'totalValue': totalValue,
        'totalQty': totalQty,
      };
    } catch (e) {
      return {'count': 0, 'totalValue': 0.0, 'totalQty': 0};
    }
  }

  // Master LC tags নিন (dropdown এর জন্য)
  Future<List<String>> getMasterLcTags() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('master_lc')
          .orderBy('tag_no')
          .get();
      return snapshot.docs
          .map((doc) => doc['tag_no']?.toString() ?? '')
          .where((tag) => tag.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
