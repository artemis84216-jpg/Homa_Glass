import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllOrders();
      if (mounted) {
        setState(() { _orders = data; _filtered = data; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      var result = _orders;
      if (_statusFilter != 'all') {
        result = result.where((o) => o['status'] == _statusFilter).toList();
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        result = result.where((o) => 
          (o['order_number'] ?? '').toString().toLowerCase().contains(q) ||
          (o['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
          (o['frame_name'] ?? '').toString().toLowerCase().contains(q)
        ).toList();
      }
      _filtered = result;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'ready': return AppTheme.green;
      case 'delivered': return AppTheme.textGrey;
      case 'cancelled': return Colors.red;
      default: return AppTheme.textGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'در انتظار';
      case 'in_progress': return 'در حال ساخت';
      case 'ready': return 'آماده تحویل';
      case 'delivered': return 'تحویل داده شده';
      case 'cancelled': return 'لغو شده';
      default: return status;
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> order) async {
    String newStatus = order['status'] ?? 'pending';
    final deliveryController = TextEditingController(text: order['delivery_date']?.toString() ?? '');
    final notesController = TextEditingController(text: order['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: const Text('تغییر وضعیت سفارش', style: TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('شماره سفارش: ${order['order_number']}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: newStatus,
                  dropdownColor: AppTheme.cardBlack,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'وضعیت جدید', prefixIcon: Icon(Icons.update, color: AppTheme.yellow)),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
                    DropdownMenuItem(value: 'in_progress', child: Text('در حال ساخت')),
                    DropdownMenuItem(value: 'ready', child: Text('آماده تحویل')),
                    DropdownMenuItem(value: 'delivered', child: Text('تحویل داده شده')),
                    DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
                  ],
                  onChanged: (v) => setStateDialog(() => newStatus = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: deliveryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تاریخ تحویل', prefixIcon: Icon(Icons.event, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.yellow))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  try {
                    await DatabaseHelper.instance.updateOrder(order['id'], {
                      'status': newStatus,
                      'delivery_date': deliveryController.text.trim(),
                      'notes': notesController.text.trim(),
                    });
                    Navigator.pop(ctx);
                    _loadOrders();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ وضعیت بروزرسانی شد'), backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('ذخیره', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOrderSms(Map<String, dynamic> order) async {
    final customerPhone = order['customer_phone']?.toString() ?? '';
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره تماس مشتری ثبت نشده'), backgroundColor: Colors.red));
      return;
    }

    final statusText = _getStatusText(order['status'] ?? 'pending');
    final buffer = StringBuffer();
    buffer.writeln('وضعیت سفارش شما - Homa Glass');
    buffer.writeln('شماره سفارش: ${order['order_number']}');
    buffer.writeln('-------------------');
    buffer.writeln('وضعیت فعلی: $statusText');
    if ((order['frame_name'] ?? '').toString().isNotEmpty) {
      buffer.writeln('فریم: ${order['frame_name']}');
    }
    if ((order['lens_name'] ?? '').toString().isNotEmpty) {
      buffer.writeln('عدسی: ${order['lens_name']}');
    }
    if ((order['delivery_date'] ?? '').toString().isNotEmpty) {
      buffer.writeln('تاریخ تحویل: ${order['delivery_date']}');
    }
    buffer.writeln('مبلغ: ${formatPrice((order['total'] ?? 0).toInt())} تومان');
    buffer.writeln('-------------------');
    buffer.writeln('با احترام، مرکز عینک هما');

    final smsBody = Uri.encodeComponent(buffer.toString());
    final smsUri = Uri.parse('sms:$customerPhone?body=$smsBody');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('امکان باز کردن پیامک وجود ندارد'), backgroundColor: Colors.red));
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text('جزئیات سفارش ${order['order_number']}', style: const TextStyle(color: AppTheme.yellow)),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _detailRow('مشتری', order['customer_name'] ?? '-'),
              _detailRow('تاریخ سفارش', order['order_date'] ?? '-'),
              _detailRow('تاریخ تحویل', order['delivery_date'] ?? '-'),
              _detailRow('وضعیت', _getStatusText(order['status'] ?? ''), color: _getStatusColor(order['status'] ?? '')),
              const Divider(color: AppTheme.yellow),
              _detailRow('فریم', order['frame_name'] ?? '-'),
              _detailRow('عدسی', order['lens_name'] ?? '-'),
              const Divider(color: AppTheme.yellow),
              const Text('نسخه چشم:', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('OD: SPH ${order['sph_right']} | CYL ${order['cyl_right']} | AXIS ${order['axis_right']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontFamily: 'monospace')),
              Text('OS: SPH ${order['sph_left']} | CYL ${order['cyl_left']} | AXIS ${order['axis_left']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontFamily: 'monospace')),
              Text('PD: ${order['pd']} | ADD: ${order['add_value']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontFamily: 'monospace')),
              const Divider(color: AppTheme.yellow),
              _detailRow('جمع کل', '${formatPrice((order['subtotal'] ?? 0).toInt())} تومان'),
              _detailRow('تخفیف', '${formatPrice((order['discount'] ?? 0).toInt())} تومان', color: Colors.red),
              _detailRow('مبلغ نهایی', '${formatPrice((order['total'] ?? 0).toInt())} تومان', color: AppTheme.yellow, isBold: true),
              if ((order['notes'] ?? '').toString().isNotEmpty) ...[
                const Divider(color: AppTheme.yellow),
                _detailRow('یادداشت', order['notes']),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن', style: TextStyle(color: AppTheme.yellow))),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color color = AppTheme.textWhite, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { 
      await DatabaseHelper.instance.deleteOrder(id); 
      _loadOrders(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سفارشات'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadOrders)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              TextField(
                controller: _searchController, style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(hintText: 'جستجو بر اساس شماره، مشتری یا فریم...', prefixIcon: const Icon(Icons.search, color: AppTheme.yellow), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.yellow), onPressed: () { _searchController.clear(); _applyFilters(); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onChanged: (_) => _applyFilters(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('all', 'همه'),
                    _buildFilterChip('pending', 'در انتظار'),
                    _buildFilterChip('in_progress', 'در حال ساخت'),
                    _buildFilterChip('ready', 'آماده تحویل'),
                    _buildFilterChip('delivered', 'تحویل شده'),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) : _filtered.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('سفارشی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final o = _filtered[index];
                final statusColor = _getStatusColor(o['status'] ?? 'pending');
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showOrderDetails(o),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor)), child: Text(_getStatusText(o['status'] ?? ''), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12))),
                          const Spacer(),
                          Text(o['order_date'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),
                        Text('شماره: ${o['order_number']}', style: const TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('مشتری: ${o['customer_name'] ?? '-'}', style: const TextStyle(color: AppTheme.textWhite)),
                        if ((o['frame_name'] ?? '').toString().isNotEmpty) Text('فریم: ${o['frame_name']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        if ((o['lens_name'] ?? '').toString().isNotEmpty) Text('عدسی: ${o['lens_name']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        const Divider(color: AppTheme.yellow, height: 20),
                        Row(children: [
                          const Icon(Icons.attach_money, size: 20, color: AppTheme.yellow),
                          const SizedBox(width: 8),
                          Text('${formatPrice((o['total'] ?? 0).toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.sms, color: AppTheme.yellow), tooltip: 'ارسال پیامک', onPressed: () => _sendOrderSms(o)),
                          IconButton(icon: const Icon(Icons.update, color: AppTheme.yellow), tooltip: 'تغییر وضعیت', onPressed: () => _changeStatus(o)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOrder(o['id'])),
                        ]),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
          if (result == true) _loadOrders();
        },
        backgroundColor: AppTheme.yellow, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('سفارش جدید'),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.black : AppTheme.yellow, fontSize: 12)),
        selected: isSelected,
        onSelected: (_) { setState(() => _statusFilter = value); _applyFilters(); },
        selectedColor: AppTheme.yellow,
        backgroundColor: AppTheme.cardBlack,
        checkmarkColor: Colors.black,
        side: const BorderSide(color: AppTheme.yellow),
      ),
    );
  }
}

// ===== صفحه ساخت سفارش =====
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _frames = [];
  List<Map<String, dynamic>> _lenses = [];
  List<Map<String, dynamic>> _exams = [];

  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedFrame;
  Map<String, dynamic>? _selectedLens;
  Map<String, dynamic>? _latestExam;
  
  Jalali _orderDate = Jalali.now();
  final _deliveryController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // فیلدهای نسخه
  final _sphRController = TextEditingController(text: '0');
  final _cylRController = TextEditingController(text: '0');
  final _axisRController = TextEditingController(text: '0');
  final _addRController = TextEditingController(text: '0');
  final _sphLController = TextEditingController(text: '0');
  final _cylLController = TextEditingController(text: '0');
  final _axisLController = TextEditingController(text: '0');
  final _addLController = TextEditingController(text: '0');
  final _pdController = TextEditingController(text: '0');

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await DatabaseHelper.instance.getAllCustomers();
      final frames = await DatabaseHelper.instance.getAllFrames();
      final lenses = await DatabaseHelper.instance.getAllLenses();
      final exams = await DatabaseHelper.instance.getAllEyeExams();
      if (mounted) {
        setState(() {
          _customers = customers;
          _frames = frames;
          _lenses = lenses;
          _exams = exams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _loadCustomerExam() {
    if (_selectedCustomer == null) return;
    final customerId = _selectedCustomer!['id'];
    final customerExams = _exams.where((e) => e['customer_id'] == customerId).toList();
    if (customerExams.isNotEmpty) {
      setState(() {
        _latestExam = customerExams.first;
        _sphRController.text = _latestExam!['sph_right'].toString();
        _cylRController.text = _latestExam!['cyl_right'].toString();
        _axisRController.text = _latestExam!['axis_right'].toString();
        _addRController.text = _latestExam!['add_right'].toString();
        _sphLController.text = _latestExam!['sph_left'].toString();
        _cylLController.text = _latestExam!['cyl_left'].toString();
        _axisLController.text = _latestExam!['axis_left'].toString();
        _addLController.text = _latestExam!['add_left'].toString();
        _pdController.text = _latestExam!['pd'].toString();
      });
    }
  }

  double get _subtotal {
    double total = 0;
    if (_selectedFrame != null) total += (_selectedFrame!['sell_price'] ?? 0).toDouble();
    if (_selectedLens != null) total += (_selectedLens!['sell_price'] ?? 0).toDouble();
    return total;
  }

  double get _discount => double.tryParse(toEnglishDigits(_discountController.text.replaceAll(',', ''))) ?? 0;
  double get _total => _subtotal - _discount;

  Future<void> _saveOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مشتری را انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedFrame == null && _selectedLens == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک فریم یا عدسی انتخاب کنید'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final orderNumber = await generateDailyOrderNumber();
      final dateStr = '${_orderDate.year}/${_orderDate.month.toString().padLeft(2, '0')}/${_orderDate.day.toString().padLeft(2, '0')}';

      await DatabaseHelper.instance.insertOrder({
        'order_number': orderNumber,
        'customer_id': _selectedCustomer!['id'],
        'employee_id': null,
        'order_date': dateStr,
        'delivery_date': _deliveryController.text.trim(),
        'status': 'pending',
        'frame_id': _selectedFrame?['id'],
        'lens_id': _selectedLens?['id'],
        'sph_right': double.tryParse(_sphRController.text) ?? 0,
        'cyl_right': double.tryParse(_cylRController.text) ?? 0,
        'axis_right': int.tryParse(_axisRController.text) ?? 0,
        'sph_left': double.tryParse(_sphLController.text) ?? 0,
        'cyl_left': double.tryParse(_cylLController.text) ?? 0,
        'axis_left': int.tryParse(_axisLController.text) ?? 0,
        'add_value': double.tryParse(_addRController.text) ?? 0,
        'pd': double.tryParse(_pdController.text) ?? 0,
        'subtotal': _subtotal,
        'discount': _discount,
        'total': _total,
        'is_credit': 0,
        'warranty_date': null,
        'notes': _notesController.text.trim(),
        'created_at': getCurrentJalaliDateTime(),
      });

      // کاهش موجودی
      if (_selectedFrame != null) {
        final newStock = (_selectedFrame!['stock_quantity'] ?? 0) - 1;
        await DatabaseHelper.instance.updateFrame(_selectedFrame!['id'], {'stock_quantity': newStock < 0 ? 0 : newStock});
      }
      if (_selectedLens != null) {
        final newStock = (_selectedLens!['stock_quantity'] ?? 0) - 1;
        await DatabaseHelper.instance.updateLens(_selectedLens!['id'], {'stock_quantity': newStock < 0 ? 0 : newStock});
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ سفارش $orderNumber ثبت شد'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سفارش جدید'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // مشتری
                  const Text('۱. انتخاب مشتری', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.yellow)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCustomer,
                    dropdownColor: AppTheme.cardBlack,
                    decoration: const InputDecoration(labelText: 'مشتری *', prefixIcon: Icon(Icons.person, color: AppTheme.yellow)),
                    items: _customers.map((c) => DropdownMenuItem<Map<String, dynamic>>(value: c, child: Text('${c['name']} - ${c['phone'] ?? '-'}', style: const TextStyle(color: AppTheme.textWhite)))).toList(),
                    onChanged: (v) { setState(() => _selectedCustomer = v); _loadCustomerExam(); },
                  ),
                  if (_latestExam != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.green)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('✓ آخرین نسخه معاینه بارگذاری شد', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('تاریخ معاینه: ${_latestExam!['exam_date']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // نسخه چشم
                  const Text('۲. نسخه چشم (قابل ویرایش)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.yellow)),
                  const SizedBox(height: 8),
                  const Text('چشم راست (OD)', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold)),
                  Row(children: [
                    Expanded(child: TextField(controller: _sphRController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'SPH'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _cylRController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'CYL'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _axisRController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'AXIS'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _addRController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ADD'))),
                  ]),
                  const SizedBox(height: 8),
                  const Text('چشم چپ (OS)', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold)),
                  Row(children: [
                    Expanded(child: TextField(controller: _sphLController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'SPH'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _cylLController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'CYL'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _axisLController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'AXIS'))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _addLController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ADD'))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: _pdController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'فاصله مردمک (PD)', prefixIcon: Icon(Icons.straighten, color: AppTheme.yellow))),
                  const SizedBox(height: 16),

                  // فریم
                  const Text('۳. انتخاب فریم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.yellow)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedFrame,
                    dropdownColor: AppTheme.cardBlack,
                    decoration: const InputDecoration(labelText: 'فریم', prefixIcon: Icon(Icons.style, color: AppTheme.yellow)),
                    items: _frames.where((f) => (f['stock_quantity'] ?? 0) > 0).map((f) => DropdownMenuItem<Map<String, dynamic>>(value: f, child: Text('${f['name']} - ${formatPrice(f['sell_price'])} تومان', style: const TextStyle(color: AppTheme.textWhite)))).toList(),
                    onChanged: (v) => setState(() => _selectedFrame = v),
                  ),
                  const SizedBox(height: 16),

                  // عدسی
                  const Text('۴. انتخاب عدسی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.yellow)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedLens,
                    dropdownColor: AppTheme.cardBlack,
                    decoration: const InputDecoration(labelText: 'عدسی', prefixIcon: Icon(Icons.lens_blur, color: AppTheme.yellow)),
                    items: _lenses.where((l) => (l['stock_quantity'] ?? 0) > 0).map((l) => DropdownMenuItem<Map<String, dynamic>>(value: l, child: Text('${l['name']} - ${formatPrice(l['sell_price'])} تومان', style: const TextStyle(color: AppTheme.textWhite)))).toList(),
                    onChanged: (v) => setState(() => _selectedLens = v),
                  ),
                  const SizedBox(height: 16),

                  // تاریخ
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showPersianDatePicker(context: context, initialDate: _orderDate, firstDate: Jalali(1400), lastDate: Jalali(1450));
                      if (picked != null) setState(() => _orderDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, color: AppTheme.yellow),
                    label: Text('تاریخ سفارش: ${_orderDate.year}/${_orderDate.month.toString().padLeft(2, '0')}/${_orderDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textWhite)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.yellow)),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _deliveryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تاریخ تحویل (اختیاری)', prefixIcon: Icon(Icons.event, color: AppTheme.yellow))),
                  const SizedBox(height: 12),
                  TextField(controller: _discountController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تخفیف (تومان)', prefixIcon: Icon(Icons.discount, color: AppTheme.yellow))),
                  const SizedBox(height: 12),
                  TextField(controller: _notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.yellow))),
                  const SizedBox(height: 16),

                  // جمع کل
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 2)),
                    child: Column(children: [
                      Row(children: [const Text('فریم:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice((_selectedFrame?['sell_price'] ?? 0).toInt())} تومان', style: const TextStyle(color: AppTheme.textWhite))]),
                      const SizedBox(height: 8),
                      Row(children: [const Text('عدسی:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice((_selectedLens?['sell_price'] ?? 0).toInt())} تومان', style: const TextStyle(color: AppTheme.textWhite))]),
                      const SizedBox(height: 8),
                      Row(children: [const Text('تخفیف:', style: TextStyle(color: AppTheme.textGrey)), const Spacer(), Text('${formatPrice(_discount.toInt())} تومان', style: const TextStyle(color: Colors.red))]),
                      const Divider(color: AppTheme.yellow, height: 20),
                      Row(children: [const Text('مبلغ نهایی:', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold, fontSize: 18)), const Spacer(), Text('${formatPrice(_total.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 20))]),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // دکمه ثبت
                  SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                      onPressed: _isSaving ? null : _saveOrder,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                      label: Text(_isSaving ? 'در حال ثبت...' : 'ثبت سفارش', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}