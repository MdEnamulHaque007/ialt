import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data
  List<Map<String, dynamic>> _exports = [];
  List<Map<String, dynamic>> _issues = [];
  List<Map<String, dynamic>> _purchaseOrders = [];
  bool _isLoading = true;

  // Form state
  DateTime? _selectedDate;
  final TextEditingController _dcNoController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _selectedPoNo;
  String? _selectedArticle;
  String? _selectedColor;
  String? _selectedDeliveryCriteria;
  String? _selectedSellingCriteria;
  String? _editingId;

  // Search & Filter
  String _searchQuery = '';
  String _filterDeliveryCriteria = 'All';
  String _filterSellingCriteria = 'All';

  // Pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;

  // Scroll controller for horizontal scroll
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dcNoController.dispose();
    _invoiceController.dispose();
    _quantityController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadExports(), _loadIssues(), _loadPurchaseOrders()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadExports() async {
    try {
      final snapshot = await _firestore
          .collection('export')
          .orderBy('date', descending: true)
          .get();

      _exports = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _showSnackBar('Error loading exports: $e', isError: true);
    }
  }

  Future<void> _loadIssues() async {
    try {
      final snapshot = await _firestore.collection('issue').get();
      _issues = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Issues load error: $e');
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

  List<Map<String, dynamic>> get _filteredExports {
    return _exports.where((exp) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final dcMatch =
            exp['dcNo']?.toString().toLowerCase().contains(searchLower) ??
            false;
        final invoiceMatch =
            exp['commercialInvoice']?.toString().toLowerCase().contains(
              searchLower,
            ) ??
            false;
        final poMatch =
            exp['poNo']?.toString().toLowerCase().contains(searchLower) ??
            false;
        if (!dcMatch && !invoiceMatch && !poMatch) return false;
      }

      // Delivery criteria filter
      if (_filterDeliveryCriteria != 'All' &&
          exp['deliveryCriteria'] != _filterDeliveryCriteria)
        return false;

      // Selling criteria filter
      if (_filterSellingCriteria != 'All' &&
          exp['sellingCriteria'] != _filterSellingCriteria)
        return false;

      return true;
    }).toList();
  }

  double _getTotalValue(Map<String, dynamic> export) {
    final qty = (export['quantity'] as num?)?.toDouble() ?? 0;
    final unitPrice = _getUnitPrice(
      export['poNo']?.toString() ?? '',
      export['articleNo']?.toString() ?? '',
      export['color']?.toString() ?? '',
    );
    return qty * unitPrice;
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

  double _getIssuedQty(String poNo, String articleNo, String color) {
    double issuedQty = 0.0;
    for (final issue in _issues) {
      if (issue['poNo']?.toString() == poNo &&
          issue['articleNo']?.toString() == articleNo &&
          issue['color']?.toString() == color) {
        issuedQty += (issue['quantity'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return issuedQty;
  }

  double _getExportedQty(String poNo, String articleNo, String color) {
    double exportedQty = 0.0;
    for (final export in _exports) {
      if (export['poNo']?.toString() == poNo &&
          export['articleNo']?.toString() == articleNo &&
          export['color']?.toString() == color &&
          export['id'] != _editingId) {
        exportedQty += (export['quantity'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return exportedQty;
  }

  List<String> get _poNumbers {
    return _issues
        .map((issue) => issue['poNo']?.toString() ?? '')
        .where((po) => po.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _articlesForSelectedPo {
    if (_selectedPoNo == null) return [];
    return _issues
        .where((i) => i['poNo']?.toString() == _selectedPoNo)
        .map((i) => i['articleNo']?.toString() ?? '')
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _colorsForSelectedPoArticle {
    if (_selectedPoNo == null || _selectedArticle == null) return [];
    return _issues
        .where(
          (i) =>
              i['poNo']?.toString() == _selectedPoNo &&
              i['articleNo']?.toString() == _selectedArticle,
        )
        .map((i) => i['color']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _saveExport() async {
    final qty = double.tryParse(_quantityController.text.trim());
    if (_selectedDate == null ||
        _dcNoController.text.isEmpty ||
        _invoiceController.text.isEmpty ||
        _selectedPoNo == null ||
        _selectedArticle == null ||
        _selectedColor == null ||
        qty == null ||
        qty <= 0 ||
        _selectedDeliveryCriteria == null ||
        _selectedSellingCriteria == null) {
      _showSnackBar('Please fill all fields correctly', isError: true);
      return;
    }

    // Check remaining quantity
    final issuedQty = _getIssuedQty(
      _selectedPoNo!,
      _selectedArticle!,
      _selectedColor!,
    );
    final exportedQty = _getExportedQty(
      _selectedPoNo!,
      _selectedArticle!,
      _selectedColor!,
    );
    final remaining = issuedQty - exportedQty;

    if (qty > remaining) {
      _showSnackBar(
        'Export quantity ($qty) exceeds remaining available quantity ($remaining). Entry blocked!',
        isError: true,
      );
      return;
    }

    final exportData = {
      'date': Timestamp.fromDate(_selectedDate!),
      'dcNo': _dcNoController.text.trim(),
      'commercialInvoice': _invoiceController.text.trim(),
      'poNo': _selectedPoNo,
      'articleNo': _selectedArticle,
      'color': _selectedColor,
      'quantity': qty,
      'deliveryCriteria': _selectedDeliveryCriteria,
      'sellingCriteria': _selectedSellingCriteria,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingId == null) {
        exportData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('export').add(exportData);
        _showSnackBar('Export added successfully');
      } else {
        await _firestore
            .collection('export')
            .doc(_editingId)
            .update(exportData);
        _showSnackBar('Export updated successfully');
      }

      _resetForm();
      await _loadData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _deleteExport(String id) async {
    try {
      await _firestore.collection('export').doc(id).delete();
      _showSnackBar('Export deleted successfully');
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _resetForm() {
    _selectedDate = null;
    _dcNoController.clear();
    _invoiceController.clear();
    _quantityController.clear();
    _selectedPoNo = null;
    _selectedArticle = null;
    _selectedColor = null;
    _selectedDeliveryCriteria = null;
    _selectedSellingCriteria = null;
    _editingId = null;
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

  void _showFormDialog([Map<String, dynamic>? export]) {
    _resetForm();

    if (export != null) {
      _selectedDate = (export['date'] as Timestamp?)?.toDate();
      _dcNoController.text = export['dcNo']?.toString() ?? '';
      _invoiceController.text = export['commercialInvoice']?.toString() ?? '';
      _quantityController.text = export['quantity']?.toString() ?? '';
      _selectedPoNo = export['poNo']?.toString();
      _selectedArticle = export['articleNo']?.toString();
      _selectedColor = export['color']?.toString();
      _selectedDeliveryCriteria = export['deliveryCriteria']?.toString();
      _selectedSellingCriteria = export['sellingCriteria']?.toString();
      _editingId = export['id'];
    }

    final isEdit = _editingId != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.add,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Export' : 'New Export',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Date Picker
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_selectedDate!)
                                        : 'Select Export Date *',
                                    style: TextStyle(
                                      color: _selectedDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DC No
                        TextField(
                          controller: _dcNoController,
                          decoration: const InputDecoration(
                            labelText: 'DC Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_shipping),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Commercial Invoice
                        TextField(
                          controller: _invoiceController,
                          decoration: const InputDecoration(
                            labelText: 'Commercial Invoice *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PO Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'PO Number *',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedPoNo,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select PO Number *'),
                            ),
                            ..._poNumbers.map(
                              (po) =>
                                  DropdownMenuItem(value: po, child: Text(po)),
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
                        const SizedBox(height: 12),

                        // Article Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Article Number *',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedArticle,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select Article *'),
                            ),
                            ..._articlesForSelectedPo.map(
                              (article) => DropdownMenuItem(
                                value: article,
                                child: Text(article),
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
                        const SizedBox(height: 12),

                        // Color Dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Color *',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedColor,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select Color *'),
                            ),
                            ..._colorsForSelectedPoArticle.map(
                              (color) => DropdownMenuItem(
                                value: color,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getColorFromName(color),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(color),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged:
                              (_selectedPoNo != null &&
                                  _selectedArticle != null)
                              ? (value) =>
                                    setDialogState(() => _selectedColor = value)
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Quantity
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Delivery Criteria
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Delivery Criteria *',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedDeliveryCriteria,
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Select Delivery Criteria *'),
                            ),
                            DropdownMenuItem(
                              value: 'FG',
                              child: Text('FG - Finished Goods'),
                            ),
                            DropdownMenuItem(
                              value: 'B-Grade',
                              child: Text('B-Grade'),
                            ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => _selectedDeliveryCriteria = value,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Selling Criteria
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Selling Criteria *',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedSellingCriteria,
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Select Selling Criteria *'),
                            ),
                            DropdownMenuItem(
                              value: 'Sale',
                              child: Text('Sale'),
                            ),
                            DropdownMenuItem(
                              value: 'Gift',
                              child: Text('Gift'),
                            ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => _selectedSellingCriteria = value,
                          ),
                        ),

                        // Remaining Info
                        if (_selectedPoNo != null &&
                            _selectedArticle != null &&
                            _selectedColor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.blue.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Available: ${(_getIssuedQty(_selectedPoNo!, _selectedArticle!, _selectedColor!) - _getExportedQty(_selectedPoNo!, _selectedArticle!, _selectedColor!)).toStringAsFixed(0)} units',
                                      style: TextStyle(
                                        fontSize: 12,
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

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveExport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isEdit ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  void _showDeleteDialog(String id, String dcNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delete'),
        content: Text('Delete export DC: $dcNo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteExport(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExports;
    final totalItems = filtered.length;
    final totalQty = filtered.fold<double>(
      0,
      (sum, e) => sum + ((e['quantity'] as num?)?.toDouble() ?? 0),
    );
    final totalValue = filtered.fold<double>(
      0,
      (sum, e) => sum + _getTotalValue(e),
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
        label: const Text('New Export'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Header
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Export Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Stats
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Exports',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            '${filtered.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Qty',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            NumberFormat('#,###').format(totalQty),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Value',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            '\$${NumberFormat('#,###').format(totalValue)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
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
                          hintText: 'Search by DC, Invoice, PO...',
                          prefixIcon: const Icon(Icons.search),
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
                          value: _filterDeliveryCriteria,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Delivery'),
                            ),
                            DropdownMenuItem(value: 'FG', child: Text('FG')),
                            DropdownMenuItem(
                              value: 'B-Grade',
                              child: Text('B-Grade'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterDeliveryCriteria = value!;
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
                          value: _filterSellingCriteria,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Selling'),
                            ),
                            DropdownMenuItem(
                              value: 'Sale',
                              child: Text('Sale'),
                            ),
                            DropdownMenuItem(
                              value: 'Gift',
                              child: Text('Gift'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterSellingCriteria = value!;
                              _currentPage = 0;
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text('No exports found'),
                        const SizedBox(height: 8),
                        const Text('Tap + button to add new export'),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? const Center(child: Text('No matching exports found'))
                : Scrollbar(
                    controller: _horizontalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 45,
                          dataRowHeight: 50,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                            verticalInside: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.green.shade50,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'SL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'DC No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Invoice',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'PO No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Article',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Color',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Qty',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Unit Price',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Delivery',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Selling',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: paginated.asMap().entries.map((entry) {
                            final idx = startIndex + entry.key;
                            final export = entry.value;
                            final unitPrice = _getUnitPrice(
                              export['poNo']?.toString() ?? '',
                              export['articleNo']?.toString() ?? '',
                              export['color']?.toString() ?? '',
                            );
                            final qty =
                                (export['quantity'] as num?)?.toDouble() ?? 0;
                            final totalValue = unitPrice * qty;

                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text(_formatDate(export['date']))),
                                DataCell(Text(export['dcNo'] ?? '—')),
                                DataCell(
                                  Text(export['commercialInvoice'] ?? '—'),
                                ),
                                DataCell(Text(export['poNo'] ?? '—')),
                                DataCell(Text(export['articleNo'] ?? '—')),
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _getColorFromName(
                                            export['color'] ?? '',
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(export['color'] ?? '—'),
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
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: export['deliveryCriteria'] == 'FG'
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      export['deliveryCriteria'] ?? '—',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            export['deliveryCriteria'] == 'FG'
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: export['sellingCriteria'] == 'Sale'
                                          ? Colors.blue.shade50
                                          : Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      export['sellingCriteria'] ?? '—',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            export['sellingCriteria'] == 'Sale'
                                            ? Colors.blue.shade700
                                            : Colors.purple.shade700,
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
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _showFormDialog(export),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _showDeleteDialog(
                                          export['id'],
                                          export['dcNo'] ?? '',
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
          ),

          // Pagination
          if (!_isLoading && _exports.isNotEmpty && filtered.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Rows per page:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _rowsPerPage,
                    items: [10, 15, 25, 50]
                        .map(
                          (v) => DropdownMenuItem(value: v, child: Text('$v')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _rowsPerPage = v!;
                      _currentPage = 0;
                    }),
                  ),
                  const SizedBox(width: 16),
                  Text('${startIndex + 1}-$endIndex of $totalItems'),
                  const SizedBox(width: 16),
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
    );
  }
}
