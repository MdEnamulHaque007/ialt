import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/purchase_order_service.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data
  List<Map<String, dynamic>> _pos = [];
  List<Map<String, dynamic>> _filteredPos = [];
  Map<String, dynamic>? _selectedPO;
  bool _isLoading = true;

  List<String> _masterLcTags = [];

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  final String _filterStatus = 'All';
  String _sortBy = 'Date';

  // Animation
  late AnimationController _animationController;

  // Stats
  double _totalPoValue = 0;
  int _totalPoCount = 0;

  final PurchaseOrderService _service = PurchaseOrderService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadPOs();
    _loadMasterLcTags();
    _animationController.forward();
  }

  Future<void> _loadMasterLcTags() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('master_lc')
          .orderBy('tag_no')
          .get();
      setState(() {
        _masterLcTags = snapshot.docs
            .map((doc) => doc['tag_no']?.toString() ?? '')
            .where((tag) => tag.isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading master LC tags: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPOs() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('purchase_order')
          .get();

      _pos = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _calculateStats();
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      _showSnackBar('Error loading POs: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _totalPoCount = _pos.length;
    _totalPoValue = _pos.fold<double>(
      0,
      (sum, po) => sum + ((po['totalValue'] as num?)?.toDouble() ?? 0),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredPos = _pos.where((po) {
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          final poNo = po['poNo']?.toString().toLowerCase() ?? '';
          final orderBy = po['orderBy']?.toString().toLowerCase() ?? '';
          final tag = po['tag']?.toString().toLowerCase() ?? '';
          final brand = po['brand']?.toString().toLowerCase() ?? '';
          final project = po['project']?.toString().toLowerCase() ?? '';
          if (!poNo.contains(searchLower) &&
              !orderBy.contains(searchLower) &&
              !tag.contains(searchLower) &&
              !brand.contains(searchLower) &&
              !project.contains(searchLower)) {
            return false;
          }
        }

        // Status filter (based on if PO has any production)
        if (_filterStatus != 'All') {
          final hasProduction = _hasProductionForPo(
            po['poNo']?.toString() ?? '',
          );
          if (_filterStatus == 'Completed' && !hasProduction) return false;
          if (_filterStatus == 'Pending' && hasProduction) return false;
        }

        return true;
      }).toList();

      // Sorting
      _filteredPos.sort((a, b) {
        switch (_sortBy) {
          case 'PO No':
            return (a['poNo'] ?? '').toString().compareTo(b['poNo'] ?? '');
          case 'Value':
            return ((b['totalValue'] as num?)?.toDouble() ?? 0).compareTo(
              (a['totalValue'] as num?)?.toDouble() ?? 0,
            );
          case 'Quantity':
            return ((b['totalQuantity'] as num?)?.toDouble() ?? 0).compareTo(
              (a['totalQuantity'] as num?)?.toDouble() ?? 0,
            );
          default: // Date
            DateTime aDate = DateTime.now();
            DateTime bDate = DateTime.now();
            
            if (a['createdAt'] is Timestamp) {
              aDate = (a['createdAt'] as Timestamp).toDate();
            } else if (a['createdAt'] is String) {
              aDate = DateTime.tryParse(a['createdAt']) ?? DateTime.now();
            }

            if (b['createdAt'] is Timestamp) {
              bDate = (b['createdAt'] as Timestamp).toDate();
            } else if (b['createdAt'] is String) {
              bDate = DateTime.tryParse(b['createdAt']) ?? DateTime.now();
            }

            return bDate.compareTo(aDate);
        }
      });
    });
  }

  bool _hasProductionForPo(String poNo) {
    // This would need to check Firestore production collection
    // For now, return false as placeholder
    return false;
  }

  Future<void> _deletePO(String id) async {
    try {
      await _service.delete(id);
      _showSnackBar('PO deleted successfully');
      await _loadPOs();
      if (_selectedPO?.containsKey('id') == true && _selectedPO!['id'] == id) {
        setState(() => _selectedPO = null);
      }
    } catch (e) {
      _showSnackBar('Error deleting PO: $e', isError: true);
    }
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

  void _showCreateDialog() {
    final controllers = {
      'poDate': TextEditingController(),
      'poNo': TextEditingController(),
      'orderBy': TextEditingController(),
      'brand': TextEditingController(),
      'project': TextEditingController(),
      'tag': TextEditingController(),
    };

    List<Map<String, dynamic>> tempLines = [];
    final articleCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController();
    bool isAutoFilled = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 700,
            height: 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create Purchase Order',
                          style: TextStyle(
                            fontSize: 20,
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

                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: controllers['poDate']!,
                                label: 'PO Date *',
                                hint: 'Select date',
                                icon: Icons.calendar_today,
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Colors.indigo,
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      controllers['poDate']!.text = DateFormat(
                                        'dd MMM yyyy',
                                      ).format(date);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: controllers['poNo']!,
                                label: 'PO Number *',
                                hint: 'Enter PO number',
                                icon: Icons.receipt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: controllers['orderBy']!,
                                label: 'Order By',
                                hint: 'Customer name',
                                icon: Icons.person,
                                readOnly: isAutoFilled,
                                fillColor: isAutoFilled ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: controllers['brand']!,
                                label: 'Brand',
                                hint: 'Brand name',
                                icon: Icons.branding_watermark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: controllers['project']!,
                                label: 'Project',
                                hint: 'Project name',
                                icon: Icons.business,
                                readOnly: isAutoFilled,
                                fillColor: isAutoFilled ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: controllers['tag']!.text.isEmpty
                                    ? null
                                    : controllers['tag']!.text,
                                decoration: InputDecoration(
                                  labelText: 'Tag No (Master LC)',
                                  prefixIcon: Icon(
                                    Icons.label,
                                    size: 20,
                                    color: Colors.indigo.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.indigo,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                items: _masterLcTags
                                    .map(
                                      (tag) => DropdownMenuItem(
                                        value: tag,
                                        child: Text(tag),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  controllers['tag']!.text = value ?? '';
                                  if (value != null && value.isNotEmpty) {
                                    try {
                                      final snapshot = await FirebaseFirestore.instance
                                          .collection('master_lc')
                                          .where('tag_no', isEqualTo: value)
                                          .limit(1)
                                          .get();
                                      if (snapshot.docs.isNotEmpty) {
                                        final data = snapshot.docs.first.data();
                                        setDialogState(() {
                                          controllers['orderBy']!.text = data['applicant']?.toString() ?? '';
                                          controllers['project']!.text = data['project']?.toString() ?? '';
                                          isAutoFilled = true;
                                        });
                                      }
                                    } catch (e) {
                                      debugPrint('Error: $e');
                                    }
                                  } else {
                                    setDialogState(() => isAutoFilled = false);
                                  }
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Tag required'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Line Items Section
                        const Text(
                          'Line Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Add Line Item Form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildCompactField(
                                      articleCtrl,
                                      'Article',
                                      Icons.article,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _buildCompactField(
                                      colorCtrl,
                                      'Color',
                                      Icons.color_lens,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactField(
                                      qtyCtrl,
                                      'Qty',
                                      Icons.numbers,
                                      isNumber: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactField(
                                      unitPriceCtrl,
                                      'Price',
                                      Icons.attach_money,
                                      isNumber: true,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: IconButton(
                                      onPressed: () {
                                        final qty =
                                            double.tryParse(qtyCtrl.text) ?? 0;
                                        final unitPrice =
                                            double.tryParse(
                                              unitPriceCtrl.text,
                                            ) ??
                                            0;
                                        if (articleCtrl.text.isNotEmpty &&
                                            colorCtrl.text.isNotEmpty &&
                                            qty > 0 &&
                                            unitPrice > 0) {
                                          setDialogState(() {
                                            tempLines.add({
                                              'article': articleCtrl.text
                                                  .trim(),
                                              'color': colorCtrl.text.trim(),
                                              'qty': qty,
                                              'unitPrice': unitPrice,
                                              'totalValue': qty * unitPrice,
                                            });
                                            articleCtrl.clear();
                                            colorCtrl.clear();
                                            qtyCtrl.clear();
                                            unitPriceCtrl.clear();
                                          });
                                        } else {
                                          _showSnackBar(
                                            'Please fill all fields correctly',
                                            isError: true,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Line Items List
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.3,
                          ),
                          child: tempLines.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No line items added',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: tempLines.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final line = tempLines[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.indigo,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${line['article']} - ${line['color']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Qty: ${NumberFormat('#,###').format(line['qty'])}',
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Unit: \$${NumberFormat('#,###.##').format(line['unitPrice'])}',
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Total: \$${NumberFormat('#,###.##').format(line['totalValue'])}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => setDialogState(
                                              () => tempLines.removeAt(index),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        if (tempLines.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigo.shade50,
                                  Colors.blue.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Quantity: ${NumberFormat('#,###').format(tempLines.fold<double>(0, (sum, l) => sum + (l['qty'] ?? 0)))}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total Value: \$${NumberFormat('#,###.##').format(tempLines.fold<double>(0, (sum, l) => sum + (l['totalValue'] ?? 0)))}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              tempLines.isEmpty ||
                                  controllers['poNo']!.text.isEmpty
                              ? null
                              : () async {
                                  try {
                                    final totalQuantity = tempLines
                                        .fold<double>(
                                          0,
                                          (sum, l) => sum + (l['qty'] ?? 0),
                                        );
                                    final totalValue = tempLines.fold<double>(
                                      0,
                                      (sum, l) => sum + (l['totalValue'] ?? 0),
                                    );

                                    final po = PurchaseOrder(
                                      id: '',
                                      poNo: controllers['poNo']!.text.trim(),
                                      poDate: controllers['poDate']!.text
                                          .trim(),
                                      orderBy: controllers['orderBy']!.text
                                          .trim(),
                                      brand: controllers['brand']!.text.trim(),
                                      project: controllers['project']!.text
                                          .trim(),
                                      tag: controllers['tag']!.text.trim(),
                                      totalQuantity: totalQuantity.toInt(),
                                      totalValue: totalValue,
                                      lines: tempLines
                                          .map(
                                            (l) => PurchaseOrderLine(
                                              article:
                                                  l['article']?.toString() ??
                                                  '',
                                              color:
                                                  l['color']?.toString() ?? '',
                                              qty:
                                                  (l['qty'] as num?)?.toInt() ??
                                                  0,
                                              unitPrice:
                                                  (l['unitPrice'] as num?)
                                                      ?.toDouble() ??
                                                  0.0,
                                              totalValue:
                                                  (l['totalValue'] as num?)
                                                      ?.toDouble() ??
                                                  0.0,
                                            ),
                                          )
                                          .toList(),
                                      createdAt: DateTime.now(),
                                    );
                                    await _service.add(po);

                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    _showSnackBar('PO created successfully!');
                                    await _loadPOs();
                                  } catch (e) {
                                    _showSnackBar('Error: $e', isError: true);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Create PO'),
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

  void _showEditDialog(Map<String, dynamic> po) {
    final headerControllers = {
      'poDate': TextEditingController(text: po['poDate']?.toString() ?? ''),
      'poNo': TextEditingController(text: po['poNo']?.toString() ?? ''),
      'orderBy': TextEditingController(text: po['orderBy']?.toString() ?? ''),
      'brand': TextEditingController(text: po['brand']?.toString() ?? ''),
      'project': TextEditingController(text: po['project']?.toString() ?? ''),
      'tag': TextEditingController(text: po['tag']?.toString() ?? ''),
    };

    List<Map<String, dynamic>> tempLines = (po['lines'] as List? ?? [])
        .map((line) => Map<String, dynamic>.from(line as Map))
        .toList();

    final articleCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitPriceCtrl = TextEditingController();
    int? editingIndex;
    bool isAutoFilled = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 700,
            height: 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.orange.shade500],
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Purchase Order',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              po['poNo'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Basic Info (same as create dialog)
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: headerControllers['poDate']!,
                                label: 'PO Date *',
                                hint: 'Select date',
                                icon: Icons.calendar_today,
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: ctx,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) => Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Colors.orange,
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      headerControllers['poDate']!.text =
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(date);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: headerControllers['poNo']!,
                                label: 'PO Number *',
                                hint: 'Enter PO number',
                                icon: Icons.receipt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: headerControllers['orderBy']!,
                                label: 'Order By',
                                hint: 'Customer name',
                                icon: Icons.person,
                                readOnly: isAutoFilled,
                                fillColor: isAutoFilled ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: headerControllers['brand']!,
                                label: 'Brand',
                                hint: 'Brand name',
                                icon: Icons.branding_watermark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: headerControllers['project']!,
                                label: 'Project',
                                hint: 'Project name',
                                icon: Icons.business,
                                readOnly: isAutoFilled,
                                fillColor: isAutoFilled ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    headerControllers['tag']!.text.isEmpty
                                    ? null
                                    : headerControllers['tag']!.text,
                                decoration: InputDecoration(
                                  labelText: 'Tag No (Master LC)',
                                  prefixIcon: Icon(
                                    Icons.label,
                                    size: 20,
                                    color: Colors.indigo.shade400,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.indigo,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                items: _masterLcTags
                                    .map(
                                      (tag) => DropdownMenuItem(
                                        value: tag,
                                        child: Text(tag),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  headerControllers['tag']!.text = value ?? '';
                                  if (value != null && value.isNotEmpty) {
                                    try {
                                      final snapshot = await FirebaseFirestore.instance
                                          .collection('master_lc')
                                          .where('tag_no', isEqualTo: value)
                                          .limit(1)
                                          .get();
                                      if (snapshot.docs.isNotEmpty) {
                                        final data = snapshot.docs.first.data();
                                        setDialogState(() {
                                          headerControllers['orderBy']!.text = data['applicant']?.toString() ?? '';
                                          headerControllers['project']!.text = data['project']?.toString() ?? '';
                                          isAutoFilled = true;
                                        });
                                      }
                                    } catch (e) {
                                      debugPrint('Error: $e');
                                    }
                                  } else {
                                    setDialogState(() => isAutoFilled = false);
                                  }
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Tag required'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'Line Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildCompactField(
                                  articleCtrl,
                                  'Article',
                                  Icons.article,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildCompactField(
                                  colorCtrl,
                                  'Color',
                                  Icons.color_lens,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactField(
                                  qtyCtrl,
                                  'Qty',
                                  Icons.numbers,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactField(
                                  unitPriceCtrl,
                                  'Price',
                                  Icons.attach_money,
                                  isNumber: true,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                child: IconButton(
                                  onPressed: () {
                                    final qty =
                                        double.tryParse(qtyCtrl.text) ?? 0;
                                    final unitPrice =
                                        double.tryParse(unitPriceCtrl.text) ??
                                        0;
                                    if (articleCtrl.text.isNotEmpty &&
                                        colorCtrl.text.isNotEmpty &&
                                        qty > 0 &&
                                        unitPrice > 0) {
                                      setDialogState(() {
                                        final newLine = {
                                          'article': articleCtrl.text.trim(),
                                          'color': colorCtrl.text.trim(),
                                          'qty': qty,
                                          'unitPrice': unitPrice,
                                          'totalValue': qty * unitPrice,
                                        };
                                        if (editingIndex != null) {
                                          tempLines[editingIndex!] = newLine;
                                          editingIndex = null;
                                        } else {
                                          tempLines.add(newLine);
                                        }
                                        articleCtrl.clear();
                                        colorCtrl.clear();
                                        qtyCtrl.clear();
                                        unitPriceCtrl.clear();
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    editingIndex != null
                                        ? Icons.check_circle
                                        : Icons.add_circle,
                                    color: editingIndex != null
                                        ? Colors.orange
                                        : Colors.green,
                                    size: 32,
                                  ),
                                ),
                              ),
                              if (editingIndex != null)
                                IconButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      editingIndex = null;
                                      articleCtrl.clear();
                                      colorCtrl.clear();
                                      qtyCtrl.clear();
                                      unitPriceCtrl.clear();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.25,
                          ),
                          child: tempLines.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No line items',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: tempLines.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final line = tempLines[index];
                                    final isEditing = editingIndex == index;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isEditing
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isEditing
                                              ? Colors.orange
                                              : Colors.grey.shade200,
                                          width: isEditing ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isEditing
                                                  ? Colors.orange
                                                  : Colors.indigo,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${line['article']} - ${line['color']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Qty: ${NumberFormat('#,###').format(line['qty'])}',
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Unit: \$${NumberFormat('#,###.##').format(line['unitPrice'])}',
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Total: \$${NumberFormat('#,###.##').format(line['totalValue'])}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setDialogState(() {
                                                editingIndex = index;
                                                articleCtrl.text =
                                                    line['article'] ?? '';
                                                colorCtrl.text =
                                                    line['color'] ?? '';
                                                qtyCtrl.text =
                                                    (line['qty'] ?? 0)
                                                        .toString();
                                                unitPriceCtrl.text =
                                                    (line['unitPrice'] ?? 0)
                                                        .toString();
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => setDialogState(
                                              () => tempLines.removeAt(index),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        if (tempLines.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.deepOrange.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Quantity: ${NumberFormat('#,###').format(tempLines.fold<double>(0, (sum, l) => sum + (l['qty'] ?? 0)))}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total Value: \$${NumberFormat('#,###.##').format(tempLines.fold<double>(0, (sum, l) => sum + (l['totalValue'] ?? 0)))}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(24),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: tempLines.isEmpty
                              ? null
                              : () async {
                                  try {
                                    final totalQuantity = tempLines
                                        .fold<double>(
                                          0,
                                          (sum, l) => sum + (l['qty'] ?? 0),
                                        );
                                    final totalValue = tempLines.fold<double>(
                                      0,
                                      (sum, l) => sum + (l['totalValue'] ?? 0),
                                    );

                                    final po2 = PurchaseOrder(
                                      id: po['id'],
                                      poNo: headerControllers['poNo']!.text
                                          .trim(),
                                      poDate: headerControllers['poDate']!.text
                                          .trim(),
                                      orderBy: headerControllers['orderBy']!
                                          .text
                                          .trim(),
                                      brand: headerControllers['brand']!.text
                                          .trim(),
                                      project: headerControllers['project']!
                                          .text
                                          .trim(),
                                      tag: headerControllers['tag']!.text
                                          .trim(),
                                      totalQuantity: totalQuantity.toInt(),
                                      totalValue: totalValue,
                                      lines: tempLines
                                          .map(
                                            (l) => PurchaseOrderLine(
                                              article:
                                                  l['article']?.toString() ??
                                                  '',
                                              color:
                                                  l['color']?.toString() ?? '',
                                              qty:
                                                  (l['qty'] as num?)?.toInt() ??
                                                  0,
                                              unitPrice:
                                                  (l['unitPrice'] as num?)
                                                      ?.toDouble() ??
                                                  0.0,
                                              totalValue:
                                                  (l['totalValue'] as num?)
                                                      ?.toDouble() ??
                                                  0.0,
                                            ),
                                          )
                                          .toList(),
                                      updatedAt: DateTime.now(),
                                    );
                                    await _service.update(po2);

                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    _showSnackBar('PO updated successfully!');
                                    await _loadPOs();
                                  } catch (e) {
                                    _showSnackBar('Error: $e', isError: true);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Update PO'),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    Color? fillColor,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: fillColor != null,
        fillColor: fillColor,
        prefixIcon: Icon(icon, size: 20, color: Colors.indigo.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCompactField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  void _showDeleteDialog(String id, String poNo) {
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
                'Delete Purchase Order?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'PO $poNo will be permanently deleted.',
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
                        _deletePO(id);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
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
                        Icons.shopping_cart_outlined,
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
                            'Purchase Orders',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage all purchase orders and line items',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Stats
                    _buildStatChip(
                      label: 'Total POs',
                      value: '$_totalPoCount',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      label: 'Total Value',
                      value: '\$${NumberFormat('#,###').format(_totalPoValue)}',
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by PO No, Order By, Brand, Project...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Icons.sort),
                          items: ['Date', 'PO No', 'Value', 'Quantity'].map((
                            sort,
                          ) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                              _applyFilters();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _loadPOs,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('New PO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pos.isEmpty
                ? _buildEmptyState()
                : Row(
                    children: [
                      // PO Grid
                      Expanded(
                        flex: 2,
                        child: _filteredPos.isEmpty
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
                                      'No matching POs found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 0.85,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: _filteredPos.length,
                                itemBuilder: (context, index) {
                                  final po = _filteredPos[index];
                                  final isSelected =
                                      _selectedPO?['id'] == po['id'];
                                  return FadeTransition(
                                    opacity: AlwaysStoppedAnimation(
                                      1 - (index * 0.02).clamp(0, 1),
                                    ),
                                    child: _POCard(
                                      po: po,
                                      isSelected: isSelected,
                                      onTap: () =>
                                          setState(() => _selectedPO = po),
                                      onEdit: () => _showEditDialog(po),
                                      onDelete: () => _showDeleteDialog(
                                        po['id'],
                                        po['poNo'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Line Items Panel
                      Container(
                        width: 380,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: _selectedPO == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Select a PO to view details',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _LineItemsPanel(po: _selectedPO!),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Purchase Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to create your first PO',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// PO Card Widget
class _POCard extends StatelessWidget {
  final Map<String, dynamic> po;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _POCard({
    required this.po,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalValue = (po['totalValue'] as num?)?.toDouble() ?? 0;
    final totalQty = (po['totalQuantity'] as num?)?.toDouble() ?? 0;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isSelected ? Colors.indigo.shade50 : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt,
                      size: 20,
                      color: isSelected ? Colors.white : Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      po['poNo'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? Colors.indigo : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isSelected ? Colors.indigo : Colors.grey,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              if (po['orderBy']?.isNotEmpty == true) ...[
                Text(
                  po['orderBy'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (po['brand']?.isNotEmpty == true) ...[
                Text(
                  po['brand'],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (po['project']?.isNotEmpty == true) ...[
                Text(
                  po['project'],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // Footer
              Divider(height: 24, color: Colors.grey.shade200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        NumberFormat('#,###').format(totalQty),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Value',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '\$${NumberFormat('#,###').format(totalValue)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Line Items Panel Widget
class _LineItemsPanel extends StatelessWidget {
  final Map<String, dynamic> po;

  const _LineItemsPanel({required this.po});

  @override
  Widget build(BuildContext context) {
    final lines = (po['lines'] as List? ?? []);
    final totalQty = (po['totalQuantity'] as num?)?.toDouble() ?? 0;
    final totalValue = (po['totalValue'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Line Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'PO: ${po['poNo'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (po['poDate']?.isNotEmpty == true)
                Text(
                  'Date: ${po['poDate']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),

        // Line Items List
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No line items',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final qty = (line['qty'] as num?)?.toDouble() ?? 0;
                    final unitPrice =
                        (line['unitPrice'] as num?)?.toDouble() ?? 0;
                    final total = qty * unitPrice;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${line['article'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      line['color'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat('#,###').format(qty),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unit Price',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${NumberFormat('#,###.##').format(unitPrice)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${NumberFormat('#,###.##').format(total)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Footer Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Quantity:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    NumberFormat('#,###').format(totalQty),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Value:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${NumberFormat('#,###.##').format(totalValue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
