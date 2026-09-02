import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'services/payment_service.dart';
import 'services/vpn_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Spenix Internet',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F3A),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyan),
          ),
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/packages', page: () => const PackagesScreen()),
        GetPage(name: '/voucher', page: () => const VoucherScreen()),
        GetPage(name: '/account', page: () => const AccountScreen()),
        GetPage(name: '/admin', page: () => const AdminDashboard()),
        GetPage(name: '/admin/users', page: () => const AdminUsersScreen()),
        GetPage(name: '/admin/packages', page: () => const AdminPackagesScreen()),
        GetPage(name: '/admin/payments', page: () => const AdminPaymentsScreen()),
        GetPage(name: '/admin/vouchers', page: () => const AdminVouchersScreen()),
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuth();
    });
  }

  void _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('user');
    if (user != null) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyan, width: 3),
                  boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 30)],
                ),
                child: const Icon(Icons.wifi, size: 50, color: Colors.cyan),
              ),
              const SizedBox(height: 20),
              const Text('SPENIX', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('INTERNET', style: TextStyle(fontSize: 16, color: Colors.cyan, letterSpacing: 4)),
              const SizedBox(height: 30),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.cyan)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DATABASE SERVICE
// ============================================================
class DB {
  static final DB _instance = DB._internal();
  factory DB() => _instance;
  DB._internal();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> getUsers() async {
    final prefs = await _prefs;
    final json = prefs.getString('users') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await _prefs;
    await prefs.setString('users', jsonEncode(users));
  }

  Future<void> addUser(Map<String, dynamic> user) async {
    final users = await getUsers();
    users.add(user);
    await saveUsers(users);
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u['phone'] == phone);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String phone, String password) async {
    final user = await getUserByPhone(phone);
    if (user != null && user['password'] == password) {
      final prefs = await _prefs;
      await prefs.setString('user', jsonEncode(user));
      return user;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await _prefs;
    final json = prefs.getString('user');
    return json != null ? Map<String, dynamic>.from(jsonDecode(json)) : null;
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove('user');
  }

  Future<List<Map<String, dynamic>>> getPackages() async {
    final prefs = await _prefs;
    final json = prefs.getString('packages') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  Future<void> savePackages(List<Map<String, dynamic>> packages) async {
    final prefs = await _prefs;
    await prefs.setString('packages', jsonEncode(packages));
  }

  Future<void> addPackage(Map<String, dynamic> pkg) async {
    final packages = await getPackages();
    packages.add(pkg);
    await savePackages(packages);
  }

  Future<void> deletePackage(String id) async {
    final packages = await getPackages();
    packages.removeWhere((p) => p['id'] == id);
    await savePackages(packages);
  }

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    final prefs = await _prefs;
    final json = prefs.getString('subscriptions') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  Future<void> saveSubscriptions(List<Map<String, dynamic>> subs) async {
    final prefs = await _prefs;
    await prefs.setString('subscriptions', jsonEncode(subs));
  }

  Future<void> addSubscription(Map<String, dynamic> sub) async {
    final subs = await getSubscriptions();
    subs.add(sub);
    await saveSubscriptions(subs);
  }

  Future<Map<String, dynamic>?> getActiveSubscription(String userId) async {
    final subs = await getSubscriptions();
    final now = DateTime.now().toIso8601String();
    try {
      return subs.firstWhere((s) => s['userId'] == userId && s['status'] == 'active' && s['expiryDate'] > now);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getVouchers() async {
    final prefs = await _prefs;
    final json = prefs.getString('vouchers') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  Future<void> saveVouchers(List<Map<String, dynamic>> vouchers) async {
    final prefs = await _prefs;
    await prefs.setString('vouchers', jsonEncode(vouchers));
  }

  Future<Map<String, dynamic>?> getVoucherByCode(String code) async {
    final vouchers = await getVouchers();
    try {
      return vouchers.firstWhere((v) => v['code'] == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> useVoucher(String code, String userId) async {
    final vouchers = await getVouchers();
    final index = vouchers.indexWhere((v) => v['code'] == code);
    if (index != -1 && !vouchers[index]['isUsed']) {
      vouchers[index]['isUsed'] = true;
      vouchers[index]['usedBy'] = userId;
      vouchers[index]['usedAt'] = DateTime.now().toIso8601String();
      await saveVouchers(vouchers);
    }
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final prefs = await _prefs;
    final json = prefs.getString('payments') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  Future<void> addPayment(Map<String, dynamic> payment) async {
    final payments = await getPayments();
    payments.add(payment);
    final prefs = await _prefs;
    await prefs.setString('payments', jsonEncode(payments));
  }

  Future<void> seedData() async {
    final users = await getUsers();
    if (users.isEmpty) {
      await addUser({'id': 'admin_1', 'name': 'Admin', 'phone': '0771208144', 'password': 'Admin@2024', 'role': 'admin', 'isActive': true, 'createdAt': DateTime.now().toIso8601String()});
      await addUser({'id': 'user_1', 'name': 'Test User', 'phone': '0700000001', 'password': 'User@2024', 'role': 'user', 'isActive': true, 'createdAt': DateTime.now().toIso8601String()});
      
      await savePackages([
        {'id': 'p1', 'name': 'Daily Plan', 'price': 1000, 'durationDays': 1, 'isActive': true},
        {'id': 'p2', 'name': 'Weekly Plan', 'price': 5000, 'durationDays': 7, 'isActive': true},
        {'id': 'p3', 'name': 'Monthly Plan', 'price': 15000, 'durationDays': 30, 'isActive': true},
      ]);
      
      await saveVouchers([
        {'id': 'v1', 'code': 'FREE1', 'durationDays': 1, 'isUsed': false},
        {'id': 'v2', 'code': 'FREE3', 'durationDays': 3, 'isUsed': false},
        {'id': 'v3', 'code': 'FREE7', 'durationDays': 7, 'isUsed': false},
      ]);
    }
  }
}

// ============================================================
// LOGIN, REGISTER, HOME, PACKAGES, PAYMENT, VOUCHER, ACCOUNT, ADMIN...
// ============================================================
// (All your existing screens remain unchanged. We keep the VPN status logic.)

// ============================================================
// We only adapt the HomeScreen to use VpnStatus
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DB();
  Map<String, dynamic>? user;
  Map<String, dynamic>? sub;
  bool loading = true;
  bool _vpnConnected = false;  // simpler bool

  @override
  void initState() {
    super.initState();
    loadData();
    _listenToVpnStatus();
  }

  void _listenToVpnStatus() {
    VpnService.status.listen((connected) {
      setState(() {
        _vpnConnected = connected;
      });
    });
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    user = await db.getCurrentUser();
    if (user != null) sub = await db.getActiveSubscription(user!['id']);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [const Text('SPENIX', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)), const Text('INTERNET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
        actions: [IconButton(icon: const Icon(Icons.person, color: Colors.cyan), onPressed: () => Get.toNamed('/account'))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, ${user?['name'] ?? 'Guest'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: sub != null ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)] : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.05)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sub != null ? Colors.green : Colors.red),
                      ),
                      child: Column(
                        children: [
                          Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: sub != null ? Colors.green : Colors.red)), const SizedBox(width: 8), Text(sub != null ? 'CONNECTED' : 'DISCONNECTED', style: TextStyle(color: sub != null ? Colors.green : Colors.red, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 16),
                          Text(sub != null ? 'Active Plan' : 'No Active Subscription', style: const TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 16),
                          Row(children: [Expanded(child: ElevatedButton(onPressed: () => Get.toNamed('/packages'), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan), child: const Text('BUY INTERNET')))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _vpnConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _vpnConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _vpnConnected ? Icons.vpn_key : Icons.vpn_key_off,
                            color: _vpnConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _vpnConnected ? '🟢 VPN Connected' : '🔴 VPN Disconnected',
                            style: TextStyle(
                              color: _vpnConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_vpnConnected)
                            TextButton(
                              onPressed: () async {
                                await VpnService.disconnect();
                                Get.snackbar('Disconnected', 'VPN disconnected');
                              },
                              child: Text('Disconnect', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [Expanded(child: _quickAction('Packages', Icons.shopping_bag, Colors.cyan, () => Get.toNamed('/packages'))), const SizedBox(width: 12), Expanded(child: _quickAction('Voucher', Icons.card_giftcard, Colors.orange, () => Get.toNamed('/voucher')))]),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF1A1F3A), border: Border(top: BorderSide(color: Colors.grey[800]!))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          IconButton(icon: const Icon(Icons.home, color: Colors.cyan), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_bag, color: Colors.grey), onPressed: () => Get.toNamed('/packages')),
          IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.grey), onPressed: () => Get.toNamed('/voucher')),
          IconButton(icon: const Icon(Icons.person, color: Colors.grey), onPressed: () => Get.toNamed('/account')),
        ]),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 12))])),
    );
  }
}

// ============================================================
// THE REST OF YOUR SCREENS (Packages, Payment, Voucher, Account, Admin...)
// ============================================================
// Use the same code you already have – no changes needed.
// Just make sure your PaymentScreen calls VpnService.connect(...)
// as we already implemented.

// ============================================================
// END OF FILE
// ============================================================
