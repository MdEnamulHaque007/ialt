import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/production.dart';

class ProductionService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'Production',
  );

  // সব Production এর Stream (realtime)
  Stream<List<Production>> streamAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Production.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  // নতুন Production যোগ করুন
  Future<void> add(Production production) async {
    try {
      await _col.add(production.toFirestore());
    } catch (e) {
      throw Exception('Production add failed: $e');
    }
  }

  // Production update করুন
  Future<void> update(Production production) async {
    try {
      await _col.doc(production.id).update(production.toFirestore());
    } catch (e) {
      throw Exception('Production update failed: $e');
    }
  }

  // Production delete করুন
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw Exception('Production delete failed: $e');
    }
  }

  // Statistics নিন
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _col.get();
      final list = snapshot.docs.map((doc) {
        return Production.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      final totalQty = list.fold<int>(0, (total, p) => total + p.qty);

      return {'count': list.length, 'totalQty': totalQty};
    } catch (e) {
      return {'count': 0, 'totalQty': 0};
    }
  }
}
