import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sewing.dart';

class SewingService {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'sewing',
  );

  Stream<List<Sewing>> streamAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => Sewing.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  Future<List<Sewing>> getAll() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map(
          (doc) =>
              Sewing.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Sewing?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Sewing.fromFirestore(id, doc.data() as Map<String, dynamic>);
  }

  Future<String> create(Sewing sewing) async {
    final ref = await _col.add(sewing.toFirestore());
    return ref.id;
  }

  Future<void> update(Sewing sewing) async {
    await _col.doc(sewing.id).update(sewing.toFirestore());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
