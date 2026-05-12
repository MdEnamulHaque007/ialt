import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cutting.dart';
import '../services/cutting_service.dart';

class CuttingPage extends StatefulWidget {
  const CuttingPage({super.key});

  @override
  State<CuttingPage> createState() => _CuttingPageState();
}

class _CuttingPageState extends State<CuttingPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CuttingService _service = CuttingService();

  List<Map<String, dynamic>> _cuttings = [];
  bool _isLoading = true;

  // Form state
  DateTime? _selectedDate;
  final TextEditingController _voucherController = TextEditingController();
  String? _selectedPoNo;
  String? _selectedArticle;
  String? _selectedColor;
  final TextEditingController _quantityController = TextEditingController();
  String? _editingId;

  // Search & filter
  String _searchQuery = '';

  // Pagination
  int _rowsPerPage = 15;
  int _currentPage = 0;

  // Scroll controllers (for wide table)
  final ScrollController _horizontalScrollController = ScrollController();

  late final TextEditingController _dummy = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    _quantityController.dispose();
    _horizontalScrollController.dispose();
    _dummy.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('cutting').get();
      _cuttings = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading cutting: $e', isError: true);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _cuttings;
    return _cuttings.where((c) {
      final voucher = c['voucherNo']?.toString().toLowerCase() ?? '';
      final poNo = c['poNo']?.toString().toLowerCase() ?? '';
      final article = c['articleNo']?.toString().toLowerCase() ?? '';
      final color = c['color']?.toString().toLowerCase() ?? '';
      return voucher.contains(q) ||
          poNo.contains(q) ||
          article.contains(q) ||
          color.contains(q);
    }).toList();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_quantityController.text.trim());
    if (_selectedDate == null ||
        _voucherController.text.trim().isEmpty ||
        _selectedPoNo == null ||
        _selectedArticle == null ||
        _selectedColor == null ||
        qty == null ||
        qty <= 0) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    try {
      final cutting = Cutting(
        id: _editingId ?? '',
        voucherNo: _voucherController.text.trim(),
        poNo: _selectedPoNo ?? '',
        articleNo: _selectedArticle ?? '',
        color: _selectedColor ?? '',
        quantity: qty,
        date: _selectedDate!.toIso8601String(),
        createdAt: _editingId == null ? DateTime.now() : null,
        updatedAt: _editingId != null ? DateTime.now() : null,
      );

      if (_editingId == null) {
        await _service.create(cutting);
        _showSnackBar('Cutting created successfully');
      } else {
        await _service.update(cutting);
        _showSnackBar('Cutting updated successfully');
      }

      _resetForm();
      await _loadData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _service.delete(id);
      _showSnackBar('Cutting deleted successfully');
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _resetForm() {
    _selectedDate = null;
    _voucherController.clear();
    _selectedPoNo = null;
    _selectedArticle = null;
    _selectedColor = null;
    _quantityController.clear();
    _editingId = null;
  }

  bool get _isFormValid {
    final qty = int.tryParse(_quantityController.text.trim());
    return _selectedDate != null &&
        _voucherController.text.trim().isNotEmpty &&
        _selectedPoNo != null &&
        _selectedArticle != null &&
        _selectedColor != null &&
        qty != null &&
        qty > 0;
  }

  void _showForm([Map<String, dynamic>? data]) {
    _resetForm();

    if (data != null) {
      _editingId = data['id']?.toString();
      _voucherController.text = data['voucherNo']?.toString() ?? '';
      _selectedPoNo = data['poNo']?.toString();
      _selectedArticle = data['articleNo']?.toString();
      _selectedColor = data['color']?.toString();
      _quantityController.text = data['quantity']?.toString() ?? '';

      final rawDate = data['date'];
      if (rawDate is Timestamp) {
        _selectedDate = rawDate.toDate();
      } else if (rawDate is String && rawDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(rawDate);
      }
    }

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
                      colors: _editingId == null
                          ? [Colors.blue.shade700, Colors.blue.shade500]
                          : [Colors.indigo.shade700, Colors.indigo.shade500],
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
                        child: const Icon(
                          Icons.cut,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _editingId == null ? 'Add Cutting' : 'Edit Cutting',
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
                        _buildTextField(
                          controller: _voucherController,
                          label: 'Voucher No *',
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownField(
                          label: 'PO No *',
                          value: _selectedPoNo,
                          onChanged: (v) {
                            setDialogState(() => _selectedPoNo = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: TextEditingController(
                            text: _selectedArticle ?? '',
                          ),
                          label: 'Article No *',
                          icon: Icons.article,
                          onChanged: (v) {
                            setDialogState(() => _selectedArticle = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: TextEditingController(
                            text: _selectedColor ?? '',
                          ),
                          label: 'Color *',
                          icon: Icons.color_lens,
                          onChanged: (v) {
                            setDialogState(() => _selectedColor = v);
                          },
                        ),
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
                          onPressed: _isFormValid ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(_editingId == null ? 'Create' : 'Update'),
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
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          setDialogState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedDate != null ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: _selectedDate != null
                  ? Colors.blue.shade700
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Quantity *',
        prefixIcon: Icon(Icons.production_quantity_limits),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.blue.shade700),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    // For now: reuse free-text input pattern instead of PO/Article lookup.
    // Keeps implementation simple and avoids adding more dependencies.
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.receipt_long, size: 18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      controller: TextEditingController(text: value ?? ''),
      onChanged: onChanged,
    );
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalItems = filtered.length;

    final maxPages = totalItems > 0 ? (totalItems / _rowsPerPage).ceil() : 1;
    if (_currentPage >= maxPages) _currentPage = maxPages - 1;

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final paginated = filtered.sublist(startIndex, endIndex);

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cut,
                        color: Colors.blue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cutting Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip('Records', '$totalItems', Colors.blue),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showForm(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by Voucher, PO, Article or Color...',
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
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cuttings.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _horizontalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              color: Colors.blue.shade50,
                              child: Row(
                                children: [
                                  _buildHeaderCell('SL', 50, center: true),
                                  _buildHeaderCell('Date', 100, center: true),
                                  _buildHeaderCell('Voucher No', 150),
                                  _buildHeaderCell('PO No', 120),
                                  _buildHeaderCell('Article', 150),
                                  _buildHeaderCell('Color', 120),
                                  _buildHeaderCell('Qty', 90, center: true),
                                  _buildHeaderCell(
                                    'Actions',
                                    100,
                                    center: true,
                                  ),
                                ],
                              ),
                            ),
                            ...paginated.asMap().entries.map((entry) {
                              final idx = startIndex + entry.key;
                              final c = entry.value;
                              final dateStr = _formatDate(c['date']);
                              return Container(
                                color: (idx % 2 == 0)
                                    ? Colors.white
                                    : Colors.blue.shade50.withValues(
                                        alpha: 0.25,
                                      ),
                                child: Row(
                                  children: [
                                    _buildDataCell(
                                      '${idx + 1}',
                                      50,
                                      center: true,
                                    ),
                                    _buildDataCell(dateStr, 100, center: true),
                                    _buildDataCell(c['voucherNo'] ?? '—', 150),
                                    _buildDataCell(c['poNo'] ?? '—', 120),
                                    _buildDataCell(c['articleNo'] ?? '—', 150),
                                    _buildDataCell(c['color'] ?? '—', 120),
                                    _buildDataCell(
                                      NumberFormat('#,###').format(
                                        (c['quantity'] as num?)?.toInt() ?? 0,
                                      ),
                                      90,
                                      center: true,
                                    ),
                                    _buildActionCell(c['id'], idx + 1),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (!_isLoading && _cuttings.isNotEmpty && filtered.isNotEmpty)
            _buildPagination(totalItems, startIndex, endIndex),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems, int startIndex, int endIndex) {
    return Container(
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
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    }
    return '';
  }

  Widget _buildActionCell(String? id, int sl) {
    return SizedBox(
      width: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
              onPressed: () {
                final data = _cuttings.firstWhere(
                  (x) => x['id']?.toString() == id,
                  orElse: () => {},
                );
                _showForm(data.isEmpty ? null : data);
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _showDeleteDialog(id, sl),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String? id, int sl) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Cutting?'),
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
              _delete(id);
            },
            child: const Text('Delete'),
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
          const Icon(Icons.cut, size: 70, color: Colors.blueGrey),
          const SizedBox(height: 16),
          const Text(
            'No Cutting Records',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click + to add first cutting',
            style: TextStyle(color: Colors.grey),
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
}
