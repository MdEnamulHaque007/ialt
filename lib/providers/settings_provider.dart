import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider extends ChangeNotifier {
  String _companyName = 'Loading...';
  String _email = '';

  String get companyName => _companyName;
  String get email => _email;

  final DocumentReference _doc = FirebaseFirestore.instance.collection('settings').doc('company_info');

  Future<void> loadSettings() async {
    try {
      final docSnapshot = await _doc.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _companyName = data['company_name'] ?? 'Company Name';
        _email = data['email'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load settings provider: $e');
      _companyName = 'Company Name';
      notifyListeners();
    }
  }

  void updateSettingsLocally({required String companyName, required String email}) {
    _companyName = companyName;
    _email = email;
    notifyListeners();
  }
}
