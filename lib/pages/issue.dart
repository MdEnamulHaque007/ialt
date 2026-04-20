import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/issue.dart' as issue_model;
import '../services/issue_service.dart';

class IssuePage extends StatefulWidget {
  const IssuePage({super.key});

  @override
  State<IssuePage> createState() => _IssuePageState();
}

class _IssuePageState extends State<IssuePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data
  List<Map<String, dynamic>> _issues = [];
  List<Map<String, dynamic>> _productions = [];
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _isLoading = true;

  // Form state
  DateTime? _selectedDate;
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedPoNo;
  String? _selectedArticle;
  String? _selectedColor;
  String? _selectedCriteria;
  String? _editingId;

  // Search & Filter
  String _searchQuery = '';
  String _filterCriteria = 'All';
  DateTimeRange? _dateRange;

  // Pagination
  int _rowsPerPage = 15;
  int _currentPage = 0;

  // Animation
  late AnimationController _animationController;

  // Stats
  double _totalIssuedQty = 0;
  double _totalIssuedValue = 0;

  final List<String> _criteriaOptions = ['All', 'FG', 'B-Grade'];

  final IssueService _service = IssueService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voucherController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadIssues(),
      _loadProductions(),
      _loadPurchaseOrders(),
    ]);
    _calculateStats();
    setState(() => _isLoading = false);
  }

  Future<void> _loadIssues() async {
    try {
      final snapshot = await _firestore
          .collection('issue')
          .orderBy('date', descending: true)
          .get();

      _issues = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _showSnackBar('Error loading issues: $e', isError: true);
    }
  }

  Future<void> _loadProductions() async {
    try {
      final snapshot = await _firestore.collection('Production').get();
      _productions = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Production load error: $e');
    }
  }

  Future<void> _loadPurchaseOrders() async {
    try {
      final snapshot = await _firestore.collection('purchase_order').get();
      _purchaseOrders = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('PO load error: $e');
    }
  }

  void _calculateStats() {
    _totalIssuedQty = _filteredIssues.fold<double>(
      0,
      (sum, issue) => sum + ((issue['quantity'] as num?)?.toDouble() ?? 0),
    );
    _totalIssuedValue = _filteredIssues.fold<double>(
      0,
      (sum, issue) => sum + (_getTotalValue(issue)),
    );
  }

  List<Map<String, dynamic>> get _filteredIssues {
    return _issues.where((issue) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final voucherMatch =
            issue['voucherNo']?.toString().toLowerCase().contains(
              searchLower,
            ) ??
            false;
        final poMatch =
            issue['poNo']?.toString().toLowerCase().contains(searchLower) ??
            false;
        final articleMatch =
            issue['articleNo']?.toString().toLowerCase().contains(
              searchLower,
            ) ??
            false;
        if (!voucherMatch && !poMatch && !articleMatch) return false;
      }

      // Criteria filter
      if (_filterCriteria != 'All' && issue['criteria'] != _filterCriteria)
        return false;

      // Date range filter
      if (_dateRange != null) {
        final issueDate = (issue['date'] as Timestamp?)?.toDate();
        if (issueDate != null) {
          if (issueDate.isBefore(_dateRange!.start) ||
              issueDate.isAfter(_dateRange!.end)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  double _getUnitPrice(String poNo, String articleNo, String color) {
    for (final po in _purchaseOrders) {
      if (po['poNo']?.toString() == poNo) {
        final lines = po['lines'] as List? ?? [];
        for (final line in lines) {
          if (line is Map<String, dynamic>) {
            final lineArticle = line['article']?.toString() ?? '';
            if (lineArticle == articleNo &&
                line['color']?.toString() == color) {
              return (line['unitPrice'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
      }
    }
    return 0.0;
  }

  double _getTotalValue(Map<String, dynamic> issue) {
    final qty = (issue['quantity'] as num?)?.toDouble() ?? 0;
    final unitPrice = _getUnitPrice(
      issue['poNo']?.toString() ?? '',
      issue['articleNo']?.toString() ?? '',
      issue['color']?.toString() ?? '',
    );
    return qty * unitPrice;
  }

  double _getRemainingProductionQty(
    String poNo,
    String articleNo,
    String color,
  ) {
    double prodQty = 0.0;
    double issuedQty = 0.0;

    // Sum production qty
    for (final prod in _productions) {
      if (prod['poNo']?.toString() == poNo &&
          prod['articleNo']?.toString() == articleNo &&
          prod['color']?.toString() == color) {
        prodQty += (prod['qty'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Sum existing issue qty (excluding current if editing)
    for (final issue in _issues) {
      if (issue['poNo']?.toString() == poNo &&
          issue['articleNo']?.toString() == articleNo &&
          issue['color']?.toString() == color &&
          issue['id'] != _editingId) {
        issuedQty += (issue['quantity'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return prodQty - issuedQty;
  }

  List<String> get _poNumbers {
    return _productions
        .map((prod) => prod['poNo']?.toString() ?? '')
        .where((po) => po.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _articlesForSelectedPo {
    if (_selectedPoNo == null) return [];
    return _productions
        .where((p) => p['poNo']?.toString() == _selectedPoNo)
        .map((p) => p['articleNo']?.toString() ?? '')
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _colorsForSelectedPoArticle {
    if (_selectedPoNo == null || _selectedArticle == null) return [];
    return _productions
        .where(
          (p) =>
              p['poNo']?.toString() == _selectedPoNo &&
              p['articleNo']?.toString() == _selectedArticle,
        )
        .map((p) => p['color']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _saveIssue() async {
    if (!_isFormValid) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      _showSnackBar('Invalid quantity', isError: true);
      return;
    }

    // Check remaining production qty
    final remaining = _getRemainingProductionQty(
      _selectedPoNo!,
      _selectedArticle!,
      _selectedColor!,
    );
    if (qty > remaining) {
      _showSnackBar(
        'Issue quantity ($qty) exceeds remaining production quantity ($remaining). Entry blocked!',
        isError: true,
      );
      return;
    }

    final issue = issue_model.Issue(
      id: _editingId ?? '',
      voucherNo: _voucherController.text.trim(),
      poNo: _selectedPoNo ?? '',
      articleNo: _selectedArticle ?? '',
      color: _selectedColor ?? '',
      quantity: qty.toInt(),
      criteria: _selectedCriteria ?? 'FG',
      date: _selectedDate!.toIso8601String(),
      createdAt: _editingId == null ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    try {
      if (_editingId == null) {
        await _service.add(issue);
        _showSnackBar('Issue added successfully');
      } else {
        await _service.update(issue);
        _showSnackBar('Issue updated successfully');
      }

      _resetForm();
      await _loadData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteIssue(String id) async {
    try {
      await _service.delete(id);
      _showSnackBar('Issue deleted successfully');
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _resetForm() {
    _selectedDate = null;
    _voucherController.clear();
    _quantityController.clear();
    _selectedPoNo = null;
    _selectedArticle = null;
    _selectedColor = null;
    _selectedCriteria = null;
    _editingId = null;
  }

  bool get _isFormValid {
    return _selectedDate != null &&
        _voucherController.text.trim().isNotEmpty &&
        _selectedPoNo != null &&
        _selectedArticle != null &&
        _selectedColor != null &&
        _quantityController.text.trim().isNotEmpty &&
        _selectedCriteria != null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return '';
  }

  void _showFormDialog([Map<String, dynamic>? issue]) async {
    _resetForm();

    if (issue != null) {
      _selectedDate = (issue['date'] as Timestamp?)?.toDate();
      _voucherController.text = issue['voucherNo']?.toString() ?? '';
      _quantityController.text = issue['quantity']?.toString() ?? '';
      _selectedPoNo = issue['poNo']?.toString();
      _selectedArticle = issue['articleNo']?.toString();
      _selectedColor = issue['color']?.toString();
      _selectedCriteria = issue['criteria']?.toString();
      _editingId = issue['id'];
    }

    final isEdit = _editingId != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            constraints: const BoxConstraints(
              maxHeight: 600, // Maximum height fixed
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEdit
                          ? [Colors.orange.shade700, Colors.orange.shade500]
                          : [Colors.indigo.shade700, Colors.indigo.shade500],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit_note : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Issue' : 'New Issue',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Form Body with SingleChildScrollView
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Date Picker
                        _buildDatePicker(setDialogState),
                        const SizedBox(height: 14),

                        // Voucher No
                        _buildTextField(
                          controller: _voucherController,
                          label: 'Voucher Number *',
                          hint: 'Enter voucher number',
                          icon: Icons.receipt,
                        ),
                        const SizedBox(height: 14),

                        // PO Dropdown
                        _buildPoDropdown(setDialogState),
                        const SizedBox(height: 14),

                        // Article Dropdown
                        _buildArticleDropdown(setDialogState),
                        const SizedBox(height: 14),

                        // Color Dropdown
                        _buildColorDropdown(setDialogState),
                        const SizedBox(height: 14),

                        // Quantity Field
                        _buildTextField(
                          controller: _quantityController,
                          label: 'Quantity *',
                          hint: 'Enter issue quantity',
                          icon: Icons.production_quantity_limits,
                          isNumber: true,
                        ),
                        const SizedBox(height: 14),

                        // Criteria Dropdown
                        _buildCriteriaDropdown(setDialogState),

                        // Remaining Qty Info
                        if (_selectedPoNo != null &&
                            _selectedArticle != null &&
                            _selectedColor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Remaining available: ${_getRemainingProductionQty(_selectedPoNo!, _selectedArticle!, _selectedColor!).toStringAsFixed(0)} units',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveIssue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEdit
                                ? Colors.orange
                                : Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(isEdit ? 'Update' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for building form fields (more compact)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.indigo.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true, // Makes the field more compact
        labelStyle: const TextStyle(fontSize: 13),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
    );
  }

  // Updated Date Picker (more compact)
  Widget _buildDatePicker(StateSetter setDialogState) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.indigo),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setDialogState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedDate != null ? Colors.indigo : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: _selectedDate != null
                  ? Colors.indigo
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                    : 'Select Issue Date *',
                style: TextStyle(
                  color: _selectedDate != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                  fontWeight: _selectedDate != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
            if (_selectedDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 10, color: Colors.indigo),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Updated PO Dropdown (more compact)
  Widget _buildPoDropdown(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPoNo != null ? Colors.indigo : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            'Select PO Number *',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          value: _selectedPoNo,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Select PO Number *', style: TextStyle(fontSize: 13)),
            ),
            ..._poNumbers.map(
              (po) => DropdownMenuItem(
                value: po,
                child: Text(po, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: (value) {
            setDialogState(() {
              _selectedPoNo = value;
              _selectedArticle = null;
              _selectedColor = null;
            });
          },
        ),
      ),
    );
  }

  // Updated Article Dropdown
  Widget _buildArticleDropdown(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedArticle != null
              ? Colors.indigo
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            'Select Article *',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          value: _selectedArticle,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Select Article *', style: TextStyle(fontSize: 13)),
            ),
            if (_selectedPoNo != null)
              ..._articlesForSelectedPo.map(
                (article) => DropdownMenuItem(
                  value: article,
                  child: Text(article, style: const TextStyle(fontSize: 13)),
                ),
              ),
          ],
          onChanged: _selectedPoNo != null
              ? (value) {
                  setDialogState(() {
                    _selectedArticle = value;
                    _selectedColor = null;
                  });
                }
              : null,
        ),
      ),
    );
  }

  // Updated Color Dropdown
  Widget _buildColorDropdown(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedColor != null ? Colors.indigo : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            'Select Color *',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          value: _selectedColor,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Select Color *', style: TextStyle(fontSize: 13)),
            ),
            if (_selectedPoNo != null && _selectedArticle != null)
              ..._colorsForSelectedPoArticle.map(
                (color) => DropdownMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getColorFromName(color),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(color, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
          onChanged: (_selectedPoNo != null && _selectedArticle != null)
              ? (value) => setDialogState(() => _selectedColor = value)
              : null,
        ),
      ),
    );
  }

  // Updated Criteria Dropdown
  Widget _buildCriteriaDropdown(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedCriteria != null
              ? Colors.indigo
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            'Select Criteria *',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          value: _selectedCriteria,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Select Criteria *', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'FG',
              child: Text(
                'FG - Finished Goods',
                style: TextStyle(fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: 'B-Grade',
              child: Text('B-Grade', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (value) => setDialogState(() => _selectedCriteria = value),
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Black': Colors.black,
      'White': Colors.white,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
      'Pink': Colors.pink,
      'Brown': Colors.brown,
      'Grey': Colors.grey,
    };
    return colorMap[colorName] ?? Colors.grey.shade400;
  }

  void _showDeleteDialog(String id, String voucherNo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Issue?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Voucher $voucherNo will be permanently deleted.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteIssue(id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.indigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _currentPage = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIssues;
    final totalItems = filtered.length;

    // Update stats
    _totalIssuedQty = filtered.fold<double>(
      0,
      (sum, issue) => sum + ((issue['quantity'] as num?)?.toDouble() ?? 0),
    );
    _totalIssuedValue = filtered.fold<double>(
      0,
      (sum, issue) => sum + _getTotalValue(issue),
    );

    final maxPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    if (_currentPage >= maxPages) _currentPage = maxPages - 1;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final paginated = filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Issue'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade700,
                            Colors.indigo.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issue Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Track all issued items from production',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Stats
                    _buildStatChip(
                      label: 'Total Issues',
                      value: '${filtered.length}',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      label: 'Total Qty',
                      value: NumberFormat('#,###').format(_totalIssuedQty),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      label: 'Total Value',
                      value:
                          '\$${NumberFormat('#,###').format(_totalIssuedValue)}',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by Voucher, PO, Article...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _currentPage = 0;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Criteria Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterCriteria,
                          icon: const Icon(Icons.filter_list),
                          items: _criteriaOptions.map((criteria) {
                            return DropdownMenuItem(
                              value: criteria,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: criteria == 'FG'
                                          ? Colors.green
                                          : criteria == 'B-Grade'
                                          ? Colors.orange
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(criteria),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterCriteria = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date Range Filter
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dateRange != null
                              ? Colors.indigo
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.date_range,
                          color: _dateRange != null
                              ? Colors.indigo
                              : Colors.grey.shade600,
                        ),
                        onPressed: _showDateRangePicker,
                        tooltip: 'Filter by date range',
                      ),
                    ),
                    if (_dateRange != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _dateRange = null;
                              _currentPage = 0;
                            });
                          },
                          tooltip: 'Clear date filter',
                        ),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _issues.isEmpty
                ? _buildEmptyState()
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching issues found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowHeight: 48,
                              dataRowHeight: 56,
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                                verticalInside: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => Colors.indigo.shade50,
                              ),
                              columns: [
                                _buildDataColumn('SL', 50, numeric: true),
                                _buildDataColumn('Date', 110),
                                _buildDataColumn('Voucher No', 130),
                                _buildDataColumn('PO No', 120),
                                _buildDataColumn('Article', 150),
                                _buildDataColumn('Color', 100),
                                _buildDataColumn('Qty', 100, numeric: true),
                                _buildDataColumn(
                                  'Unit Price',
                                  120,
                                  numeric: true,
                                ),
                                _buildDataColumn(
                                  'Total Value',
                                  130,
                                  numeric: true,
                                ),
                                _buildDataColumn('Criteria', 100),
                                _buildDataColumn('Actions', 100),
                              ],
                              rows: paginated.asMap().entries.map((entry) {
                                final idx = startIndex + entry.key;
                                final issue = entry.value;
                                final unitPrice = _getUnitPrice(
                                  issue['poNo']?.toString() ?? '',
                                  issue['articleNo']?.toString() ?? '',
                                  issue['color']?.toString() ?? '',
                                );
                                final qty =
                                    (issue['quantity'] as num?)?.toDouble() ??
                                    0;
                                final totalValue = unitPrice * qty;

                                return DataRow(
                                  cells: [
                                    DataCell(Text('${idx + 1}')),
                                    DataCell(Text(_formatDate(issue['date']))),
                                    DataCell(
                                      Text(
                                        issue['voucherNo'] ?? '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(issue['poNo'] ?? '—')),
                                    DataCell(Text(issue['articleNo'] ?? '—')),
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getColorFromName(
                                                issue['color'] ?? '',
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(issue['color'] ?? '—'),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(NumberFormat('#,###').format(qty)),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${NumberFormat('#,###.##').format(unitPrice)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${NumberFormat('#,###.##').format(totalValue)}',
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: issue['criteria'] == 'FG'
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          issue['criteria'] ?? '—',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: issue['criteria'] == 'FG'
                                                ? Colors.green.shade700
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 18,
                                            ),
                                            color: Colors.indigo,
                                            onPressed: () =>
                                                _showFormDialog(issue),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                            ),
                                            color: Colors.red,
                                            onPressed: () => _showDeleteDialog(
                                              issue['id'],
                                              issue['voucherNo'] ?? '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Pagination
                      if (totalItems > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('Rows per page:'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _rowsPerPage,
                                items: [10, 15, 25, 50, 100]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text('$v'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _rowsPerPage = v!;
                                  _currentPage = 0;
                                }),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                '${startIndex + 1}-$endIndex of $totalItems',
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: endIndex < totalItems
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(
    String label,
    double width, {
    bool numeric = false,
  }) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      numeric: numeric,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Issues Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to add your first issue',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
