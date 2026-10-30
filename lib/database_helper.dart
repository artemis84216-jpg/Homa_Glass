import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

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
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // ... (تمام جداول قبلی را اینجا نگه دارید، فقط جدول جدید زیر را اضافه کنید) ...
    await db.execute('''
      CREATE TABLE general_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        image_paths TEXT,
        created_at TEXT
      )
    ''');
    // بقیه جداول قبلی (customers, eye_exams, frames, lenses, sunglasses, contact_lenses, orders, employees, suppliers, installments, expenses, expense_categories, plans, licenses) را همانطور که بودند نگه دارید.
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // کدهای migration نسخه ۲
      try { await db.execute('ALTER TABLE customers ADD COLUMN total_debt REAL DEFAULT 0'); } catch(e){}
      try { await db.execute('CREATE TABLE suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, address TEXT, total_debt REAL DEFAULT 0, notes TEXT, created_at TEXT)'); } catch(e){}
      try { await db.execute('CREATE TABLE installments (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, reference_id INTEGER, amount REAL, date TEXT, description TEXT, is_paid INTEGER DEFAULT 1, created_at TEXT)'); } catch(e){}
      try { await db.execute('ALTER TABLE orders ADD COLUMN is_credit INTEGER DEFAULT 0'); } catch(e){}
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE general_info (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          image_paths TEXT,
          created_at TEXT
        )
      ''');
    }
  }

  // ... (تمام متدهای قبلی را نگه دارید و این متدهای جدید را به انتهای کلاس اضافه کنید) ...

  // متدهای اطلاعات عمومی
  Future<int> insertGeneralInfo(Map<String, dynamic> info) async { 
    final db = await instance.database; 
    return await db.insert('general_info', info); 
  }
  Future<List<Map<String, dynamic>>> getAllGeneralInfo() async { 
    final db = await instance.database; 
    return await db.query('general_info', orderBy: 'id DESC'); 
  }
  Future<int> updateGeneralInfo(int id, Map<String, dynamic> info) async { 
    final db = await instance.database; 
    return await db.update('general_info', info, where: 'id = ?', whereArgs: [id]); 
  }
  Future<int> deleteGeneralInfo(int id) async { 
    final db = await instance.database; 
    return await db.delete('general_info', where: 'id = ?', whereArgs: [id]); 
  }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('customers'); await db.delete('eye_exams'); await db.delete('frames');
    await db.delete('lenses'); await db.delete('sunglasses'); await db.delete('contact_lenses');
    await db.delete('orders'); await db.delete('employees'); await db.delete('suppliers');
    await db.delete('installments'); await db.delete('expenses'); await db.delete('plans'); 
    await db.delete('licenses'); await db.delete('general_info');
  }
}