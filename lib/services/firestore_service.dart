import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic get collection
  Future<List<Map<String, dynamic>>> getCollection(
    String collectionName, {
    Query? query,
  }) async {
    try {
      Query q = _firestore.collection(collectionName);
      if (query != null) q = query;

      final snapshot = await q.get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Firestore get error in $collectionName: $e');
      rethrow;
    }
  }

  // Stream collection
  Stream<List<Map<String, dynamic>>> streamCollection(String collectionName) {
    return _firestore
        .collection(collectionName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // Add document
  Future<String> addDocument(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final ref = await _firestore.collection(collectionName).add(data);
      return ref.id;
    } catch (e) {
      debugPrint('Firestore add error in $collectionName: $e');
      rethrow;
    }
  }

  // Update document
  Future<void> updateDocument(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(docId).update(data);
    } catch (e) {
      debugPrint('Firestore update error in $collectionName/$docId: $e');
      rethrow;
    }
  }

  // Delete document
  Future<void> deleteDocument(String collectionName, String docId) async {
    try {
      await _firestore.collection(collectionName).doc(docId).delete();
    } catch (e) {
      debugPrint('Firestore delete error in $collectionName/$docId: $e');
      rethrow;
    }
  }

  // Convenience methods
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async =>
      await getCollection(AppConstants.colPurchaseOrder);
  Future<List<Map<String, dynamic>>> getProductions() async =>
      await getCollection(AppConstants.colProduction);
  Future<List<Map<String, dynamic>>> getIssues() async =>
      await getCollection(AppConstants.colIssue);
}
