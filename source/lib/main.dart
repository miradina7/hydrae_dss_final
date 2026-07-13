import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

// Notifier global untuk mengawal mod cerah/gelap aplikasi secara masa-nyata
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

void main() {
  runApp(const HydraeApp());
}

class HydraeApp extends StatelessWidget {
  const HydraeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Hydrae',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // 1. TEMA CERAH (LIGHT MODE)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F7F6),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00838F),
              secondary: Color(0xFF00796B),
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                letterSpacing: 1.2,
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00838F),
              ),
              bodyLarge: TextStyle(color: Color(0xFF374151)),
            ),
            cardTheme: ThemeData().cardTheme.copyWith(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black12,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00838F),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // 2. TEMA GELAP PREMIUM (DARK MODE)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(
              0xFF0B0F19,
            ), // Hitam Slate Midnight
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF), // Neon Cyan
              secondary: Color(0xFF00796B),
              surface: Color(0xFF1F2937), // Kotak kelabu gelap premium
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E5FF),
              ),
              bodyLarge: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withOpacity(0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00E5FF),
                  width: 1.5,
                ),
              ),
            ),
          ),
          home: const MainNavigationController(),
        );
      },
    );
  }
}

// ==========================================
// KELAS MODEL DATA & SISTEM AKUAKULTUR
// ==========================================

class SystemConfig {
  final String name;
  final String type; // Kolam, Sangkar, Tangki
  final String waterType; // Air Tawar, Air Payau, Air Masin
  final double length;
  final double width;
  final double depth;
  final String speciesType; // Ikan, Udang, Ketam
  final String speciesName; // e.g. Patin, Tilapia
  final int quantity;
  final String culturePhase; // Larva, Benih, Dewasa

  SystemConfig({
    required this.name,
    required this.type,
    required this.waterType,
    required this.length,
    required this.width,
    required this.depth,
    required this.speciesType,
    required this.speciesName,
    required this.quantity,
    required this.culturePhase,
  });
}

class FarmLog {
  final DateTime timestamp;
  final double temp;
  final double ph; // Mapped directly to ph scale [1, 2]
  final double doLevel;
  final double ammonia;
  final double riskScore;
  final String dssStatus;

  FarmLog({
    required this.timestamp,
    required this.temp,
    required this.ph,
    required this.doLevel,
    required this.ammonia,
    required this.riskScore,
    required this.dssStatus,
  });
}

enum AppScreen {
  welcome,
  phoneInput,
  otpVerification,
  setupProfile,
  systemDetail,
  mainApp,
}

// ==========================================
// HASIL DAN DEFINISI RULE MAMDANI
// ==========================================

class FuzzyResult {
  final double score;
  final bool noRulesActive;
  final Map<int, double> ruleStrengths;
  final double stableStrength;
  final double warningStrength;
  final double criticalStrength;
  final String recommendation;

  const FuzzyResult({
    required this.score,
    required this.noRulesActive,
    required this.ruleStrengths,
    required this.stableStrength,
    required this.warningStrength,
    required this.criticalStrength,
    required this.recommendation,
  });
}

class FuzzyRuleInfo {
  final String category;
  final String recommendation;

  const FuzzyRuleInfo(this.category, this.recommendation);
}

const Map<int, FuzzyRuleInfo> _ruleDefinitions = {
  1: FuzzyRuleInfo('Stable', 'Continue normal operation'),
  2: FuzzyRuleInfo('Stable', 'Continue normal operation'),
  3: FuzzyRuleInfo('Stable', 'Continue normal operation'),
  4: FuzzyRuleInfo('Stable', 'Continue normal operation'),
  5: FuzzyRuleInfo('Stable', 'Continue normal operation'),
  6: FuzzyRuleInfo('Warning', 'Monitor water quality'),
  7: FuzzyRuleInfo('Warning', 'Monitor water quality'),
  8: FuzzyRuleInfo('Warning', 'Monitor water quality'),
  9: FuzzyRuleInfo('Warning', 'Reduce feeding'),
  10: FuzzyRuleInfo('Warning', 'Reduce feeding'),
  11: FuzzyRuleInfo('Warning', 'Check pH adjustment'),
  12: FuzzyRuleInfo('Warning', 'Check pH adjustment'),
  13: FuzzyRuleInfo('Warning', 'Check pH adjustment'),
  14: FuzzyRuleInfo('Critical', 'Increase aeration'),
  15: FuzzyRuleInfo('Critical', 'Increase aeration'),
  16: FuzzyRuleInfo('Critical', 'Delay feeding'),
  17: FuzzyRuleInfo('Critical', 'Reduce feeding'),
  18: FuzzyRuleInfo('Warning', 'Perform water exchange if suitable'),
  19: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  20: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  21: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  22: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  23: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  24: FuzzyRuleInfo('Warning', 'Avoid water exchange'),
  25: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  26: FuzzyRuleInfo('Warning', 'Avoid water exchange'),
  27: FuzzyRuleInfo('Warning', 'Perform water exchange if suitable'),
  28: FuzzyRuleInfo('Warning', 'Perform water exchange if suitable'),
  29: FuzzyRuleInfo('Warning', 'Delay feeding'),
  30: FuzzyRuleInfo('Warning', 'Perform water exchange if suitable'),
  31: FuzzyRuleInfo('Critical', 'Warning alert / emergency action'),
  32: FuzzyRuleInfo('Warning', 'Check pH adjustment'),
  33: FuzzyRuleInfo('Warning', 'Monitor water quality'),
  34: FuzzyRuleInfo('Warning', 'Perform water exchange if suitable'),
  35: FuzzyRuleInfo('Warning', 'Reduce feeding'),
};

// ==========================================
// ENJIN LOGIK KABUR MAMDANI
// ==========================================

// Triangular membership calculation: tiga koordinat (a, b, c).
double _trimf(double x, double a, double b, double c) {
  if (x < a || x > c) return 0.0;
  if (x == b) return 1.0;
  if (x < b) return b == a ? 1.0 : (x - a) / (b - a);
  return c == b ? 1.0 : (c - x) / (c - b);
}

// Trapezoidal membership calculation: empat koordinat (a, b, c, d).
double _trapmf(double x, double a, double b, double c, double d) {
  if (x < a || x > d) return 0.0;
  if (x >= b && x <= c) return 1.0;
  if (x < b) return b == a ? 1.0 : (x - a) / (b - a);
  return d == c ? 1.0 : (d - x) / (d - c);
}

double _min6(double a, double b, double c, double d, double e, double f) {
  return math.min(a, math.min(b, math.min(c, math.min(d, math.min(e, f)))));
}

FuzzyResult _invalidFuzzyResult(String message) {
  return FuzzyResult(
    score: 0.0,
    noRulesActive: true,
    ruleStrengths: const {},
    stableStrength: 0.0,
    warningStrength: 0.0,
    criticalStrength: 0.0,
    recommendation: message,
  );
}

FuzzyResult calculateFuzzyRisk(
  double temp,
  double ph,
  double doLevel,
  String weather,
  String tide,
  String systemType,
) {
  // Validasi input kualiti air dan kategori simulasi.
  if (!temp.isFinite || !ph.isFinite || !doLevel.isFinite) {
    return _invalidFuzzyResult('Bacaan sensor tidak sah. Sila semak input.');
  }
  if (temp < 0.0 || temp > 100.0 || ph < 0.0 || ph > 14.0 || doLevel < 0.0 || doLevel > 20.0) {
    return _invalidFuzzyResult('Bacaan di luar julat sah. Sila semak input.');
  }
  if (!const ['Sunny', 'Cloudy', 'Rainy', 'Stormy'].contains(weather) ||
      !const ['Active Flow', 'Slack Tide', 'Not Applicable'].contains(tide) ||
      !const ['Kolam', 'Tangki', 'Sangkar'].contains(systemType)) {
    return _invalidFuzzyResult('Pilihan simulasi tidak sah. Sila semak input.');
  }

  // 1. Fuzzification. Koordinat luar ialah andaian implementasi daripada
  // julat kod asal; plateau 26-30 C dan DO >= 5 datang terus daripada Bab 3.
  final tLow = _trapmf(temp, 0.0, 0.0, 22.0, 26.0);
  final tOpt = _trapmf(temp, 22.0, 26.0, 30.0, 34.0);
  final tHigh = _trapmf(temp, 30.0, 34.0, 100.0, 100.0);

  final pAcidic = _trimf(ph, 0.0, 5.2, 7.2);
  final pOpt = _trimf(ph, 5.2, 7.2, 9.2);
  final pAlkaline = _trimf(ph, 7.2, 9.2, 14.0);

  final doLow = _trapmf(doLevel, 0.0, 0.0, 3.0, 5.0);
  // Moderate dikekalkan sebagai set peralihan kerana matriks 35 rules
  // membezakannya daripada Low dan High.
  final doMod = _trimf(doLevel, 3.0, 4.2, 5.4);
  final doHigh = _trapmf(doLevel, 3.0, 5.0, 20.0, 20.0);

  final wSunny = weather == 'Sunny' ? 1.0 : 0.0;
  final wCloudy = weather == 'Cloudy' || weather == 'Rainy' ? 1.0 : 0.0;
  final wStormy = weather == 'Stormy' ? 1.0 : 0.0;

  // Tide ialah don't-care bagi Tangki Konvensional; kedua-dua label diberi
  // keahlian 1 supaya pilihan pasang surut tidak mengubah hasil tangki.
  final tActive = systemType == 'Tangki'
      ? 1.0
      : (tide == 'Active Flow' || tide == 'Not Applicable' ? 1.0 : 0.0);
  final tSlack = systemType == 'Tangki' ? 1.0 : (tide == 'Slack Tide' ? 1.0 : 0.0);

  final sysPond = systemType == 'Kolam' ? 1.0 : 0.0;
  final sysTank = systemType == 'Tangki' ? 1.0 : 0.0;
  final sysCage = systemType == 'Sangkar' ? 1.0 : 0.0;
  const sysAny = 1.0;

  // 2. Semua 35 rules dinilai selari menggunakan operator MIN.
  final rules = <int, double>{
    1: _min6(tOpt, pOpt, doHigh, wSunny, tActive, sysAny),
    2: _min6(tOpt, pOpt, doHigh, wCloudy, tActive, sysAny),
    3: _min6(tOpt, pOpt, doHigh, wSunny, tSlack, sysTank),
    4: _min6(tOpt, pOpt, doHigh, wSunny, tSlack, sysPond),
    5: _min6(tOpt, pOpt, doHigh, wCloudy, tSlack, sysTank),
    6: _min6(tOpt, pOpt, doMod, wSunny, tActive, sysAny),
    7: _min6(tOpt, pOpt, doMod, wCloudy, tActive, sysAny),
    8: _min6(tOpt, pOpt, doMod, wSunny, tSlack, sysCage),
    9: _min6(tLow, pOpt, doHigh, wSunny, tActive, sysAny),
    10: _min6(tHigh, pOpt, doMod, wSunny, tActive, sysAny),
    11: _min6(tOpt, pAcidic, doHigh, wCloudy, tActive, sysAny),
    12: _min6(tOpt, pAcidic, doMod, wCloudy, tActive, sysTank),
    13: _min6(tOpt, pAlkaline, doHigh, wSunny, tActive, sysAny),
    14: _min6(tOpt, pOpt, doLow, wSunny, tActive, sysAny),
    15: _min6(tOpt, pOpt, doLow, wCloudy, tActive, sysAny),
    16: _min6(tHigh, pOpt, doLow, wSunny, tActive, sysAny),
    17: _min6(tLow, pOpt, doLow, wCloudy, tActive, sysAny),
    18: _min6(tOpt, pAlkaline, doMod, wSunny, tSlack, sysPond),
    19: _min6(tHigh, pAlkaline, doLow, wCloudy, tSlack, sysAny),
    20: _min6(tHigh, pAcidic, doLow, wCloudy, tSlack, sysAny),
    21: _min6(tLow, pAcidic, doLow, wCloudy, tSlack, sysAny),
    22: _min6(tOpt, pAlkaline, doLow, wSunny, tSlack, sysCage),
    23: _min6(tHigh, pOpt, doLow, wCloudy, tSlack, sysTank),
    24: _min6(tOpt, pOpt, doHigh, wStormy, tActive, sysPond),
    25: _min6(tOpt, pOpt, doHigh, wStormy, tActive, sysCage),
    26: _min6(tOpt, pOpt, doMod, wStormy, tSlack, sysPond),
    27: _min6(tOpt, pOpt, doHigh, wCloudy, tSlack, sysPond),
    28: _min6(tOpt, pOpt, doHigh, wSunny, tSlack, sysCage),
    29: _min6(tHigh, pOpt, doMod, wSunny, tSlack, sysCage),
    30: _min6(tOpt, pAlkaline, doMod, wSunny, tSlack, sysCage),
    31: _min6(tHigh, pAlkaline, doMod, wCloudy, tSlack, sysCage),
    32: _min6(tOpt, pAcidic, doHigh, wSunny, tActive, sysTank),
    33: _min6(tHigh, pOpt, doMod, wSunny, tActive, sysTank),
    34: _min6(tOpt, pOpt, doMod, wCloudy, tActive, sysPond),
    35: _min6(tOpt, pOpt, doHigh, wCloudy, tActive, sysTank),
  };

  // 3. Output aggregation menggunakan operator MAX.
  double maxFor(List<int> numbers) => numbers.map((n) => rules[n]!).reduce(math.max);
  final wStable = maxFor(const [1, 2, 3, 4, 5]);
  final wWarning = maxFor(const [6, 7, 8, 9, 10, 11, 12, 13, 18, 24, 26, 27, 28, 29, 30, 32, 33, 34, 35]);
  final wCritical = maxFor(const [14, 15, 16, 17, 19, 20, 21, 22, 23, 25, 31]);

  // 4. Centroid defuzzification pada domain risiko 0-100.
  double numerator = 0.0;
  double denominator = 0.0;
  for (int y = 0; y <= 100; y++) {
    final yValue = y.toDouble();
    final stable = math.min(wStable, _trimf(yValue, 0.0, 0.0, 35.0));
    final warning = math.min(wWarning, _trimf(yValue, 30.0, 50.0, 70.0));
    final critical = math.min(wCritical, _trimf(yValue, 65.0, 100.0, 100.0));
    final aggregated = math.max(stable, math.max(warning, critical));
    numerator += yValue * aggregated;
    denominator += aggregated;
  }

  // Fallback Bab 3: 0% dan minta pengguna menyemak input.
  if (denominator == 0.0) {
    return FuzzyResult(
      score: 0.0,
      noRulesActive: true,
      ruleStrengths: rules,
      stableStrength: 0.0,
      warningStrength: 0.0,
      criticalStrength: 0.0,
      recommendation: 'Tiada rule aktif. Sila semak dan sahkan input.',
    );
  }

  final maxStrength = rules.values.reduce(math.max);
  final candidates = rules.entries
      .where((entry) => (entry.value - maxStrength).abs() < 1e-9)
      .map((entry) => entry.key)
      .toList();

  int severity(String category) => category == 'Critical' ? 3 : (category == 'Warning' ? 2 : 1);
  candidates.sort((a, b) {
    final severityOrder = severity(_ruleDefinitions[b]!.category)
        .compareTo(severity(_ruleDefinitions[a]!.category));
    return severityOrder != 0 ? severityOrder : a.compareTo(b);
  });

  return FuzzyResult(
    score: numerator / denominator,
    noRulesActive: false,
    ruleStrengths: rules,
    stableStrength: wStable,
    warningStrength: wWarning,
    criticalStrength: wCritical,
    recommendation: _ruleDefinitions[candidates.first]!.recommendation,
  );
}

// ==========================================
// KONTROLLER NAVIGASI & KEADAAN UTAMA
// ==========================================

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() =>
      _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  // App State Navigation
  bool isLoggedIn = false;
  int onboardingStep = 1; // 1: Auth, 2: Setup 1, 3: Setup 2
  AppScreen activeScreen = AppScreen.welcome;
  bool isDarkMode = false; // Mengawal fungsi live dark mode aplikasi
  int currentTabIndex = 0;
  List<Map<String, dynamic>> _historicalLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  List<Map<String, dynamic>> _notifications = [];
  List<dynamic> registeredSystems = [];
  int selectedSystemIndex = 0;

  // A. FUNGSI SIMPAN REKOD DATA BARU & AUTO-TALLY NOTIFIKASI
  void addNewDataRecord({
    required double doReading,
    required double ammoniaReading,
    required double temperatureReading,
    required String dssStatus,
    required String fuzzyRisk,
  }) {
    final currentDateTime = DateTime.now();

    setState(() {
      // Masukkan entri baharu ke dalam senarai log sejarah dengan key ph [1]
      _historicalLogs.insert(0, {
        'date': currentDateTime,
        'do': doReading,
        'ammonia': ammoniaReading,
        'temperature': temperatureReading,
        'ph': phSensor, // logged ph level [1]
        'status': dssStatus,
        'risk': fuzzyRisk,
      });

      // Kemas kini senarai tapis (filter engine)
      _filteredLogs = List.from(_historicalLogs);

      // Cetus dan tambah notifikasi baharu secara automatik supaya TALLY
      _notifications.insert(0, {
        'title': 'Rekod Baru Disimpan ($fuzzyRisk)',
        'body':
            'Bacaan kualiti air baru telah berjaya dicatatkan pada jam ${currentDateTime.hour}:${currentDateTime.minute.toString().padLeft(2, '0')}. Status DSS: $dssStatus.',
        'time': 'Baru sahaja',
        'isRead': false,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data berjaya direkod & Notifikasi dikemas kini!'),
      ),
    );
  }

  // B. FUNGSI PENAPIS SEJARAH DATA MENGIKUT TARIKH
  void filterLogsByDate(DateTimeRange? pickedRange) {
    if (pickedRange == null) return;

    setState(() {
      _filteredLogs = _historicalLogs.where((log) {
        DateTime logDate = log['date'] as DateTime;
        return logDate.isAfter(
              pickedRange.start.subtract(const Duration(days: 1)),
            ) &&
            logDate.isBefore(pickedRange.end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  // C. FUNGSI EKSPORT REKOD LOG DATABASE KEPADA FAIL CSV
  Future<void> exportLogsToCSV() async {
    if (_filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiada data untuk dieksport!')),
      );
      return;
    }

    List<List<dynamic>> csvData = [
      [
        'Tarikh',
        'DO (mg/L)',
        'Ammonia (mg/L)',
        'Suhu (°C)',
        'pH Level', // ph header [1]
        'Status DSS',
        'Skor Risiko',
      ],
    ];

    for (var log in _filteredLogs) {
      csvData.add([
        log['date'].toString(),
        log['do'],
        log['ammonia'],
        log['temperature'],
        log['ph'], // ph data mapping [1]
        log['status'],
        log['risk'],
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);

    try {
      final bytes = Uint8List.fromList(utf8.encode(csvString));
      await FileSaver.instance.saveFile(
        name: 'Rekod_Ternakan_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fail CSV berjaya dieksport.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat mengeksport CSV: $error')),
      );
    }
  }

  // Profile Setup State
  String ownerName = '';
  String farmLocation = 'Sila Pilih Negeri'; // Default placeholder
  String waterType = ''; // Padam 'Air Tawar', jadikan kosong
  String systemType = ''; // Padam 'Kolam', jadikan kosong
  String shapeType = ''; // Padam 'Segi Empat', jadikan kosong
  String phoneNumber = ''; // Captures user phone number
  String verificationOTPCode = ''; // Captures what code user typed
  String generatedOTP = ''; // Stores randomized code sent by Twilio simulator
  bool isOTPLoading = false; // Controls the loading spinner state

  // Dynamic system configurations state
  final TextEditingController _systemNameCtrl = TextEditingController(
    text: 'Sistem Utama', // Tetapkan nama sistem default kepada "Sistem Utama"
  );
  double lengthValue = 0.0;
  double widthValue = 0.0;
  double depthValue = 0.0;
  final TextEditingController _speciesNameCtrl = TextEditingController(
    text: '',
  );
  final TextEditingController _quantityCtrl = TextEditingController(text: '');
  final TextEditingController _diameterCtrl = TextEditingController();
  final TextEditingController _kedalamanCtrl = TextEditingController();
  final TextEditingController _panjangCtrl = TextEditingController();
  final TextEditingController _lebarCtrl = TextEditingController();
  final TextEditingController _ammoniaCtrl = TextEditingController();
  String? speciesType; // 🔒 TUKAR KEPADA String? dan buang = 'Ikan' (Jadi null)
  String?
  culturePhase; // 🔒 TUKAR KEPADA String? dan buang = 'Dewasa' (Jadi null)

  // Live sensors state [1, 2]
  double tempSensor = 26.5;
  double phSensor = 7.2; // Changed from salinitySensor to pH Level [1]
  double doSensor = 6.5;
  double ammoniaSensor = 0.05;

  // Manual inputs for compact simulation testing [1]
  String manualWeather = 'Sunny'; // Options: Sunny, Cloudy, Rainy, Stormy [1]
  String manualTide =
      'Active Flow'; // Options: Active Flow, Slack Tide, Not Applicable [1]

  // Weather & Tide API state
  String weatherCondition = 'Sedia...';
  double weatherTemp = 28.0;
  bool isWeatherLoading = false;

  Map<String, dynamic> _createHistoricalItem(
    DateTime date,
    double temp,
    double ph,
    double doLevel,
    String weather,
    String tide,
    String systemType,
    double ammonia,
  ) {
    final result = calculateFuzzyRisk(
      temp,
      ph,
      doLevel,
      weather,
      tide,
      systemType,
    );

    final status = result.noRulesActive
        ? 'TIADA ALERTI AKTIF'
        : result.score >= 75.0
        ? 'KRITIKAL: Kualiti Air Buruk'
        : result.score >= 40.0
        ? 'AMARAN: Degradasi Sistem'
        : 'OPTIMAL: Ekosistem Stabil';

    return {
      'date': date,
      'do': doLevel,
      'ammonia': ammonia,
      'temperature': temp,
      'ph': ph,
      'status': status,
      'risk': '${result.score.toStringAsFixed(1)}%',
    };
  }

  @override
  void initState() {
    super.initState();
    _resetForm();
    _ammoniaCtrl.text = '0.05';

    // Rekod demo menggunakan pengiraan Mamdani sebenar, bukan skor hardcoded.
    _historicalLogs = [
      _createHistoricalItem(
        DateTime.now().subtract(const Duration(days: 1)),
        26.2,
        7.2,
        5.8,
        'Sunny',
        'Active Flow',
        'Kolam',
        0.32,
      ),
      _createHistoricalItem(
        DateTime.now().subtract(const Duration(days: 2)),
        29.5,
        8.8,
        5.5,
        'Cloudy',
        'Slack Tide',
        'Sangkar',
        0.65,
      ),
      _createHistoricalItem(
        DateTime.now().subtract(const Duration(days: 3)),
        25.0,
        7.0,
        6.0,
        'Sunny',
        'Active Flow',
        'Kolam',
        0.45,
      ),
      _createHistoricalItem(
        DateTime.now().subtract(const Duration(days: 4)),
        24.5,
        7.5,
        6.2,
        'Sunny',
        'Active Flow',
        'Kolam',
        0.12,
      ),
    ];

    _filteredLogs = List.from(_historicalLogs);

    _notifications = [
      {
        'title': 'Sistem Sedia Terkawal',
        'body':
            'Semua bacaan sensor dikesan stabil dan mengikut had parameter.',
        'time': '1 jam yang lalu',
        'isRead': false,
      },
    ];
  }

  @override
  void dispose() {
    _systemNameCtrl.dispose();
    _speciesNameCtrl.dispose();
    _quantityCtrl.dispose();
    _diameterCtrl.dispose();
    _kedalamanCtrl.dispose();
    _panjangCtrl.dispose();
    _lebarCtrl.dispose();
    _ammoniaCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _systemNameCtrl.text =
          'Sistem  Utama'; // Tetapkan semula nama sistem kepada "Sistem Utama"
      lengthValue = 0.0;
      widthValue = 0.0;
      depthValue = 0.0;

      // Tukar kepada null supaya dropdown kembali tunjuk 'Sila Pilih'
      speciesType = null;
      culturePhase = null;

      // Kosongkan tulisan pada kotak nama dan kuantiti/bilangan
      _speciesNameCtrl.clear();
      _quantityCtrl.clear();

      // PAKSA tulisan '10' dan '2' pada Diameter & Kedalaman hilang:
      _diameterCtrl.clear();
      _kedalamanCtrl.clear();

      // PAKSA tulisan '10' dan '2' pada Panjang & Lebar hilang:
      _panjangCtrl.clear();
      _lebarCtrl.clear();

      manualWeather = 'Sunny';
      manualTide = 'Active Flow';
    });
  }

  // Dictionary translation helper (Malay / English) - DIKUNCI KHAS UNTUK BAHASA MELAYU SAHAJA
  String _t(String key) {
    final Map<String, String> dictionary = {
      'welcome': 'Selamat Datang ke Hydrae',
      'subtitle': 'Dengan kerjasama Universiti Putra Malaysia',
      'phone_number': 'Nombor Telefon',
      'register': 'Daftar Masuk',
      'bypass_login': 'Login (Sudah mempunyai akaun?)',
      'enter_phone': 'Masukkan nombor telefon bimbit anda',
      'send_otp': 'Hantar Kod OTP',
      'verify_otp': 'Sahkan & Seterusnya',
      'otp_code': 'Sila Masukkan Kod OTP (6 digit)',
      'otp_sent_info': 'Simulasi SMS OTP: Sila masukkan kod "483921"',
      'setup_profile': 'Sediakan Profil Anda',
      'owner_name': 'Nama Pemilik / Ladang',
      'farm_location': 'Lokasi Ternakan (Negeri)',
      'water_type': 'Jenis Air',
      'system_type': 'Jenis Sistem Akuakultur',
      'next_step': 'Seterusnya',
      'mari_kenali': 'Mari kenali sistem anda',
      'dimensions': 'Ukuran Badan Air (Meter)',
      'length': 'Panjang',
      'width': 'Lebar',
      'depth': 'Kedalaman',
      'species_type': 'Jenis Ternakan',
      'species_name': 'Nama Spesies (contoh: Patin)',
      'quantity': 'Bilangan Individu (Anggaran)',
      'phase': 'Fasa Kultur',
      'add_other': 'Tambah Sistem Lain?',
      'finish_open': 'Selesai & Buka DSS',
      'nav_home': 'Utama',
      'nav_reports': 'Laporan Ternakan',
      'nav_notif': 'Notifikasi',
      'nav_account': 'Akaun',
      'weather_api': 'Automasi Cuaca Terbuka',
      'tide_api': 'Ramalan Pasang Surut',
      'water_quality_sensors': 'Sensor Kualiti Air',
      'decide_act': 'DSS: Keputusan & Tindakan',
      'risk_score': 'Skor Risiko',
      'cause': 'SEBAB',
      'impact': 'KESAN',
      'action': 'TINDAKAN',
      'save_reading': 'Simpan Pembacaan Semasa',
      'success_saved': 'Pembacaan berjaya disimpan!',
      'tides_high': 'Pasang Penuh',
      'tides_low': 'Surut Terendah',
      'change_system': 'Pilih Sistem Aktif',
      'logout': 'Log Keluar',
      'lang_settings': 'Tetapan Bahasa',
      'help_support': 'Bantuan & Sokongan',
      'notif_empty': 'Tiada amaran kritikal direkodkan buat masa ini.',
      'reports_title': 'Analisis & Trend Sistem',
      'averages': 'Purata Sepanjang Tempoh Dipilih',
      'export_csv': 'Eksport Data',
      'historical_logs': 'Log Sejarah Pembacaan Raw',
      'system_list': 'Senarai Sistem Anda',
      'temp_lbl': 'Suhu (°C)',
      'ph_lbl':
          'Tahap pH', // salinity_lbl Keasinan (ppt) -> ph_lbl Tahap pH [1]
      'do_lbl': 'Oksigen Terlarut (mg/L)',
      'ammonia_lbl': 'Ammonia (ppm)',
    };
    return dictionary[key] ?? key;
  }

  // OpenWeather kekal sebagai paparan konteks dan tidak memasuki enjin fuzzy.
  Future<void> _fetchWeatherAutomated(String state) async {
    setState(() {
      isWeatherLoading = true;
    });

    // 💡 AUTOMATED MAPPING TECH: Translate broad state inputs into specific farm/coastal queries
    String apiCityQuery = "Kuala Lumpur, Malaysia";

    if (state == 'Selangor') {
      apiCityQuery = "Kuala Selangor, Malaysia";
    } else if (state == 'Johor') {
      apiCityQuery = "Pontian, Malaysia";
    } else if (state == 'Putrajaya') {
      apiCityQuery = "Putrajaya, Malaysia";
    } else if (state == 'Perak') {
      apiCityQuery = "Lumut, Malaysia";
    } else if (state == 'Kedah') {
      apiCityQuery = "Kuala Muda, Malaysia";
    } else if (state == 'Pulau Pinang') {
      apiCityQuery = "Georgetown, Malaysia";
    } else if (state == 'Terengganu') {
      apiCityQuery = "Kuala Terengganu, Malaysia";
    } else if (state == 'Labuan') {
      apiCityQuery = "Labuan, Malaysia";
    } else if (state == 'Sabah') {
      apiCityQuery = "Sandakan, Malaysia";
    } else if (state == 'Sarawak') {
      apiCityQuery = "Bintulu, Malaysia";
    }

    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(apiCityQuery)}&units=metric&appid=59f5830a6b44d7d166644e4977168038",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          weatherTemp = (data['main']['temp'] as num).toDouble();
          final mainWeather = data['weather'][0]['main'].toString();
          if (mainWeather.contains('Rain') ||
              mainWeather.contains('Thunderstorm') ||
              mainWeather.contains('Drizzle')) {
            weatherCondition = 'Hujan Lebat ⛈️';
          } else if (mainWeather.contains('Clouds')) {
            weatherCondition = 'Berawan ☁️';
          } else {
            weatherCondition = 'Cerah ☀️';
          }
        });
      } else {
        _useSimulatedFallbackWeather(state);
      }
    } catch (_) {
      _useSimulatedFallbackWeather(state);
    } finally {
      setState(() {
        isWeatherLoading = false;
      });
    }
  }

  void _useSimulatedFallbackWeather(String state) {
    final random = math.Random();
    final isRainy = random.nextBool();
    setState(() {
      weatherTemp = 26.0 + (random.nextDouble() * 6.0);
      weatherCondition = isRainy ? 'Hujan Lebat ⛈️' : 'Cerah ☀️';
    });
  }

  // Dynamic Tides Simulator mapping to Malaysia Coastal States
  Map<String, String> _getTidesForState(String state) {
    switch (state) {
      case 'Johor':
        return {'high': '2.8m (11:24)', 'low': '0.3m (17:45)'};
      case 'Selangor':
        return {'high': '2.6m (10:15)', 'low': '0.4m (16:30)'};
      case 'Terengganu':
        return {'high': '2.1m (08:40)', 'low': '0.2m (14:55)'};
      case 'Sabah':
        return {'high': '2.3m (09:12)', 'low': '0.5m (15:20)'};
      case 'Sarawak':
        return {'high': '2.9m (12:05)', 'low': '0.6m (18:10)'};
      case 'Kedah':
      case 'Perlis':
      case 'Pulau Pinang':
        return {'high': '2.2m (10:50)', 'low': '0.3m (17:15)'};
      case 'Putrajaya':
        return {'high': '1.8m (11:24)', 'low': '0.4m (17:12)'};
      case 'Labuan':
        return {'high': '2.1m (09:15)', 'low': '0.3m (15:40)'};
      default:
        return {'high': '1.8m (10:15)', 'low': '0.5m (16:30)'};
    }
  }

  // Bypass Auth / Onboarding instantly
  void _bypassLogin() {
    setState(() {
      ownerName = 'Encik Abdullah';
      farmLocation = 'Selangor';
      waterType = 'Air Tawar';
      systemType = 'Kolam';
      registeredSystems = [
        SystemConfig(
          name: 'Kolam Utama Patin',
          type: 'Kolam',
          waterType: 'Air Tawar',
          length: 15.0,
          width: 8.0,
          depth: 2.5,
          speciesType: 'Ikan',
          speciesName: 'Patin',
          quantity: 2000,
          culturePhase: 'Benih',
        ),
      ];
      selectedSystemIndex = 0;
      isLoggedIn = true;
      activeScreen = AppScreen.mainApp;
    });
    _fetchWeatherAutomated(farmLocation);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(message)),
    );
  }

  bool _validateSystemInputs() {
    if (_systemNameCtrl.text.trim().isEmpty) {
      _showErrorSnackBar('Sila masukkan nama sistem yang sah.');
      return false;
    }
    if (speciesType == null || speciesType!.isEmpty) {
      _showErrorSnackBar('Sila pilih jenis ternakan.');
      return false;
    }
    if (_speciesNameCtrl.text.trim().isEmpty) {
      _showErrorSnackBar('Sila masukkan nama spesies yang sah.');
      return false;
    }
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    if (quantity == null || quantity <= 0) {
      _showErrorSnackBar('Bilangan individu mesti nombor bulat melebihi 0.');
      return false;
    }
    if (culturePhase == null || culturePhase!.isEmpty) {
      _showErrorSnackBar('Sila pilih fasa kultur.');
      return false;
    }
    if (!lengthValue.isFinite || lengthValue <= 0.0 ||
        !widthValue.isFinite || widthValue <= 0.0 ||
        !depthValue.isFinite || depthValue <= 0.0) {
      _showErrorSnackBar('Semua ukuran mesti nombor sah melebihi 0.');
      return false;
    }
    return true;
  }

  void _completeOnboarding() {
    if (!_validateSystemInputs()) return;
    setState(() {
      registeredSystems.add(
        SystemConfig(
          name: _systemNameCtrl.text.trim(),
          type: systemType,
          waterType: waterType,
          length: lengthValue,
          width: widthValue,
          depth: depthValue,
          speciesType: speciesType!,
          speciesName: _speciesNameCtrl.text.trim(),
          quantity: int.parse(_quantityCtrl.text.trim()),
          culturePhase: culturePhase!,
        ),
      );
      isLoggedIn = true;
      activeScreen = AppScreen.mainApp;
    });
    _fetchWeatherAutomated(farmLocation);
  }

  void _addAnotherSystem() {
    if (!_validateSystemInputs()) return;
    setState(() {
      registeredSystems.add(
        SystemConfig(
          name: _systemNameCtrl.text.trim(),
          type: systemType,
          waterType: waterType,
          length: lengthValue,
          width: widthValue,
          depth: depthValue,
          speciesType: speciesType!,
          speciesName: _speciesNameCtrl.text.trim(),
          quantity: int.parse(_quantityCtrl.text.trim()),
          culturePhase: culturePhase!,
        ),
      );
      _resetForm();
      onboardingStep = 3;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00F5D4),
        content: Text(
          'Sistem berjaya disimpan! Daftarkan sistem seterusnya.',
          style: TextStyle(
            color: Color(0xFF0B0F19),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
      onboardingStep = 1;
      registeredSystems.clear();
      _resetForm();
      _ammoniaCtrl.text = '0.05';
      ammoniaSensor = 0.05;
      currentTabIndex = 0;

      // Reset data profil kepada asal secara mutlak
      ownerName = '';
      farmLocation = 'Sila Pilih Negeri';
      waterType = '';
      systemType = '';
      shapeType = '';
      phoneNumber = '';
      activeScreen = AppScreen.welcome;
    });
  }

  Color _getRiskColor(double score) {
    // Aligned strictly with the thesis UI layout boundaries (39.9% / 74.9%) [1, 2]
    if (score >= 75.0) return Colors.red;
    if (score >= 40.0) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    switch (activeScreen) {
      case AppScreen.welcome:
        return _buildWelcomeScreen();
      case AppScreen.phoneInput:
        return _buildPhoneInputScreen();
      case AppScreen.otpVerification:
        return _buildOtpVerificationScreen();
      case AppScreen.setupProfile:
        return _buildSetupProfileScreen();
      case AppScreen.systemDetail:
        return _buildSystemDetailScreen();
      case AppScreen.mainApp:
        return _buildMainApp();
    }
  }

  // ==========================================
  // SKRIN 1: SELAMAT DATANG (WELCOME)
  // ==========================================

  Widget _buildWelcomeScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                : [const Color(0xFFE0F2F1), const Color(0xFFF4F7F6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Icon(
                    Icons.waves,
                    size: 80,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'HYDRAE',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: isDarkMode
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF007A87),
                      letterSpacing: 4.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _t('subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? Colors.white70
                          : Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      activeScreen = AppScreen.phoneInput;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                    foregroundColor: isDarkMode
                        ? const Color(0xFF0B0F19)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _t('register'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _bypassLogin,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF0A5C66),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _t('bypass_login'),
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF0A5C66),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SKRIN 1.1: INPUT TELEFON
  // ==========================================

  // 🌐 WHATSAPP CLOUD BUSINESS API INFRASTRUCTURE SIMULATOR
  Future<void> _sendWhatsAppOTP(
    String mobileNumber,
    BuildContext context,
  ) async {
    final cleanedNumber = mobileNumber.trim();

    // 🇲🇾 Strict Malaysian Mobile Number RegEx Check
    final RegExp msiaPhoneRegex = RegExp(r'^011\d{8}$|^01[02-9]\d{7}$');

    if (cleanedNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila masukkan nombor telefon bimbit anda!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!msiaPhoneRegex.hasMatch(cleanedNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Format tidak sah! Sila guna format standard tanpa sengkang (Contoh: 0123456789).',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // 🔄 Trigger button loading state
    setState(() => isOTPLoading = true);

    // Simulate Meta/WhatsApp Cloud API request network delay handshake latency
    await Future.delayed(const Duration(milliseconds: 1200));

    // Generate secure randomized 6-digit verification pin token token using system clock
    generatedOTP = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000))
        .toString();

    setState(() {
      isOTPLoading = false;
      activeScreen = AppScreen.otpVerification; // Slide forward seamlessly
    });

    // Premium Green WhatsApp Business API Message Broadcast Display Alert
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'WhatsApp OTP Dispatched via Meta Business Suite! Code: $generatedOTP',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(
          0xFF25D366,
        ), // Official WhatsApp Emerald Green Color Hex
        duration: const Duration(seconds: 15),
      ),
    );
  }

  Widget _buildPhoneInputScreen() {
    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0B0F19)
          : const Color(0xFFF4F7F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🚀 SUNTIKAN 1: Menolak keseluruhan kandungan skrin turun ke bawah!
              const SizedBox(height: 130),

              // 🚀 SUNTIKAN 2: Tajuk "Daftar Masuk" kustom yang boleh di-adjust kedudukan dia
              Text(
                _t('register'), // Memanggil teks 'Daftar Masuk' asal kau
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF007A87),
                ),
              ),
              const SizedBox(
                height: 8,
              ), // Jarak kecil antara tajuk dengan sub-tajuk bawah

              Text(
                _t('enter_phone'),
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (val) => phoneNumber = val,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('phone_number'),
                  hintText: '+60 12-345-6789',
                  prefixIcon: Icon(
                    Icons.phone,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                // 🔒 KUNCI UTAMA: Memanggil fungsi penapis Twilio dan mengunci butang jika sedang loading!
                onPressed: isOTPLoading
                    ? null
                    : () => _sendWhatsAppOTP(phoneNumber, context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                  foregroundColor: isDarkMode
                      ? const Color(0xFF0B0F19)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isOTPLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Hantar Kod OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 60),

              // Jarak pengimbang kustom
              const SizedBox(height: 10),

              // 🌊 ELEMEN 3: GRAFIK ILUSTRASI VEKTOR OMBAK MINIMALIS (WATERMARK EFFECT)
              Opacity(
                opacity: isDarkMode
                    ? 0.35
                    : 0.50, // Samar-samar sahaja supaya tak semak
                child: const Center(
                  child: Column(
                    children: [
                      FaIcon(
                        FontAwesomeIcons
                            .fish, // Ikon ikan yang sangat realistik!
                        size: 110,
                        color: Color(0xFF007A87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'HYDRAE AQUA-ECOSYSTEM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A87),
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 90,
              ), // Nota: Ditukar dari Spacer() ke SizedBox supaya kebal ralat scrollview!
              // 📜 ELEMEN 2: TEKS TERMA & POLISI PRIVASI (COMMERCIAL LOOK)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: Text(
                    'Dengan mendaftar, anda bersetuju dengan Terma Perkhidmatan\ndan Polisi Privasi Hydrae DSS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SKRIN 1.2: VERIFIKASI OTP
  // ==========================================

  Widget _buildOtpVerificationScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('otp_code')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // BARU: Suntikan ikon anak panah untuk patah balik ke skrin masukkan nombor telefon
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              activeScreen = AppScreen.phoneInput; // Mengundur langkah skrin
            });
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sila masukkan 6-digit kod pengesahan yang dihantar melalui WhatsApp ke $phoneNumber.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (val) => verificationOTPCode = val,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: 8.0,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '******',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (verificationOTPCode == generatedOTP) {
                    setState(() {
                      activeScreen = AppScreen.setupProfile;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Kod OTP salah! Sila cuba lagi.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                  foregroundColor: isDarkMode
                      ? const Color(0xFF0B0F19)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _t('verify_otp'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SKRIN 2: SETUP PROFILE (NAMA, NEGERI, DLL)
  // ==========================================

  Widget _buildSetupProfileScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('setup_profile')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // BARU: Back button to return to the OTP screen safely
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              activeScreen = AppScreen.otpVerification; // Steps back cleanly
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: 0.5,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF007A87),
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (val) => ownerName = val,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('owner_name'),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: farmLocation,
                dropdownColor: isDarkMode
                    ? const Color(0xFF1F2937)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('farm_location'),
                  prefixIcon: Icon(
                    Icons.map,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
                items:
                    [
                      'Johor',
                      'Kedah',
                      'Kelantan',
                      'Melaka',
                      'Negeri Sembilan',
                      'Pahang',
                      'Perak',
                      'Perlis',
                      'Pulau Pinang',
                      'Sabah',
                      'Sarawak',
                      'Selangor',
                      'Terengganu',
                      'Labuan',
                      'Putrajaya',
                      'Sila Pilih Negeri',
                    ].map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => farmLocation = val!),
              ),
              const SizedBox(height: 16),

              // 1. 💧 PILIHAN JENIS AIR KEPADA INTERACTIVE PILIHAN MENDATAR (ROBUST SELECTION) [1]
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t('water_type'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Pilihan Air Tawar
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => waterType = 'Air Tawar');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: waterType == 'Air Tawar'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: waterType == 'Air Tawar'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Air Tawar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: waterType == 'Air Tawar'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Pilihan Air Payau
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => waterType = 'Air Payau');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: waterType == 'Air Payau'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: waterType == 'Air Payau'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Air Payau',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: waterType == 'Air Payau'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Pilihan Air Masin
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => waterType = 'Air Masin');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: waterType == 'Air Masin'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: waterType == 'Air Masin'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Air Masin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: waterType == 'Air Masin'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 🐟 PILIHAN JENIS SISTEM KEPADA 3 INTERACTIVE SELECTION MENDATAR (ROBUST GESTURE SELECTION) [1]
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t('system_type'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Pilihan A: Kolam [1]
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => systemType = 'Kolam');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: systemType == 'Kolam'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: systemType == 'Kolam'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Kolam',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: systemType == 'Kolam'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Pilihan B: Tangki [1]
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => systemType = 'Tangki');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: systemType == 'Tangki'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: systemType == 'Tangki'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Tangki',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: systemType == 'Tangki'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Pilihan C: Sangkar [1]
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => systemType = 'Sangkar');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: systemType == 'Sangkar'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: systemType == 'Sangkar'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sangkar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: systemType == 'Sangkar'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 🔄 BARU: MENU PILIHAN BENTUK BADAN AIR (DYNAMIC UX SELECTION)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bentuk Badan Air',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => shapeType = 'Segi Empat');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: shapeType == 'Segi Empat'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: shapeType == 'Segi Empat'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Segi Empat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: shapeType == 'Segi Empat'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => shapeType = 'Bulat');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: shapeType == 'Bulat'
                              ? const Color(0xFF007A87).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: shapeType == 'Bulat'
                                ? const Color(0xFF007A87)
                                : Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Bulat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: shapeType == 'Bulat'
                                  ? const Color(0xFF007A87)
                                  : (isDarkMode ? Colors.grey : Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ), // Jarak pemisah ke butang Seterusnya di bawah
              ElevatedButton(
                onPressed: () {
                  if (ownerName.trim().isNotEmpty &&
                      waterType.isNotEmpty &&
                      systemType.isNotEmpty &&
                      shapeType.isNotEmpty &&
                      farmLocation != 'Sila Pilih Negeri' &&
                      farmLocation.isNotEmpty) {
                    setState(() {
                      activeScreen = AppScreen.systemDetail;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          'Sila pastikan Nama Pemilik diisi, Negeri dipilih, dan semua Jenis Air/Sistem/Bentuk telah ditentukan.',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                  foregroundColor: isDarkMode
                      ? const Color(0xFF0B0F19)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _t('next_step'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SKRIN 3: SYSTEM DETAIL (DIMENSION & SPECIES)
  // ==========================================

  Widget _buildSystemDetailScreen() {
    return Scaffold(
      key: const Key(
        'system_detail_screen',
      ), // Ditukar daripada identity kepada key
      appBar: AppBar(
        title: Text(
          _t('mari_kenali'),
        ), // Localized title: "Mari kenali sistem anda"
        backgroundColor: Colors.transparent,
        elevation: 0,
        // BARU: Ikon anak panah untuk patah balik ke skrin Sediakan Profil
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              activeScreen = AppScreen
                  .setupProfile; // Patah balik ke setup profile cleanly
            });
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: 1.0,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF0A5C66),
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 16),
              _buildSystemVisualPlaceholder(systemType),
              const SizedBox(height: 16),
              Text(
                _t('dimensions'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  if (shapeType == 'Segi Empat') ...[
                    // 📏 A. LAYOUT SEGI EMPAT: Papar kotak input Panjang & Lebar secara selari!
                    Expanded(
                      child: TextFormField(
                        controller: _panjangCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Panjang',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          lengthValue = double.tryParse(val) ?? 0.0;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lebarCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Lebar',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          widthValue = double.tryParse(val) ?? 0.0;
                        },
                      ),
                    ),
                  ] else ...[
                    // 🔄 B. AUTOMATIC LAYOUT SWAP: Papar input Diameter jika user pilih bentuk Bulat!
                    Expanded(
                      child: TextFormField(
                        controller: _diameterCtrl, // 🌟 PASTIKAN BARIS INI ADA
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Diameter',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          double diameter = double.tryParse(val) ?? 0.0;
                          lengthValue = diameter;
                          widthValue = diameter;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  // Kotak Kedalaman akan sentiasa kekal dipapar untuk kedua-dua jenis bentuk
                  Expanded(
                    child: TextFormField(
                      controller: _kedalamanCtrl, // 🌟 PASTIKAN BARIS INI ADA
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kedalaman',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        depthValue = double.tryParse(val) ?? 0.0;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: speciesType, // Membaca status null awal kita
                hint: const Text(
                  'Sila Pilih Jenis Ternakan',
                ), // 🚀 SUIS BLANK BARU
                dropdownColor: isDarkMode
                    ? const Color(0xFF1F2937)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('species_type'),
                  prefixIcon: Icon(
                    Icons.pets,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
                items: ['Ikan', 'Udang', 'Ketam'].map((String s) {
                  return DropdownMenuItem<String>(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) => setState(() => speciesType = val ?? ''),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _speciesNameCtrl,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('species_name'),
                  prefixIcon: Icon(
                    Icons.bubble_chart,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('quantity'),
                  prefixIcon: Icon(
                    Icons.tag,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: culturePhase, // Membaca status null awal kita
                hint: const Text(
                  'Sila Pilih Fasa Kultur',
                ), // 🚀 SUIS BLANK BARU
                dropdownColor: isDarkMode
                    ? const Color(0xFF1F2937)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: _t('phase'),
                  prefixIcon: Icon(
                    Icons.timelapse,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
                items: ['Larva', 'Benih', 'Dewasa'].map((String p) {
                  return DropdownMenuItem<String>(value: p, child: Text(p));
                }).toList(),
                onChanged: (val) => setState(() => culturePhase = val!),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _addAnotherSystem,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0A5C66),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _t('add_other'),
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0A5C66),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                  foregroundColor: isDarkMode
                      ? const Color(0xFF0B0F19)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _t('finish_open'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemVisualPlaceholder(String type) {
    // 💡 ULTRA-DYNAMIC MATRIX: 6 Kombinasi Gambar Ikut Sistem DAN Bentuk Serentak!
    String assetPath = 'assets/pond_square.jpg';
    Color systemColor = const Color(0xFF00838F);

    // A. MATRIKS UNTUK KOLAM
    if (type == 'Kolam') {
      if (shapeType == 'Bulat') {
        assetPath = 'assets/pond_round.jpg';
      } else {
        assetPath = 'assets/pond_square.jpg';
      }
    }
    // B. MATRIKS UNTUK TANGKI
    else if (type == 'Tangki') {
      systemColor = const Color(0xFF455A64);
      if (shapeType == 'Bulat') {
        assetPath = 'assets/tank_round.jpg';
      } else {
        assetPath = 'assets/tank_square.jpg';
      }
    }
    // C. MATRIKS UNTUK SANGKAR
    else if (type == 'Sangkar') {
      systemColor = const Color(0xFFE65100);
      if (shapeType == 'Bulat') {
        assetPath = 'assets/cage_round.jpg';
      } else {
        assetPath = 'assets/cage_square.jpg';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🖼️ MEMANCARKAN GAMBAR TEMPATAN 100% OFFLINE IKUT 6 MATRIKS PILIHAN USER
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              assetPath,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  color: systemColor.withOpacity(0.1),
                  child: Icon(Icons.waves, size: 48, color: systemColor),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${type.toUpperCase()} (${shapeType.toUpperCase()})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: systemColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STRUKTUR UTAMA APLIKASI TERKONTROL (MAIN)
  // ==========================================

  Widget _buildMainApp() {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isDarkMode
            ? const Color(0xFF00E5FF)
            : const Color(0xFF00838F),
        unselectedItemColor: isDarkMode
            ? Colors.grey.shade600
            : Colors.grey.shade500,
        backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
        onTap: (index) => setState(() => currentTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: Icon(
              Icons.dashboard,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF00838F),
            ),
            label: _t('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(
              Icons.bar_chart,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF00838F),
            ),
            label: _t('nav_reports'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(
              Icons.notifications,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF00838F),
            ),
            label: _t('nav_notif'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: Icon(
              Icons.account_circle,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF00838F),
            ),
            label: _t('nav_account'),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentTabIndex,
          children: [
            _buildDashboardTab(),
            _buildReportsTab(),
            _buildNotificationsTab(),
            _buildAccountTab(),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // TAB 1: DSS DASHBOARD
  // -----------------------------------------

  Widget _buildDashboardTab() {
    if (registeredSystems.isEmpty) {
      return const Center(
        child: Text('Tiada konfigurasi sistem aktif dikesan.'),
      );
    }
    final activeSystem = registeredSystems[selectedSystemIndex];

    final fuzzyResult = calculateFuzzyRisk(
      tempSensor,
      phSensor,
      doSensor,
      manualWeather,
      manualTide,
      activeSystem.type,
    );
    final fuzzyRisk = fuzzyResult.score;

    String finalStatus = '';
    String cause = '';
    String impact = '';
    String actionStep = '';
    Color statusColor = isDarkMode
        ? const Color(0xFF00E5FF)
        : const Color(0xFF0A5C66);

    // Status classification dan fallback Bab 3.
    if (fuzzyResult.noRulesActive) {
      finalStatus = 'TIADA ALERTI AKTIF';
      cause = 'Tiada rule fuzzy diaktifkan untuk kombinasi input ini.';
      impact = 'Sistem memaparkan fallback selamat 0% tanpa mereka skor.';
      actionStep = fuzzyResult.recommendation;
      statusColor = Colors.grey;
    } else if (fuzzyRisk >= 75.0) {
      // Critical / Red (75.0% - 100%) [1, 2]
      finalStatus = 'KRITIKAL: Kualiti Air Buruk';
      cause = 'Suhu, pH & Oksigen (DO) dikesan pada tahap merbahaya.';
      impact = 'Risiko tinggi kematian ternakan & Osmotic shock kritikal.';
      actionStep =
          '1. Jalankan pengudaraan maksimum.\n2. Hentikan pemakanan & tukar air.';
      statusColor = Colors.red.shade700;
    } else if (fuzzyRisk >= 40.0) {
      // Warning / Yellow-Orange (40.0% - 74.9%) [1, 2]
      finalStatus = 'AMARAN: Degradasi Sistem';
      cause = 'Parameter kualiti air dikesan kurang optimal.';
      impact = 'Kadar respirasi meningkat dan stress pada ternakan.';
      actionStep =
          '1. Tingkatkan kitaran pengudaraan.\n2. Sila pantau parameter dengan kerap.';
      statusColor = Colors.orange.shade700;
    } else {
      // Stable / Green (0.0% - 39.9%) [1, 2]
      finalStatus = 'OPTIMAL: Ekosistem Stabil';
      cause = 'Semua petunjuk parameter berada dalam keadaan normal.';
      impact = 'Kadar tumbesaran optimum.';
      actionStep = 'Teruskan rutin penjagaan sedia ada.';
      statusColor = isDarkMode
          ? const Color(0xFF00E5FF)
          : const Color(0xFF0A5C66);
    }

    if (!fuzzyResult.noRulesActive) {
      actionStep = '$actionStep\n\nSyor Rule: ${fuzzyResult.recommendation}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ternakan $ownerName",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF0A2533),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 $farmLocation | ${activeSystem.name.replaceAll(' Utama', '')} (${activeSystem.type})',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF627D98),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_horiz,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
                tooltip: _t('change_system'),
                onPressed: _showSystemSelectionDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live API Section (Automated) - KEPASTIAN TUGASAN MEMBENTANGKAN DATA CONTOH/API CUACA & PASANG SURUT [1, 2]
          Row(
            children: [
              Expanded(child: _buildWeatherCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildTidesCard(farmLocation)),
            ],
          ),
          const SizedBox(height: 16),

          // Sensor Slider controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('water_quality_sensors'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSliderControl(
                  _t('temp_lbl'),
                  tempSensor,
                  20.0,
                  35.0,
                  (val) => setState(() => tempSensor = val),
                  ' °C',
                ),
                _buildSliderControl(
                  _t('ph_lbl'), // Mapped to pH level translation [1]
                  phSensor, // state variable phSensor replaces salinitySensor [1]
                  0.0,
                  14.0, // Scale range strictly 0 to 14 [1]
                  (val) => setState(() => phSensor = val),
                  '', // ppt completely removed [1]
                  isInt: false, // Double slider for highly-precise pH [1]
                ),
                _buildSliderControl(
                  _t('do_lbl'),
                  doSensor,
                  2.0,
                  10.0,
                  (val) => setState(() => doSensor = val),
                  ' mg/L',
                ),
                _buildAmmoniaManualForm(),

                // COMPACT MANUAL DROPDOWNS FOR WEATHER & TIDE TESTING [1]
                const Divider(height: 24, color: Colors.grey),
                Row(
                  children: [
                    // Weather Selection Dropdown Box [1]
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cuaca Simulasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white10
                                    : Colors.black12,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: manualWeather,
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF1F2937)
                                    : Colors.white,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: ['Sunny', 'Cloudy', 'Rainy', 'Stormy']
                                    .map((String val) {
                                      String label = val;
                                      if (val == 'Sunny')
                                        label = 'Sunny (Cerah) ☀️';
                                      if (val == 'Cloudy')
                                        label = 'Cloudy (Awan) ☁️';
                                      if (val == 'Rainy')
                                        label = 'Rainy (Hujan) 🌧️';
                                      if (val == 'Stormy')
                                        label = 'Stormy (Ribut) ⛈️';
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(label),
                                      );
                                    })
                                    .toList(),
                                onChanged: (String? newVal) {
                                  if (newVal != null) {
                                    setState(() {
                                      manualWeather = newVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tide Selection Dropdown Box [1]
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pasang Surut',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white10
                                    : Colors.black12,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: manualTide,
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF1F2937)
                                    : Colors.white,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                items:
                                    [
                                      'Active Flow',
                                      'Slack Tide',
                                      'Not Applicable',
                                    ].map((String val) {
                                      String label = val;
                                      if (val == 'Active Flow')
                                        label = 'Active (Arus)';
                                      if (val == 'Slack Tide')
                                        label = 'Slack (Tenang)';
                                      if (val == 'Not Applicable')
                                        label = 'N/A (Tiada)';
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(label),
                                      );
                                    }).toList(),
                                onChanged: (String? newVal) {
                                  if (newVal != null) {
                                    setState(() {
                                      manualTide = newVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DSS Output Section
          Text(
            _t('decide_act'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Latar belakang terus jadi Hijau Solid jika OPTIMAL [1]
              color: finalStatus.contains('OPTIMAL')
                  ? const Color(0xFF00C853)
                  : statusColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: finalStatus.contains('OPTIMAL')
                    ? const Color(0xFF00A343)
                    : statusColor.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: finalStatus.contains('OPTIMAL')
                          ? Colors.white
                          : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finalStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '🔍 ${_t('cause')}: $cause',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ ${_t('impact')}: $impact',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: finalStatus.contains('OPTIMAL')
                        ? const Color(0xFF008D36) // Hijau gelap
                        : finalStatus.contains('AMARAN')
                        ? const Color(0xFFD86600) // Oren gelap
                        : finalStatus.contains('KRITIKAL')
                        ? const Color(0xFFB71C1C) // Merah gelap untuk kritikal
                        : (isDarkMode ? const Color(0xFF111827) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: finalStatus.contains('OPTIMAL')
                          ? const Color(0xFF007A2F)
                          : finalStatus.contains('AMARAN')
                          ? const Color(0xFFB35300)
                          : finalStatus.contains('KRITIKAL')
                          ? const Color(0xFF9E1B1B)
                          : (isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04)),
                    ),
                  ),
                  child: Text(
                    '📋 ${_t('action')}:\n$actionStep',
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.4,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Risk Score metrics container directly BELOW the Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('risk_score'),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF627D98),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fuzzyRisk.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: fuzzyResult.noRulesActive
                            ? Colors.grey
                            : _getRiskColor(fuzzyRisk),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: fuzzyRisk / 100.0,
                    strokeWidth: 6,
                    color: fuzzyResult.noRulesActive
                        ? Colors.grey
                        : _getRiskColor(fuzzyRisk),
                    backgroundColor: Colors.black.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              final ammonia = double.tryParse(_ammoniaCtrl.text.trim());
              if (ammonia == null || !ammonia.isFinite || ammonia < 0.0) {
                _showErrorSnackBar(
                  'Bacaan ammonia mesti nombor sah yang tidak negatif.',
                );
                return;
              }
              ammoniaSensor = ammonia;
              addNewDataRecord(
                doReading: doSensor,
                ammoniaReading: ammonia,
                temperatureReading: tempSensor,
                dssStatus: finalStatus,
                fuzzyRisk: '${fuzzyRisk.toStringAsFixed(1)}%',
              );
            },
            icon: const Icon(Icons.add_task),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF007A87),
              foregroundColor: isDarkMode
                  ? const Color(0xFF0B0F19)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(
              _t('save_reading'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _t('change_system'),
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF007A87),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: registeredSystems.length,
              itemBuilder: (context, index) {
                final sys = registeredSystems[index];
                return ListTile(
                  leading: Icon(
                    Icons.waves,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0A5C66),
                  ),
                  title: Text(
                    'Sistem ${sys.type}', // Menggabungkan kata 'Sistem' + jenis (e.g. Tangki/Kolam/Sangkar)
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF0A2533),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${sys.speciesType} - ${sys.speciesName}', // Menampilkan 'Jenis Ternakan - Nama Spesies'
                    style: const TextStyle(
                      color: Color(0xFF627D98),
                      fontSize: 13,
                    ),
                  ),
                  trailing: selectedSystemIndex == index
                      ? Icon(
                          Icons.check_circle,
                          color: isDarkMode
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF007A87),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      selectedSystemIndex = index;
                    });
                    _fetchWeatherAutomated(farmLocation);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_queue,
                size: 16,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF007A87),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _t('weather_api'),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isWeatherLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF007A87),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weatherCondition,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${weatherTemp.toStringAsFixed(1)} °C',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTidesCard(String state) {
    final tides = _getTidesForState(state);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water,
                size: 16,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF007A87),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _t('tide_api'),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_t('tides_high')}: ${tides['high']}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF0A5C66),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_t('tides_low')}: ${tides['low']}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String unit, {
    bool isInt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              '${isInt ? value.round() : value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF007A87),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: isDarkMode
                ? const Color(0xFF00E5FF)
                : const Color(0xFF007A87),
            inactiveTrackColor: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            thumbColor: isDarkMode
                ? const Color(0xFF00F5D4)
                : const Color(0xFF0A5C66),
            overlayColor:
                (isDarkMode ? const Color(0xFF00F5D4) : const Color(0xFF0A5C66))
                    .withOpacity(0.12),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildAmmoniaManualForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _t('ammonia_lbl'),
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: _ammoniaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF007A87),
            ),
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------
  // TAB 2: LAPORAN TERNAKAN (CO-RELATIONAL CHART)
  // -----------------------------------------

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t('reports_title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            ),
          ),
          const SizedBox(height: 16),
          _buildAveragesCard(),
          const SizedBox(height: 20),
          _buildMultiParameterCorrelationGraph(),
          const SizedBox(height: 20),
          _buildOriginalHistoricalLogsTable(),
        ],
      ),
    );
  }

  Widget _buildAveragesCard() {
    if (_historicalLogs.isEmpty) return const SizedBox();

    double avgTemp =
        _historicalLogs
            .map((e) => (e['temperature'] as num).toDouble())
            .reduce((a, b) => a + b) /
        _historicalLogs.length;
    double avgPh = // Replaced avgAmmonia with avgPh [1]
        _historicalLogs
            .map((e) => (e['ph'] as num).toDouble())
            .reduce((a, b) => a + b) /
        _historicalLogs.length;
    double avgDo =
        _historicalLogs
            .map((e) => (e['do'] as num).toDouble())
            .reduce((a, b) => a + b) /
        _historicalLogs.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('averages'),
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : const Color(0xFF627D98),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAvgIndicator(
                'Suhu',
                '${avgTemp.toStringAsFixed(1)} °C',
                isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF007A87),
              ),
              _buildAvgIndicator(
                'Oksigen (DO)',
                '${avgDo.toStringAsFixed(1)} mg/L',
                isDarkMode ? const Color(0xFF00F5D4) : const Color(0xFF0A5C66),
              ),
              _buildAvgIndicator(
                'pH', // Replaced Ammonia with pH [1]
                avgPh.toStringAsFixed(
                  1,
                ), // Average value format without ppm [1]
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgIndicator(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white60 : const Color(0xFF627D98),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiParameterCorrelationGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Korelasi Parameter (Temp / pH / DO)', // Changed Temp/DO/Ammonia to Temp/pH/DO [1]
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendNode(
                'Suhu (°C)',
                isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF007A87),
              ),
              _buildLegendNode(
                'Oksigen (mg/L)',
                isDarkMode ? const Color(0xFF00F5D4) : const Color(0xFF0A5C66),
              ),
              _buildLegendNode(
                'pH',
                Colors.orange,
              ), // Changed Ammonia (ppm) to pH [1]
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: MultiParameterLinePainter(_historicalLogs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendNode(String title, Color col) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white60 : const Color(0xFF627D98),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalHistoricalLogsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t('historical_logs'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
              ),
            ),
            TextButton.icon(
              onPressed: exportLogsToCSV,
              icon: Icon(
                Icons.download,
                size: 16,
                color: isDarkMode
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF007A87),
              ),
              label: Text(
                _t('export_csv'),
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
              ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historicalLogs.length,
          itemBuilder: (context, index) {
            final log = _historicalLogs[index];

            String logStatus = log['status'] ?? '';
            double logTemp = ((log['temperature'] ?? 25.0) as num).toDouble();
            double logPh = ((log['ph'] ?? 7.2) as num)
                .toDouble(); // Read pH safely [1]
            double logDo = ((log['do'] ?? 5.0) as num).toDouble();

            Color lineStatusColor = isDarkMode
                ? const Color(0xFF00F5D4)
                : const Color(0xFF0A5C66);
            if (logStatus.contains('KRITIKAL') ||
                logStatus.contains('KRITIKAL')) {
              lineStatusColor = Colors.red.shade700;
            } else if (logStatus.contains('AMARAN') ||
                logStatus.contains('AMARAN')) {
              lineStatusColor = Colors.orange.shade700;
            } else if (logStatus.contains('OPTIMAL') ||
                logStatus.contains('OPTIMAL')) {
              lineStatusColor = const Color(
                0xFF00C853,
              ); // Standardized to Green [1]
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logStatus,
                          style: TextStyle(
                            color: lineStatusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suhu: ${logTemp.toStringAsFixed(1)}°C | pH: ${logPh.toStringAsFixed(1)} | DO: ${logDo.toStringAsFixed(1)}', // Mapped labels salinity -> ph and removed Ammonia [1]
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF627D98),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(log['date'] as DateTime).day}/${(log['date'] as DateTime).month} ${(log['date'] as DateTime).hour}:${(log['date'] as DateTime).minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF627D98),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // -----------------------------------------
  // TAB 3: NOTIFIKASI
  // -----------------------------------------

  Widget _buildNotificationsTab() {
    final alerts = _notifications;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t('nav_notif'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            ),
          ),
          const SizedBox(height: 16),
          alerts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 48,
                          color: isDarkMode
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF007A87),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _t('notif_empty'),
                          style: const TextStyle(
                            color: Color(0xFF627D98),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final log = alerts[index];
                      final String logTitle = log['title'] ?? '';
                      final isCritical =
                          logTitle.contains('KRITIKAL') ||
                          logTitle.contains('KRITIKAL');

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? Colors.red.withOpacity(0.04)
                              : Colors.orange.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCritical
                                ? Colors.red.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCritical
                                  ? Icons.error_outline
                                  : Icons.warning_amber_outlined,
                              color: isCritical ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0A2533),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log['body'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF627D98),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // TAB 4: AKAUN (PROFILE, SETTINGS, DLL)
  // -----------------------------------------

  Widget _buildAccountTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: isDarkMode
              ? const Color(0xFF111827)
              : const Color(0xFFE0F2F1),
          child: Icon(
            Icons.person,
            size: 36,
            color: isDarkMode
                ? const Color(0xFF00E5FF)
                : const Color(0xFF007A87),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            ownerName.isNotEmpty ? ownerName : 'Penternak Hydrae',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
            ),
          ),
        ),
        Center(
          child: Text(
            phoneNumber.isNotEmpty ? phoneNumber : '+60 12-345-6789',
            style: const TextStyle(
              color: Color(0xFF627D98),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. PROFIL PENGGUNA
              ListTile(
                leading: Icon(
                  Icons.edit_note_outlined,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
                title: Text(
                  'Profil Pengguna',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
                  ),
                ),
                subtitle: Text(
                  '📍 $farmLocation | $ownerName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF627D98),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF627D98),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      String tempName = ownerName;
                      String tempLoc = farmLocation;
                      return AlertDialog(
                        backgroundColor: isDarkMode
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Kemaskini Profil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF0A2533),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              initialValue: ownerName,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Nama Pemilik',
                              ),
                              onChanged: (val) => tempName = val,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: tempLoc,
                              dropdownColor: isDarkMode
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Lokasi Ternakan',
                              ),
                              items:
                                  [
                                        'Johor',
                                        'Kedah',
                                        'Kelantan',
                                        'Melaka',
                                        'Negeri Sembilan',
                                        'Pahang',
                                        'Perak',
                                        'Perlis',
                                        'Pulau Pinang',
                                        'Sabah',
                                        'Sarawak',
                                        'Selangor',
                                        'Terengganu',
                                        'Labuan',
                                        'Putrajaya',
                                      ]
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) => tempLoc = val!,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF007A87),
                              foregroundColor: isDarkMode
                                  ? const Color(0xFF0B0F19)
                                  : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                ownerName = tempName;
                                farmLocation = tempLoc;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Simpan'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 2. TETAPAN MOD GELAP (LIVE SWITCH SYNCED DENGAN MATERIALAPP)
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
                title: Text(
                  'Mod Gelap / Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
                  ),
                ),
                subtitle: Text(
                  isDarkMode ? 'Gelap / Dark' : 'Cerah / Light',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF627D98),
                  ),
                ),
                trailing: Switch(
                  value: isDarkMode,
                  activeTrackColor: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF0A5C66),
                  activeThumbColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      isDarkMode = val;
                      isDarkModeNotifier.value = val;
                    });
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 3. SAIZ TEKS APLIKASI
              ListTile(
                leading: Icon(
                  Icons.format_size_outlined,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
                title: Text(
                  'Saiz Teks Aplikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
                  ),
                ),
                subtitle: const Text(
                  'Ubah saiz font paparan sistem',
                  style: TextStyle(fontSize: 12, color: Color(0xFF627D98)),
                ),
                trailing: DropdownButton<String>(
                  value: 'Normal',
                  dropdownColor: isDarkMode
                      ? const Color(0xFF1F2937)
                      : Colors.white,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  items: ['Small', 'Normal', 'Large'].map((String size) {
                    return DropdownMenuItem<String>(
                      value: size,
                      child: Text(
                        size,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newSize) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saiz teks diubah kepada: $newSize (Simulasi)',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 4. BANTUAN & SOKONGAN
              ListTile(
                leading: Icon(
                  Icons.support_agent,
                  color: isDarkMode
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF007A87),
                ),
                title: Text(
                  _t('help_support'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A2533),
                  ),
                ),
                onTap: () {
                  showModalBottomSheet(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF1F2937)
                        : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sokongan Integrasi Hydrae UPM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFF007A87),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Untuk maklum balas sistem kawalan atau kalibrasi sensor kualiti air pintar, sila hubungi bahagian Penyelidikan Akuakultur Universiti Putra Malaysia.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0xFF627D98),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFF007A87),
                                foregroundColor: isDarkMode
                                    ? const Color(0xFF0B0F19)
                                    : Colors.white,
                              ),
                              child: const Text(
                                'Tutup',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  _t('logout'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Hydrae Aquaculture Core v2.4.0\n© 2026 Universiti Putra Malaysia',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF627D98),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// PAINTER GRAF MULTI-PARAMETER KORELASI - UPDATED DENGAN pH & DO
// ==========================================

class MultiParameterLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> logs;
  MultiParameterLinePainter(this.logs);

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.length < 2) return;

    final paintTemp = Paint()
      ..color = const Color(0xFF007A87)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintDo = Paint()
      ..color = const Color(0xFF0A5C66)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintPh =
        Paint() // Replaced paintAmmonia with paintPh [1]
          ..color = Colors.orange
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    double dx = size.width / (logs.length - 1);

    for (int i = 0; i < logs.length - 1; i++) {
      double x1 = i * dx;
      double x2 = (i + 1) * dx;

      double t1 = ((logs[i]['temperature'] ?? 25.0) as num).toDouble();
      double t2 = ((logs[i + 1]['temperature'] ?? 25.0) as num).toDouble();
      double d1 = ((logs[i]['do'] ?? 5.0) as num).toDouble();
      double d2 = ((logs[i + 1]['do'] ?? 5.0) as num).toDouble();
      double p1 = ((logs[i]['ph'] ?? 7.2) as num)
          .toDouble(); // Replaced ammonia with ph [1]
      double p2 = ((logs[i + 1]['ph'] ?? 7.2) as num).toDouble();

      double yT1 =
          size.height - ((t1 - 20) / 15 * size.height).clamp(0, size.height);
      double yT2 =
          size.height - ((t2 - 20) / 15 * size.height).clamp(0, size.height);

      double yD1 =
          size.height - ((d1 - 2) / 8 * size.height).clamp(0, size.height);
      double yD2 =
          size.height - ((d2 - 2) / 8 * size.height).clamp(0, size.height);

      double yP1 =
          size.height -
          (p1 / 14.0 * size.height).clamp(0, size.height); // Scaled for pH [1]
      double yP2 =
          size.height - (p2 / 14.0 * size.height).clamp(0, size.height);

      canvas.drawLine(Offset(x1, yT1), Offset(x2, yT2), paintTemp);
      canvas.drawLine(Offset(x1, yD1), Offset(x2, yD2), paintDo);
      canvas.drawLine(
        Offset(x1, yP1),
        Offset(x2, yP2),
        paintPh,
      ); // Replaced ammonia line drawing [1]
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
