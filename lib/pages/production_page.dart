import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/production.dart';
import '../services/production_service.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data
  List<Map<String, dynamic>> _productions = [];
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _isLoading = true;

  // Form state
  DateTime? _selectedDate;
  String? _selectedPoNo;
  String? _selectedArticle;
  String? _selectedColor;
  final TextEditingController _qtyController = TextEditingController();
  String? _editingId;

  // Search & Filter
  String _searchQuery = '';
  String _filterPoNo = '';
  String _filterStatus = 'All';

  // Pagination
  int _rowsPerPage = 15;
  int _currentPage = 0;

  // Scroll controllers
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Status options
  final List<String> _statusOptions = ['All', 'Complete', 'Pending', 'Over'];

  final ProductionService _service = ProductionService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadProductions(), _loadPurchaseOrders()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadProductions() async {
    try {
      final snapshot = await _firestore
          .collection('Production')
          .orderBy('date', descending: true)
          .get();

      _productions = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _showSnackBar('Error loading productions: $e', isError: true);
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
      debugPrint('PO loading error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredProductions {
    return _productions.where((prod) {
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final poMatch =
            prod['poNo']?.toString().toLowerCase().contains(searchLower) ??
            false;
        final articleMatch =
            prod['article']?.toString().toLowerCase().contains(searchLower) ??
            false;
        final colorMatch =
            prod['color']?.toString().toLowerCase().contains(searchLower) ??
            false;
        if (!poMatch && !articleMatch && !colorMatch) return false;
      }
      if (_filterPoNo.isNotEmpty && prod['poNo'] != _filterPoNo) return false;
      if (_filterStatus != 'All') {
        final status = _getProductionStatus(prod);
        if (status != _filterStatus) return false;
      }
      return true;
    }).toList();
  }

  String _getProductionStatus(Map<String, dynamic> production) {
    final totalOrder = _getTotalOrderQuantity(production);
    final producedQty = (production['qty'] as num?)?.toDouble() ?? 0;
    if (producedQty >= totalOrder && totalOrder > 0) return 'Complete';
    if (producedQty > totalOrder && totalOrder > 0) return 'Over';
    return 'Pending';
  }

  double _getTotalOrderQuantity(Map<String, dynamic> production) {
    final poNo = production['poNo']?.toString() ?? '';
    final article = production['article']?.toString() ?? '';
    final color = production['color']?.toString() ?? '';

    for (final po in _purchaseOrders) {
      if (po['poNo']?.toString() == poNo) {
        final lines = po['lines'] as List? ?? [];
        for (final line in lines) {
          if (line is Map<String, dynamic>) {
            final lineArticle = line['article']?.toString() ?? '';
            if (lineArticle == article && line['color']?.toString() == color) {
              return (line['qty'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      }
    }
    return 0;
  }

  double _getUnitPrice(Map<String, dynamic> production) {
    final poNo = production['poNo']?.toString() ?? '';
    final article = production['article']?.toString() ?? '';
    final color = production['color']?.toString() ?? '';

    for (final po in _purchaseOrders) {
      if (po['poNo']?.toString() == poNo) {
        final lines = po['lines'] as List? ?? [];
        for (final line in lines) {
          if (line is Map<String, dynamic>) {
            final lineArticle = line['article']?.toString() ?? '';
            if (lineArticle == article && line['color']?.toString() == color) {
              return (line['unitPrice'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      }
    }
    return 0;
  }

  List<String> _getPoNumbers() {
    return _purchaseOrders
        .map((po) => po['poNo']?.toString() ?? '')
        .where((po) => po.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getArticlesForPo(String poNo) {
    final po = _purchaseOrders.firstWhere(
      (p) => p['poNo']?.toString() == poNo,
      orElse: () => {},
    );
    final lines = po['lines'] as List? ?? [];
    return lines
        .whereType<Map<String, dynamic>>()
        .map((line) => line['article']?.toString() ?? '')
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getColorsForPoAndArticle(String poNo, String article) {
    final po = _purchaseOrders.firstWhere(
      (p) => p['poNo']?.toString() == poNo,
      orElse: () => {},
    );
    final lines = po['lines'] as List? ?? [];
    return lines
        .whereType<Map<String, dynamic>>()
        .where((line) => line['article']?.toString() == article)
        .map((line) => line['color']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _saveProduction() async {
    if (!_isFormValid) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      _showSnackBar('Invalid quantity', isError: true);
      return;
    }

    try {
      final production = Production(
        id: _editingId ?? '',
        poNo: _selectedPoNo ?? '',
        articleNo: _selectedArticle ?? '',
        color: _selectedColor ?? '',
        qty: qty.toInt(),
        date: _selectedDate!.toIso8601String(),
        createdAt: _editingId == null ? DateTime.now() : null,
        updatedAt: _editingId != null ? DateTime.now() : null,
      );
      if (_editingId == null) {
        await _service.add(production);
        _showSnackBar('Production added successfully');
      } else {
        await _service.update(production);
        _showSnackBar('Production updated successfully');
      }

      _resetForm();
      await _loadProductions();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteProduction(String id) async {
    try {
      await _service.delete(id);
      _showSnackBar('Production deleted successfully');
      await _loadProductions();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _resetForm() {
    _selectedDate = null;
    _selectedPoNo = null;
    _selectedArticle = null;
    _selectedColor = null;
    _qtyController.clear();
    _editingId = null;
  }

  bool get _isFormValid {
    return _selectedDate != null &&
        _selectedPoNo != null &&
        _selectedArticle != null &&
        _selectedColor != null &&
        _qtyController.text.trim().isNotEmpty;
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
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    if (date is String && date.isNotEmpty) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    }
    return '';
  }

  void _showFormDialog([Map<String, dynamic>? production]) {
    _resetForm();
    if (production != null) {
      _selectedDate = (production['date'] as Timestamp?)?.toDate();
      _selectedPoNo = production['poNo']?.toString();
      _selectedArticle = production['article']?.toString();
      _selectedColor = production['color']?.toString();
      _qtyController.text = production['qty']?.toString() ?? '';
      _editingId = production['id'];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _editingId == null ? Icons.add : Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _editingId == null
                              ? 'Add Production'
                              : 'Edit Production',
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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDatePicker(setDialogState),
                        const SizedBox(height: 12),
                        _buildPoDropdown(setDialogState),
                        const SizedBox(height: 12),
                        _buildArticleDropdown(setDialogState),
                        const SizedBox(height: 12),
                        _buildColorDropdown(setDialogState),
                        const SizedBox(height: 12),
                        _buildQuantityField(),
                      ],
                    ),
                  ),
                ),
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
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProduction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _editingId == null ? 'Create' : 'Update',
                            style: TextStyle(color: Colors.white),
                          ),
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
                    : 'Select Date *',
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDate != null
                      ? Colors.black87
                      : Colors.grey.shade600,
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
            'Select PO No *',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          value: _selectedPoNo,
          items: [
            const DropdownMenuItem(value: null, child: Text('Select PO No *')),
            ..._getPoNumbers().map(
              (po) => DropdownMenuItem(value: po, child: Text(po)),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          value: _selectedArticle,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Select Article *'),
            ),
            if (_selectedPoNo != null)
              ..._getArticlesForPo(_selectedPoNo!).map(
                (article) =>
                    DropdownMenuItem(value: article, child: Text(article)),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          value: _selectedColor,
          items: [
            const DropdownMenuItem(value: null, child: Text('Select Color *')),
            if (_selectedPoNo != null && _selectedArticle != null)
              ..._getColorsForPoAndArticle(
                _selectedPoNo!,
                _selectedArticle!,
              ).map(
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
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(color),
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

  Widget _buildQuantityField() {
    return TextField(
      controller: _qtyController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity *',
        hintText: 'Enter production quantity',
        prefixIcon: const Icon(Icons.production_quantity_limits),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  void _showDeleteDialog(String id, int sl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Production?'),
        content: Text('SL $sl will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduction(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProductions;
    final totalItems = filtered.length;
    final totalQty = filtered.fold<double>(
      0,
      (sum, p) => sum + ((p['qty'] as num?)?.toDouble() ?? 0),
    );
    final totalValue = filtered.fold<double>(
      0,
      (sum, p) =>
          sum + (_getUnitPrice(p) * ((p['qty'] as num?)?.toDouble() ?? 0)),
    );

    final maxPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    if (_currentPage >= maxPages) _currentPage = maxPages - 1;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final paginated = filtered.sublist(startIndex, endIndex);

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.factory_outlined,
                        color: Colors.indigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Production Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Stats
                    _buildStatChip('Records', '$totalItems', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Qty',
                      NumberFormat('#,###').format(totalQty),
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Value',
                      '\$${NumberFormat('#,###').format(totalValue)}',
                      Colors.purple,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showFormDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by PO, Article or Color...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterPoNo.isEmpty ? null : _filterPoNo,
                          hint: const Text('PO Filter'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All POs'),
                            ),
                            ..._getPoNumbers().map(
                              (po) =>
                                  DropdownMenuItem(value: po, child: Text(po)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterPoNo = value ?? '';
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          items: _statusOptions
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: status == 'Complete'
                                              ? Colors.green
                                              : status == 'Pending'
                                              ? Colors.orange
                                              : status == 'Over'
                                              ? Colors.red
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(status),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Section with Scroll
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productions.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _horizontalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              color: Colors.indigo.shade50,
                              child: Row(
                                children: [
                                  _buildHeaderCell('SL', 50, center: true),
                                  _buildHeaderCell('Date', 100, center: true),
                                  _buildHeaderCell('PO No', 120, center: true),
                                  _buildHeaderCell(
                                    'Article',
                                    150,
                                    center: true,
                                  ),
                                  _buildHeaderCell('Color', 100, center: true),
                                  _buildHeaderCell('Qty', 90, center: true),
                                  _buildHeaderCell(
                                    'Unit Price',
                                    110,
                                    center: true,
                                  ),
                                  _buildHeaderCell(
                                    'Total Value',
                                    120,
                                    center: true,
                                  ),
                                  _buildHeaderCell('Status', 100, center: true),
                                  _buildHeaderCell('Actions', 90, center: true),
                                ],
                              ),
                            ),
                            // Table Rows
                            ...paginated.asMap().entries.map((entry) {
                              final idx = startIndex + entry.key;
                              final prod = entry.value;
                              final unitPrice = _getUnitPrice(prod);
                              final qty =
                                  (prod['qty'] as num?)?.toDouble() ?? 0;
                              final totalValue = unitPrice * qty;
                              final status = _getProductionStatus(prod);
                              final isEven = idx % 2 == 0;

                              return Container(
                                color: isEven
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                child: Row(
                                  children: [
                                    _buildDataCell(
                                      '${idx + 1}',
                                      50,
                                      center: true,
                                    ),
                                    _buildDataCell(
                                      _formatDate(prod['date']),
                                      100,
                                      center: true,
                                    ),
                                    _buildDataCell(
                                      prod['poNo'] ?? '—',
                                      120,
                                      center: true,
                                    ),
                                    _buildDataCell(
                                      prod['article'] ?? '—',
                                      150,
                                      center: true,
                                    ),
                                    _buildColorCell(prod['color'] ?? '—', 100),
                                    _buildDataCell(
                                      NumberFormat('#,###').format(qty),
                                      90,
                                      center: true,
                                    ),
                                    _buildDataCell(
                                      '\$${NumberFormat('#,###').format(unitPrice)}',
                                      110,
                                      center: true,
                                    ),
                                    _buildDataCell(
                                      '\$${NumberFormat('#,###').format(totalValue)}',
                                      120,
                                      center: true,
                                    ),
                                    _buildStatusCell(status, 100),
                                    _buildActionCell(prod['id'], idx + 1, prod),
                                  ],
                                ),
                              );
                            }),
                            // Footer Summary
                            Container(
                              color: Colors.indigo.shade50,
                              child: Row(
                                children: [
                                  _buildFooterCell(
                                    'Total',
                                    50,
                                    center: true,
                                    bold: true,
                                  ),
                                  _buildFooterCell('', 100, center: true),
                                  _buildFooterCell('', 120, center: true),
                                  _buildFooterCell('', 150, center: true),
                                  _buildFooterCell('', 100, center: true),
                                  _buildFooterCell(
                                    NumberFormat('#,###').format(totalQty),
                                    90,
                                    center: true,
                                    bold: true,
                                  ),
                                  _buildFooterCell('', 110, center: true),
                                  _buildFooterCell(
                                    '\$${NumberFormat('#,###').format(totalValue)}',
                                    120,
                                    center: true,
                                    bold: true,
                                  ),
                                  _buildFooterCell('', 100, center: true),
                                  _buildFooterCell('', 90, center: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          // Pagination
          if (!_isLoading && _productions.isNotEmpty && filtered.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Rows per page:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        items: [10, 15, 25, 50]
                            .map(
                              (v) =>
                                  DropdownMenuItem(value: v, child: Text('$v')),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _rowsPerPage = v!;
                          _currentPage = 0;
                        }),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${startIndex + 1}-$endIndex of $totalItems'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: endIndex < totalItems
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, {bool center = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: center ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool center = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: center ? TextAlign.center : TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildColorCell(String color, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getColorFromName(color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                color,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status, double width) {
    Color bgColor;
    Color textColor;
    if (status == 'Complete') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (status == 'Pending') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(String id, int sl, Map<String, dynamic> prod) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
              onPressed: () => _showFormDialog(prod),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _showDeleteDialog(id, sl),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCell(
    String text,
    double width, {
    bool center = false,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          textAlign: center ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.production_quantity_limits_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Production Records',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Click + to add first production',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
