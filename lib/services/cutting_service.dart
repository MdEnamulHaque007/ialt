import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cutting.dart';

class CuttingService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'cutting',
  );

  Stream<List<Cutting>> streamAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => Cutting.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  Future<List<Cutting>> getAll() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map(
          (doc) =>
              Cutting.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Cutting?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Cutting.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<String> create(Cutting cutting) async {
    final ref = await _col.add(cutting.toFirestore());
    return ref.id;
  }

  Future<void> update(Cutting cutting) async {
    await _col.doc(cutting.id).update(cutting.toFirestore());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
