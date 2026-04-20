import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue.dart';

class IssueService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'issue',
  );

  // সব Issue এর Stream (realtime)
  Stream<List<Issue>> streamAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Issue.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // নতুন Issue যোগ করুন
  Future<void> add(Issue issue) async {
    try {
      await _col.add(issue.toFirestore());
    } catch (e) {
      throw Exception('Issue add failed: $e');
    }
  }

  // Issue update করুন
  Future<void> update(Issue issue) async {
    try {
      await _col.doc(issue.id).update(issue.toFirestore());
    } catch (e) {
      throw Exception('Issue update failed: $e');
    }
  }

  // Issue delete করুন
  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw Exception('Issue delete failed: $e');
    }
  }

  // Statistics নিন
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _col.get();
      final list = snapshot.docs.map((doc) {
        return Issue.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      final totalQty = list.fold<int>(0, (sum, i) => sum + i.quantity);
      final fgCount = list.where((i) => i.criteria == 'FG').length;
      final bGradeCount = list.where((i) => i.criteria == 'B-Grade').length;

      return {
        'count': list.length,
        'totalQty': totalQty,
        'fgCount': fgCount,
        'bGradeCount': bGradeCount,
      };
    } catch (e) {
      return {'count': 0, 'totalQty': 0, 'fgCount': 0, 'bGradeCount': 0};
    }
  }
}
