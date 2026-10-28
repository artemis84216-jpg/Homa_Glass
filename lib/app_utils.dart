import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const Color backgroundBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color yellow = Color(0xFFFFD700);
  static const Color yellowDark = Color(0xFFFFA000);
  static const Color textWhite = Colors.white;
  static const Color textYellow = Color(0xFFFFEB3B);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF2196F3);
  static const Color eyeBlue = Color(0xFF4FC3F7);

  static ThemeData get darkYellowTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: yellow,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(primary: yellow, secondary: yellowDark, surface: cardBlack, onPrimary: Colors.black, onSurface: textWhite),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: yellow, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: yellow, fontSize: 20, fontWeight: FontWeight.bold)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: yellow, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF444444), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: yellow, width: 2)),
        labelStyle: const TextStyle(color: textGrey), hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),
    );
  }
}

String toPersianDigits(String input) {
  return input.replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲').replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵').replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸').replaceAll('9', '۹');
}

String toEnglishDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    input = input.replaceAll(persian[i], i.toString()).replaceAll(arabic[i], i.toString());
  }
  return input;
}

String formatPrice(dynamic price) {
  if (price == null) return '۰';
  final num priceNum = price is int ? price : (price is double ? price.toInt() : 0);
  String formatted = priceNum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  return toPersianDigits(formatted);
}

String formatNumber(num number) => toPersianDigits(number.toString());

String formatStock(dynamic stock) {
  final s = (stock ?? 0).toDouble();
  if (s == s.toInt()) return toPersianDigits(s.toInt().toString());
  return toPersianDigits(s.toStringAsFixed(2));
}

String getCurrentJalaliDate() {
  final now = Jalali.now();
  return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
}

String getCurrentJalaliDateTime() {
  final now = Jalali.now();
  return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

class CommaSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = toEnglishDigits(newValue.text.replaceAll(',', ''));
    if (cleanText.isEmpty) return newValue;
    final intVal = int.tryParse(cleanText);
    if (intVal == null) return oldValue;
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

// لیست نکات روزانه مرتبط با چشم و عینک
const List<String> dailyEyeCareTips = [
  '👁️ قانون ۲۰-۲۰-۲۰: هر ۲۰ دقیقه، ۲۰ ثانیه به فاصله ۲۰ فوتی نگاه کنید.',
  '🕶️ از عینک آفتابی استاندارد UV400 استفاده کنید.',
  '💧 برای جلوگیری از خشکی چشم، مرتب پلک بزنید.',
  '🥕 مصرف هویج، اسفناج و ماهی برای سلامت چشم مفید است.',
  '💤 خواب کافی (۷-۸ ساعت) برای استراحت چشم ضروری است.',
  '📱 فاصله مناسب از صفحه نمایش: حداقل ۵۰ سانتی‌متر.',
  '🔍 معاینه چشم را هر ۱ تا ۲ سال یکبار انجام دهید.',
  '💡 نور محیط کار باید مناسب و بدون خیرگی باشد.',
  '🏊 هنگام شنا از عینک شنا استفاده کنید.',
  '👓 عینک خود را با دستمال مخصوص تمیز کنید.',
  '🌞 در روزهای آفتابی حتماً از عینک آفتابی استفاده کنید.',
  '🚫 از مالیدن چشم‌ها با دست خودداری کنید.',
  '📖 هنگام مطالعه، نور کافی داشته باشید.',
  '💻 هنگام کار با کامپیوتر، هر ساعت ۵ دقیقه استراحت کنید.',
  '👁️ در صورت تاری دید ناگهانی، فوراً به پزشک مراجعه کنید.',
  '🧢 کلاه لبه‌دار در کنار عینک آفتابی، محافظت بهتری ایجاد می‌کند.',
  '🔬 عدسی‌های آنتی‌رفلکس، خستگی چشم را کاهش می‌دهند.',
  '👶 کودکان نیز به معاینه چشم منظم نیاز دارند.',
  '🌙 رانندگی در شب با عینک مناسب، ایمنی را افزایش می‌دهد.',
  '💧 نوشیدن آب کافی برای سلامت چشم‌ها ضروری است.',
  '👓 عینک خود را با دو دست بردارید تا فریم آن خراب نشود.',
  '🏥 دیابت و فشار خون می‌توانند به چشم آسیب برسانند.',
  '🔍 عینک مطالعه باید دقیقاً متناسب با نمره چشم شما باشد.',
  '👁️ لنزهای تماسی را طبق دستور پزشک استفاده کنید.',
  '🌿 کمپرس سرد برای کاهش پف و خستگی چشم مفید است.',
  '📏 فاصله مناسب مطالعه: ۳۰ تا ۴۰ سانتی‌متر.',
  '🎯 عدسی‌های تدریجی برای افراد بالای ۴۰ سال مناسب هستند.',
  '💎 عدسی‌های بلوکات، از چشم در برابر نور آبی محافظت می‌کنند.',
  '🧼 دست‌های خود را قبل از لمس چشم‌ها بشویید.',
  '🏆 سلامت چشم، سرمایه‌ای برای تمام عمر است.',
];

String getRandomDailyTip() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return dailyEyeCareTips[dayOfYear % dailyEyeCareTips.length];
}

// لیست برندهای معروف فریم
const List<String> frameBrands = [
  'Ray-Ban', 'Oakley', 'Gucci', 'Prada', 'Dior', 'Versace', 'Armani',
  'Tom Ford', 'Bulgari', 'Cartier', 'Chanel', 'Fendi', 'Dolce & Gabbana',
  'Michael Kors', 'Calvin Klein', 'Hugo Boss', 'Police', 'Safilo',
  'Marchon', 'Marcolin', 'ایرانی', 'چینی', 'ترکیه‌ای', 'ایتالیایی', 'سایر'
];

// لیست برندهای معروف عدسی
const List<String> lensBrands = [
  'Essilor', 'Hoya', 'Zeiss', 'Crizal', 'Shamir', 'Rodenstock',
  'Pentax', 'Seiko', 'Nikon', 'Tokai', 'ایرانی', 'چینی', 'کره‌ای', 'سایر'
];

// ایندکس‌های عدسی
const List<String> lensIndexes = ['1.5', '1.56', '1.59', '1.60', '1.61', '1.67', '1.74'];

// انواع عدسی
const List<String> lensTypes = ['تک‌کانونی', 'دوکانونی', 'تدریجی', 'Reading', 'Computer', 'Blue Cut', 'Photochromic'];

// ویژگی‌های عدسی
const List<String> lensFeatures = [
  'آنتی‌رفلکس', 'بلوکات', 'فتوکرومیک', 'UV400', 'ضد خش', 'ضد بخار', 'ایندکس بالا', 'سبک وزن'
];

// جنس فریم
const List<String> frameMaterials = ['فلزی', 'کائوچو', 'ترکیبی', 'تیتانیوم', 'پلاستیکی', 'چوبی', 'سایر'];
// تولید شماره سفارش روزانه
Future<String> generateDailyOrderNumber() async {
  final now = Jalali.now();
  final today = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final prefs = await SharedPreferences.getInstance();
  final lastDate = prefs.getString('last_order_date') ?? '';
  int lastCount = 0;
  if (lastDate == today) {
    lastCount = prefs.getInt('last_order_count') ?? 0;
  }
  lastCount++;
  await prefs.setString('last_order_date', today);
  await prefs.setInt('last_order_count', lastCount);
  return 'ORD-$today-${lastCount.toString().padLeft(3, '0')}';
}