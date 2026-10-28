import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class EyeExamsScreen extends StatefulWidget {
  const EyeExamsScreen({super.key});
  @override
  State<EyeExamsScreen> createState() => _EyeExamsScreenState();
}

class _EyeExamsScreenState extends State<EyeExamsScreen> {
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final exams = await DatabaseHelper.instance.getAllEyeExams();
    final customers = await DatabaseHelper.instance.getAllCustomers();
    setState(() { _exams = exams; _filtered = exams; _customers = customers; _isLoading = false; });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) { _filtered = _exams; } 
      else {
        _filtered = _exams.where((e) => (e['customer_name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (e['doctor_name'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _showExamDialog({Map<String, dynamic>? exam}) async {
    final isEdit = exam != null;
    int? selectedCustomerId = isEdit ? (exam!['customer_id'] as int?) : (_customers.isNotEmpty ? (_customers.first['id'] as int?) : null);
    
    final doctorController = TextEditingController(text: exam?['doctor_name']?.toString() ?? '');
    final sphRController = TextEditingController(text: (exam?['sph_right'] ?? 0).toString());
    final cylRController = TextEditingController(text: (exam?['cyl_right'] ?? 0).toString());
    final axisRController = TextEditingController(text: (exam?['axis_right'] ?? 0).toString());
    final addRController = TextEditingController(text: (exam?['add_right'] ?? 0).toString());
    
    final sphLController = TextEditingController(text: (exam?['sph_left'] ?? 0).toString());
    final cylLController = TextEditingController(text: (exam?['cyl_left'] ?? 0).toString());
    final axisLController = TextEditingController(text: (exam?['axis_left'] ?? 0).toString());
    final addLController = TextEditingController(text: (exam?['add_left'] ?? 0).toString());
    final pdController = TextEditingController(text: (exam?['pd'] ?? 0).toString());
    
    String visionType = exam?['vision_type']?.toString() ?? 'emmetropia';
    String glassesType = exam?['glasses_type']?.toString() ?? 'single';
    final notesController = TextEditingController(text: exam?['notes']?.toString() ?? '');
    
    Jalali examDate = exam?['exam_date'] != null ? (_parseJalali(exam!['exam_date']) ?? Jalali.now()) : Jalali.now();
    Jalali nextExamDate = exam?['next_exam_date'] != null ? (_parseJalali(exam!['next_exam_date']) ?? Jalali.now().addYears(1)) : Jalali.now().addYears(1);

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش معاینه' : 'ثبت معاینه جدید', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  value: selectedCustomerId,
                  dropdownColor: AppTheme.cardBlack,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'انتخاب مشتری *', prefixIcon: Icon(Icons.person, color: AppTheme.yellow)),
                  items: _customers.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name']?.toString() ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                  )).toList(),
                  onChanged: (v) => setStateDialog(() => selectedCustomerId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: doctorController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام پزشک / اپتومتریست', prefixIcon: Icon(Icons.medical_services, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await showPersianDatePicker(context: ctx, initialDate: examDate, firstDate: Jalali(1400), lastDate: Jalali(1450)); if (p != null) setStateDialog(() => examDate = p); }, icon: const Icon(Icons.calendar_today, color: AppTheme.yellow, size: 18), label: Text('معاینه: ${examDate.year}/${examDate.month}/${examDate.day}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 11)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.yellow)))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await showPersianDatePicker(context: ctx, initialDate: nextExamDate, firstDate: Jalali(1400), lastDate: Jalali(1450)); if (p != null) setStateDialog(() => nextExamDate = p); }, icon: const Icon(Icons.event_available, color: AppTheme.green, size: 18), label: Text('بعدی: ${nextExamDate.year}/${nextExamDate.month}/${nextExamDate.day}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 11)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.green)))),
                ]),
                const SizedBox(height: 16),
                const Text('چشم راست (OD)', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: sphRController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'SPH', hintText: '0.00'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: cylRController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'CYL', hintText: '0.00'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: axisRController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'AXIS', hintText: '0'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: addRController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ADD', hintText: '0.00'))),
                ]),
                const SizedBox(height: 16),
                const Text('چشم چپ (OS)', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: sphLController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'SPH', hintText: '0.00'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: cylLController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'CYL', hintText: '0.00'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: axisLController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'AXIS', hintText: '0'))),
                  const SizedBox(width: 4),
                  Expanded(child: TextField(controller: addLController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ADD', hintText: '0.00'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: pdController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'فاصله مردمک (PD)', prefixIcon: Icon(Icons.straighten, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: visionType,
                    dropdownColor: AppTheme.cardBlack,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'نوع دید', prefixIcon: Icon(Icons.visibility, color: AppTheme.yellow)),
                    items: const [
                      DropdownMenuItem(value: 'emmetropia', child: Text('نرمال')),
                      DropdownMenuItem(value: 'myopia', child: Text('نزدیک‌بین')),
                      DropdownMenuItem(value: 'hyperopia', child: Text('دوربین')),
                      DropdownMenuItem(value: 'astigmatism', child: Text('آستیگمات')),
                      DropdownMenuItem(value: 'presbyopia', child: Text('پیرچشمی')),
                    ],
                    onChanged: (v) => setStateDialog(() => visionType = v!),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: glassesType,
                    dropdownColor: AppTheme.cardBlack,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'نوع عینک', prefixIcon: Icon(Icons.style, color: AppTheme.yellow)), // اصلاح: Icons.style جایگزین Icons.glasses
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('تک‌کانونی')),
                      DropdownMenuItem(value: 'bifocal', child: Text('دوکانونی')),
                      DropdownMenuItem(value: 'progressive', child: Text('تدریجی')),
                      DropdownMenuItem(value: 'reading', child: Text('مطالعه')),
                    ],
                    onChanged: (v) => setStateDialog(() => glassesType = v!),
                  )),
                ]),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت‌های پزشکی', prefixIcon: Icon(Icons.notes, color: AppTheme.yellow))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  if (selectedCustomerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً یک مشتری انتخاب کنید'), backgroundColor: Colors.red));
                    return;
                  }
                  final data = {
                    'customer_id': selectedCustomerId,
                    'doctor_name': doctorController.text.trim(),
                    'exam_date': '${examDate.year}/${examDate.month.toString().padLeft(2, '0')}/${examDate.day.toString().padLeft(2, '0')}',
                    'next_exam_date': '${nextExamDate.year}/${nextExamDate.month.toString().padLeft(2, '0')}/${nextExamDate.day.toString().padLeft(2, '0')}',
                    'sph_right': double.tryParse(toEnglishDigits(sphRController.text)) ?? 0,
                    'cyl_right': double.tryParse(toEnglishDigits(cylRController.text)) ?? 0,
                    'axis_right': int.tryParse(toEnglishDigits(axisRController.text)) ?? 0,
                    'add_right': double.tryParse(toEnglishDigits(addRController.text)) ?? 0,
                    'sph_left': double.tryParse(toEnglishDigits(sphLController.text)) ?? 0,
                    'cyl_left': double.tryParse(toEnglishDigits(cylLController.text)) ?? 0,
                    'axis_left': int.tryParse(toEnglishDigits(axisLController.text)) ?? 0,
                    'add_left': double.tryParse(toEnglishDigits(addLController.text)) ?? 0,
                    'pd': double.tryParse(toEnglishDigits(pdController.text)) ?? 0,
                    'vision_type': visionType,
                    'glasses_type': glassesType,
                    'notes': notesController.text.trim(),
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) { await DatabaseHelper.instance.updateEyeExam(exam!['id'], data); } 
                  else { await DatabaseHelper.instance.insertEyeExam(data); }
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: Text(isEdit ? 'ذخیره' : 'ثبت معاینه', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Jalali? _parseJalali(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return Jalali(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) { return null; }
  }

  Future<void> _deleteExam(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)),
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) { await DatabaseHelper.instance.deleteEyeExam(id); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('معاینات چشم'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadData)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController, style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(hintText: 'جستجو بر اساس نام مشتری یا پزشک...', prefixIcon: const Icon(Icons.search, color: AppTheme.yellow), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.yellow), onPressed: () { _searchController.clear(); _filter(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.visibility, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('معاینه‌ای ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final e = _filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: AppTheme.yellow.withOpacity(0.2), child: const Icon(Icons.visibility, color: AppTheme.yellow)),
                              title: Text(e['customer_name'] ?? 'مشتری حذف شده', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('پزشک: ${e['doctor_name'] ?? '-'} | تاریخ: ${e['exam_date'] ?? '-'}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('OD: SPH ${e['sph_right']} | CYL ${e['cyl_right']} | AXIS ${e['axis_right']}', style: const TextStyle(color: AppTheme.textYellow, fontSize: 11, fontFamily: 'monospace')),
                                  Text('OS: SPH ${e['sph_left']} | CYL ${e['cyl_left']} | AXIS ${e['axis_left']}', style: const TextStyle(color: AppTheme.textYellow, fontSize: 11, fontFamily: 'monospace')),
                                ],
                              ),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit, color: AppTheme.yellow), onPressed: () => _showExamDialog(exam: e)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExam(e['id'])),
                              ]),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_customers.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا یک مشتری ثبت کنید'), backgroundColor: Colors.red));
            return;
          }
          _showExamDialog();
        },
        backgroundColor: AppTheme.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ثبت معاینه'),
      ),
    );
  }
}