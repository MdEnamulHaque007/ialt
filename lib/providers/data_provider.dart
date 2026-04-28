import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unused firebase_service.dart

class DataProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Map<String, List<Map<String, dynamic>>> _collections = {};

  List<Map<String, dynamic>> get purchaseOrders =>
      _collections['Purchase Order'] ?? [];
  List<Map<String, dynamic>> get productions =>
      _collections['Production'] ?? [];
  List<Map<String, dynamic>> get issues => _collections['issue'] ?? [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DataProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadCollection('Purchase Order'),
      _loadCollection('Production'),
      _loadCollection('issue'),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadAllData();

  Future<void> _loadCollection(String collection) async {
    try {
      final snapshot = await firestore.collection(collection).get();
      final data = snapshot.docs.map((doc) {
        final item = Map<String, dynamic>.from(doc.data());
        item['id'] = doc.id;
        return item;
      }).toList();

      _collections[collection] = data;
    } catch (e) {
      debugPrint('Error loading $collection: $e');
    }
  }
}
