import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('homa_glass.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // مشتریان
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        national_id TEXT,
        address TEXT,
        birth_date TEXT,
        gender TEXT DEFAULT 'male',
        job TEXT,
        medical_history TEXT,
        total_debt REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // معاینات چشم
    await db.execute('''
      CREATE TABLE eye_exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        doctor_name TEXT,
        exam_date TEXT,
        next_exam_date TEXT,
        sph_right REAL DEFAULT 0, cyl_right REAL DEFAULT 0, axis_right INTEGER DEFAULT 0, add_right REAL DEFAULT 0,
        sph_left REAL DEFAULT 0, cyl_left REAL DEFAULT 0, axis_left INTEGER DEFAULT 0, add_left REAL DEFAULT 0,
        pd REAL DEFAULT 0,
        vision_type TEXT,
        glasses_type TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // فریم‌ها
    await db.execute('''
      CREATE TABLE frames (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, brand TEXT, model TEXT, color TEXT, material TEXT, size TEXT, cost_price REAL DEFAULT 0, sell_price REAL DEFAULT 0, stock_quantity INTEGER DEFAULT 0, image_path TEXT, created_at TEXT)
    ''');

    // عدسی‌ها
    await db.execute('''
      CREATE TABLE lenses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT, features TEXT, brand TEXT, lens_index TEXT, cost_price REAL DEFAULT 0, sell_price REAL DEFAULT 0, stock_quantity INTEGER DEFAULT 0, created_at TEXT)
    ''');

    // عینک‌های آفتابی
    await db.execute('''
      CREATE TABLE sunglasses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, brand TEXT, model TEXT, color TEXT, uv_protection TEXT, cost_price REAL DEFAULT 0, sell_price REAL DEFAULT 0, stock_quantity INTEGER DEFAULT 0, image_path TEXT, created_at TEXT)
    ''');

    // لنزهای تماسی
    await db.execute('''
      CREATE TABLE contact_lenses (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, brand TEXT, type TEXT, power REAL DEFAULT 0, cost_price REAL DEFAULT 0, sell_price REAL DEFAULT 0, stock_quantity INTEGER DEFAULT 0, created_at TEXT)
    ''');

    // سفارشات
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT UNIQUE,
        customer_id INTEGER,
        employee_id INTEGER,
        order_date TEXT,
        delivery_date TEXT,
        status TEXT DEFAULT 'pending',
        frame_id INTEGER, lens_id INTEGER,
        sph_right REAL DEFAULT 0, cyl_right REAL DEFAULT 0, axis_right INTEGER DEFAULT 0,
        sph_left REAL DEFAULT 0, cyl_left REAL DEFAULT 0, axis_left INTEGER DEFAULT 0,
        add_value REAL DEFAULT 0, pd REAL DEFAULT 0,
        subtotal REAL DEFAULT 0, discount REAL DEFAULT 0, total REAL DEFAULT 0,
        is_credit INTEGER DEFAULT 0,
        warranty_date TEXT, notes TEXT, created_at TEXT
      )
    ''');

    // کارمندان
    await db.execute('''
      CREATE TABLE employees (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, password TEXT, role TEXT DEFAULT 'seller', commission_rate REAL DEFAULT 0.0, base_salary REAL DEFAULT 0.0, status TEXT DEFAULT 'active', created_at TEXT)
    ''');

    // تامین‌کنندگان (جدید برای نسیه مرکز)
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_debt REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // اقساط و پرداخت‌ها (جدید برای مدیریت نسیه)
    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT, // 'customer' or 'supplier'
        reference_id INTEGER, // customer_id or supplier_id
        amount REAL,
        date TEXT,
        description TEXT,
        is_paid INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // هزینه‌ها
    await db.execute('CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, description TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE expense_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
    await db.execute('INSERT INTO expense_categories (name) VALUES ("خرید کالا"), ("حقوق"), ("اجاره"), ("قبوض"), ("تعمیرات"), ("تبلیغات"), ("سایر")');

    // پلن‌ها و لایسنس
    await db.execute('CREATE TABLE plans (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, duration_value INTEGER NOT NULL, duration_type TEXT DEFAULT "months", price REAL NOT NULL, max_employees INTEGER NOT NULL, max_customers INTEGER NOT NULL, is_active INTEGER DEFAULT 1, created_at TEXT)');
    await db.execute('CREATE TABLE licenses (id INTEGER PRIMARY KEY AUTOINCREMENT, shop_name TEXT NOT NULL, device_id TEXT NOT NULL, license_code TEXT NOT NULL, plan_id INTEGER NOT NULL, plan_name TEXT NOT NULL, expiry_date TEXT NOT NULL, issued_at TEXT)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE customers ADD COLUMN total_debt REAL DEFAULT 0');
      await db.execute('CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, address TEXT, total_debt REAL DEFAULT 0, notes TEXT, created_at TEXT)');
      await db.execute('CREATE TABLE installments (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, reference_id INTEGER, amount REAL, date TEXT, description TEXT, is_paid INTEGER DEFAULT 1, created_at TEXT)');
      await db.execute('ALTER TABLE orders ADD COLUMN is_credit INTEGER DEFAULT 0');
    }
  }

  // مشتریان
  Future<int> insertCustomer(Map<String, dynamic> c) async { final db = await instance.database; return await db.insert('customers', c); }
  Future<List<Map<String, dynamic>>> getAllCustomers() async { final db = await instance.database; return await db.query('customers', orderBy: 'id DESC'); }
  Future<int> updateCustomer(int id, Map<String, dynamic> c) async { final db = await instance.database; return await db.update('customers', c, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteCustomer(int id) async { final db = await instance.database; return await db.delete('customers', where: 'id = ?', whereArgs: [id]); }

  // معاینات
  Future<int> insertEyeExam(Map<String, dynamic> e) async { final db = await instance.database; return await db.insert('eye_exams', e); }
  Future<List<Map<String, dynamic>>> getAllEyeExams() async { final db = await instance.database; return await db.rawQuery('SELECT e.*, c.name as customer_name, c.phone as customer_phone FROM eye_exams e LEFT JOIN customers c ON e.customer_id = c.id ORDER BY e.id DESC'); }
  Future<List<Map<String, dynamic>>> getEyeExamsByCustomer(int customerId) async { final db = await instance.database; return await db.query('eye_exams', where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'id DESC'); }
  Future<int> updateEyeExam(int id, Map<String, dynamic> e) async { final db = await instance.database; return await db.update('eye_exams', e, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteEyeExam(int id) async { final db = await instance.database; return await db.delete('eye_exams', where: 'id = ?', whereArgs: [id]); }

  // فریم‌ها
  Future<int> insertFrame(Map<String, dynamic> f) async { final db = await instance.database; return await db.insert('frames', f); }
  Future<List<Map<String, dynamic>>> getAllFrames() async { final db = await instance.database; return await db.query('frames', orderBy: 'id DESC'); }
  Future<int> updateFrame(int id, Map<String, dynamic> f) async { final db = await instance.database; return await db.update('frames', f, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteFrame(int id) async { final db = await instance.database; return await db.delete('frames', where: 'id = ?', whereArgs: [id]); }

  // عدسی‌ها
  Future<int> insertLens(Map<String, dynamic> l) async { final db = await instance.database; return await db.insert('lenses', l); }
  Future<List<Map<String, dynamic>>> getAllLenses() async { final db = await instance.database; return await db.query('lenses', orderBy: 'id DESC'); }
  Future<int> updateLens(int id, Map<String, dynamic> l) async { final db = await instance.database; return await db.update('lenses', l, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteLens(int id) async { final db = await instance.database; return await db.delete('lenses', where: 'id = ?', whereArgs: [id]); }

  // عینک آفتابی
  Future<int> insertSunglass(Map<String, dynamic> s) async { final db = await instance.database; return await db.insert('sunglasses', s); }
  Future<List<Map<String, dynamic>>> getAllSunglasses() async { final db = await instance.database; return await db.query('sunglasses', orderBy: 'id DESC'); }
  Future<int> updateSunglass(int id, Map<String, dynamic> s) async { final db = await instance.database; return await db.update('sunglasses', s, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteSunglass(int id) async { final db = await instance.database; return await db.delete('sunglasses', where: 'id = ?', whereArgs: [id]); }

  // لنز تماسی
  Future<int> insertContactLens(Map<String, dynamic> c) async { final db = await instance.database; return await db.insert('contact_lenses', c); }
  Future<List<Map<String, dynamic>>> getAllContactLenses() async { final db = await instance.database; return await db.query('contact_lenses', orderBy: 'id DESC'); }
  Future<int> updateContactLens(int id, Map<String, dynamic> c) async { final db = await instance.database; return await db.update('contact_lenses', c, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteContactLens(int id) async { final db = await instance.database; return await db.delete('contact_lenses', where: 'id = ?', whereArgs: [id]); }

  // سفارشات
  Future<int> insertOrder(Map<String, dynamic> o) async { final db = await instance.database; return await db.insert('orders', o); }
  Future<List<Map<String, dynamic>>> getAllOrders() async { final db = await instance.database; return await db.rawQuery('SELECT o.*, c.name as customer_name, c.phone as customer_phone, e.name as employee_name, f.name as frame_name, l.name as lens_name FROM orders o LEFT JOIN customers c ON o.customer_id = c.id LEFT JOIN employees e ON o.employee_id = e.id LEFT JOIN frames f ON o.frame_id = f.id LEFT JOIN lenses l ON o.lens_id = l.id ORDER BY o.id DESC'); }
  Future<int> updateOrder(int id, Map<String, dynamic> o) async { final db = await instance.database; return await db.update('orders', o, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteOrder(int id) async { final db = await instance.database; return await db.delete('orders', where: 'id = ?', whereArgs: [id]); }

  // کارمندان
  Future<int> insertEmployee(Map<String, dynamic> e) async { final db = await instance.database; return await db.insert('employees', e); }
  Future<List<Map<String, dynamic>>> getAllEmployees() async { final db = await instance.database; return await db.query('employees', orderBy: 'id DESC'); }
  Future<Map<String, dynamic>?> getEmployeeByCredentials(String name, String password) async { final db = await instance.database; final result = await db.query('employees', where: 'name = ? AND password = ? AND status = "active"', whereArgs: [name, password]); return result.isNotEmpty ? result.first : null; }
  Future<int> updateEmployee(int id, Map<String, dynamic> e) async { final db = await instance.database; return await db.update('employees', e, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteEmployee(int id) async { final db = await instance.database; return await db.delete('employees', where: 'id = ?', whereArgs: [id]); }

  // تامین‌کنندگان
  Future<int> insertSupplier(Map<String, dynamic> s) async { final db = await instance.database; return await db.insert('suppliers', s); }
  Future<List<Map<String, dynamic>>> getAllSuppliers() async { final db = await instance.database; return await db.query('suppliers', orderBy: 'id DESC'); }
  Future<int> updateSupplier(int id, Map<String, dynamic> s) async { final db = await instance.database; return await db.update('suppliers', s, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteSupplier(int id) async { final db = await instance.database; return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]); }

  // اقساط و پرداخت‌ها
  Future<int> insertInstallment(Map<String, dynamic> i) async { final db = await instance.database; return await db.insert('installments', i); }
  Future<List<Map<String, dynamic>>> getInstallmentsByReference(String type, int refId) async { 
    final db = await instance.database; 
    return await db.query('installments', where: 'type = ? AND reference_id = ?', whereArgs: [type, refId], orderBy: 'id DESC'); 
  }

  // هزینه‌ها
  Future<List<Map<String, dynamic>>> getExpenseCategories() async { final db = await instance.database; return await db.query('expense_categories', orderBy: 'name ASC'); }
  Future<List<Map<String, dynamic>>> getExpenses({String? startDate, String? endDate}) async {
    final db = await instance.database;
    String where = '1=1'; List<dynamic> whereArgs = [];
    if (startDate != null) { where += ' AND date >= ?'; whereArgs.add(startDate); }
    if (endDate != null) { where += ' AND date <= ?'; whereArgs.add(endDate); }
    return await db.query('expenses', where: where, whereArgs: whereArgs, orderBy: 'id DESC');
  }
  Future<int> insertExpense(Map<String, dynamic> e) async { final db = await instance.database; return await db.insert('expenses', e); }
  Future<int> deleteExpense(int id) async { final db = await instance.database; return await db.delete('expenses', where: 'id = ?', whereArgs: [id]); }

  // پلن‌ها و لایسنس
  Future<List<Map<String, dynamic>>> getAllPlans() async { final db = await instance.database; return await db.query('plans', orderBy: 'duration_value ASC'); }
  Future<int> insertPlan(Map<String, dynamic> p) async { final db = await instance.database; return await db.insert('plans', p); }
  Future<int> insertLicense(Map<String, dynamic> l) async { final db = await instance.database; return await db.insert('licenses', l); }
  Future<List<Map<String, dynamic>>> getAllLicenses() async { final db = await instance.database; return await db.query('licenses', orderBy: 'id DESC'); }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('customers'); await db.delete('eye_exams'); await db.delete('frames');
    await db.delete('lenses'); await db.delete('sunglasses'); await db.delete('contact_lenses');
    await db.delete('orders'); await db.delete('employees'); await db.delete('suppliers');
    await db.delete('installments'); await db.delete('expenses'); await db.delete('plans'); await db.delete('licenses');
  }
}