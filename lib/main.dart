import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:async';
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
// DATABASE SERVICE (with Gateway methods)
// ============================================================
class DB {
  static final DB _instance = DB._internal();
  factory DB() => _instance;
  DB._internal();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // --- Users ---
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

  // --- Packages ---
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

  // --- Subscriptions ---
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

  // --- Vouchers ---
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

  // --- Payments ---
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

  // --- Gateway Mode ---
  static const String _keyGatewayMode = 'gateway_mode';

  Future<bool> getGatewayMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyGatewayMode) ?? false;
  }

  Future<void> setGatewayMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyGatewayMode, enabled);
  }

  // --- Seed Data ---
  Future<void> seedData() async {
    final users = await getUsers();
    if (users.isEmpty) {
      await addUser({'id': 'admin_1', 'name': 'Admin', 'phone': '0771208144', 'password': 'Admin@2024', 'role': 'admin', 'isActive': true, 'createdAt': DateTime.now().toIso8601String()});
      await addUser({'id': 'user_1', 'name': 'Test User', 'phone': '0700000001', 'password': 'User@2024', 'role': 'user', 'isActive': true, 'createdAt': DateTime.now().toIso8601String()});

      await savePackages([
        {'id': 'p1', 'name': 'Daily Plan', 'price': 0, 'durationDays': 1, 'isActive': true},
        {'id': 'p2', 'name': 'Weekly Plan', 'price': 0, 'durationDays': 7, 'isActive': true},
        {'id': 'p3', 'name': 'Monthly Plan', 'price': 0, 'durationDays': 30, 'isActive': true},
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
// LOGIN SCREEN
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  final db = DB();

  @override
  void initState() {
    super.initState();
    db.seedData();
  }

  void doLogin() async {
    if (phone.text.isEmpty || password.text.isEmpty) {
      Get.snackbar('Error', 'Fill all fields', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => loading = true);
    final user = await db.login(phone.text.trim(), password.text);
    setState(() => loading = false);
    if (user != null) {
      Get.snackbar('Success', 'Welcome ${user['name']}', backgroundColor: Colors.green, colorText: Colors.white);
      Get.offAllNamed(user['role'] == 'admin' ? '/admin' : '/home');
    } else {
      Get.snackbar('Error', 'Invalid credentials', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi, size: 60, color: Colors.cyan),
              const SizedBox(height: 20),
              const Text('SPENIX', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              TextField(
                controller: phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.cyan),
                  prefixText: '+256 ',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.cyan),
                ),
                onSubmitted: (_) => doLogin(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : doLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                  child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No account? ", style: TextStyle(color: Colors.grey[400])),
                  TextButton(
                    onPressed: () => Get.toNamed('/register'),
                    child: const Text('Sign Up', style: TextStyle(color: Colors.cyan)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    Text('Admin Access', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    Text('Phone: 0771208144 / Pass: Admin@2024', style: TextStyle(color: Colors.cyan[400], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER SCREEN
// ============================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  final db = DB();

  void doRegister() async {
    if (name.text.isEmpty || phone.text.isEmpty || password.text.isEmpty) {
      Get.snackbar('Error', 'Fill all fields', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (password.text != confirm.text) {
      Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (password.text.length < 6) {
      Get.snackbar('Error', 'Password must be 6+ chars', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => loading = true);
    final existing = await db.getUserByPhone(phone.text.trim());
    if (existing != null) {
      Get.snackbar('Error', 'Phone already registered', backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => loading = false);
      return;
    }
    final user = {
      'id': const Uuid().v4(),
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'password': password.text,
      'role': 'user',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await db.addUser(user);
    await db.login(phone.text.trim(), password.text);
    setState(() => loading = false);
    Get.snackbar('Success', 'Account created!', backgroundColor: Colors.green, colorText: Colors.white);
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Start with Spenix', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 30),
              TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person, color: Colors.cyan))),
              const SizedBox(height: 16),
              TextField(controller: phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone, color: Colors.cyan), prefixText: '+256 '), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextField(controller: password, style: const TextStyle(color: Colors.white), obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock, color: Colors.cyan))),
              const SizedBox(height: 16),
              TextField(controller: confirm, style: const TextStyle(color: Colors.white), obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: Colors.cyan)), onSubmitted: (_) => doRegister()),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: loading ? null : doRegister, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan), child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account', style: TextStyle(fontSize: 16)))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Have an account? ", style: TextStyle(color: Colors.grey[400])), TextButton(onPressed: () => Get.toNamed('/login'), child: const Text('Sign In', style: TextStyle(color: Colors.cyan)))]),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN (with Live Stats)
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final db = DB();
  Map<String, dynamic>? user;
  Map<String, dynamic>? sub;
  bool loading = true;
  bool _vpnConnected = false;

  // Live stats
  double _speed = 0;
  double _uptime = 0;
  int _activeUsers = 1;
  double _dataUsed = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    loadData();
    _listenToVpnStatus();
    _startLiveUpdates();
  }

  void _listenToVpnStatus() {
    VpnService.status.listen((connected) {
      setState(() {
        _vpnConnected = connected;
        if (!connected) {
          _speed = 0;
          _uptime = 0;
          _dataUsed = 0;
        }
      });
    });
  }

  void _startLiveUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_vpnConnected) {
        setState(() {
          _speed = 10 + (DateTime.now().millisecondsSinceEpoch % 51);
          _uptime += 2;
          _activeUsers = 1 + ((DateTime.now().millisecondsSinceEpoch) % 10);
          _dataUsed += 0.2 + (DateTime.now().millisecondsSinceEpoch % 10) / 10;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    user = await db.getCurrentUser();
    if (user != null) sub = await db.getActiveSubscription(user!['id']);
    setState(() => loading = false);
  }

  Future<void> _handleConnect() async {
    if (sub == null) {
      Get.snackbar('Connection Failed', 'No active subscription. Buy a package or use a voucher.',
          backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 4));
      return;
    }
    if (_vpnConnected) {
      await VpnService.disconnect();
      Get.snackbar('Disconnected', 'VPN disconnected');
      return;
    }
    try {
      await VpnService.connect(
        username: user?['id'] ?? 'user',
        password: 'pass',
      );
      Get.snackbar('Connected', 'You are now connected to Spenix Internet!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Connection Failed', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
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
                    const SizedBox(height: 20),
                    // Round Connect Button
                    Center(
                      child: GestureDetector(
                        onTap: _handleConnect,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _vpnConnected ? [Colors.green, Colors.green.shade800] : [Colors.red, Colors.red.shade800],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_vpnConnected ? Colors.green : Colors.red).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _vpnConnected ? Icons.power_settings_new : Icons.power_off,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _vpnConnected ? 'CONNECTED' : 'TAP TO CONNECT',
                        style: TextStyle(
                          color: _vpnConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Live Stats
                    if (_vpnConnected) ...[
                      Row(
                        children: [
                          _buildStat('Speed', '${_speed.toStringAsFixed(0)} Mbps', Icons.speed, Colors.cyan),
                          _buildStat('Uptime', '${(_uptime / 60).toStringAsFixed(0)}m', Icons.timer, Colors.orange),
                          _buildStat('Users', '$_activeUsers', Icons.people, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStat('Data Used', '${_dataUsed.toStringAsFixed(1)} GB', Icons.storage, Colors.blue),
                          _buildStat('Signal', 'Excellent', Icons.signal_cellular_4_bar, Colors.green),
                          _buildStat('Ping', '${20 + (DateTime.now().millisecondsSinceEpoch % 40)} ms', Icons.wifi, Colors.yellow),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _speed / 60,
                        backgroundColor: Colors.grey[800],
                        color: Colors.cyan,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bandwidth usage: ${(_speed / 60 * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
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

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
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
// PACKAGES SCREEN (Voucher Activation)
// ============================================================
class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final db = DB();
  List<Map<String, dynamic>> packages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    packages = await db.getPackages();
    setState(() => loading = false);
  }

  void _showVoucherDialog(Map<String, dynamic> pkg) {
    final codeController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Enter Voucher Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Package: ${pkg['name']}', style: TextStyle(color: Colors.cyan)),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Voucher Code',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.card_giftcard, color: Colors.orange),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isEmpty) {
                Get.snackbar('Error', 'Enter a code', backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              final voucher = await db.getVoucherByCode(code);
              if (voucher == null || voucher['isUsed']) {
                Get.snackbar('Invalid Voucher', 'Code invalid or used', backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              final user = await db.getCurrentUser();
              if (user == null) {
                Get.snackbar('Error', 'Login required', backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              await db.useVoucher(code, user['id']);
              final sub = {
                'id': const Uuid().v4(),
                'userId': user['id'],
                'voucherId': voucher['id'],
                'packageId': pkg['id'],
                'startDate': DateTime.now().toIso8601String(),
                'expiryDate': DateTime.now().add(Duration(days: pkg['durationDays'] ?? 1)).toIso8601String(),
                'status': 'active',
                'createdAt': DateTime.now().toIso8601String(),
              };
              await db.addSubscription(sub);
              await db.addPayment({
                'id': const Uuid().v4(),
                'userId': user['id'],
                'subscriptionId': sub['id'],
                'amount': 0,
                'method': 'voucher',
                'status': 'success',
                'voucherCode': code,
                'createdAt': DateTime.now().toIso8601String(),
              });
              Get.back();
              Get.snackbar('Success', 'Package activated!', backgroundColor: Colors.green, colorText: Colors.white);
              Get.offAllNamed('/home');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Apply Voucher'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Packages')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: packages.length,
              itemBuilder: (context, i) {
                final p = packages[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p['name'],
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${p['durationDays']} days',
                              style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p['description'] ?? '', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _showVoucherDialog(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text('Activate with Voucher'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// VOUCHER SCREEN
// ============================================================
class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final code = TextEditingController();
  bool loading = false;
  final db = DB();

  Future<void> apply() async {
    final c = code.text.trim().toUpperCase();
    if (c.isEmpty) {
      Get.snackbar('Error', 'Enter code', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => loading = true);
    final voucher = await db.getVoucherByCode(c);
    if (voucher == null || voucher['isUsed']) {
      Get.snackbar('Error', 'Invalid or used voucher', backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => loading = false);
      return;
    }
    final user = await db.getCurrentUser();
    if (user == null) {
      Get.snackbar('Error', 'Login required', backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => loading = false);
      return;
    }
    final packages = await db.getPackages();
    Map<String, dynamic>? matchedPackage;
    for (var p in packages) {
      if (p['durationDays'] == voucher['durationDays']) {
        matchedPackage = p;
        break;
      }
    }
    if (matchedPackage == null) {
      matchedPackage = {
        'id': 'voucher_${voucher['id']}',
        'name': 'Voucher ${voucher['durationDays']} Days',
        'durationDays': voucher['durationDays'],
        'isActive': true,
      };
    }
    await db.useVoucher(c, user['id']);
    final sub = {
      'id': const Uuid().v4(),
      'userId': user['id'],
      'voucherId': voucher['id'],
      'packageId': matchedPackage['id'],
      'startDate': DateTime.now().toIso8601String(),
      'expiryDate': DateTime.now().add(Duration(days: voucher['durationDays'])).toIso8601String(),
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await db.addSubscription(sub);
    await db.addPayment({
      'id': const Uuid().v4(),
      'userId': user['id'],
      'subscriptionId': sub['id'],
      'amount': 0,
      'method': 'voucher',
      'status': 'success',
      'voucherCode': c,
      'createdAt': DateTime.now().toIso8601String(),
    });
    setState(() => loading = false);
    Get.snackbar('Success', 'Voucher applied!', backgroundColor: Colors.green, colorText: Colors.white);
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Voucher')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.card_giftcard, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          const Text('Enter Voucher Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
            child: Row(children: [
              Expanded(child: TextField(controller: code, style: const TextStyle(color: Colors.white, fontSize: 18), decoration: const InputDecoration(hintText: 'Enter code', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)), textCapitalization: TextCapitalization.characters)),
              Padding(padding: const EdgeInsets.all(4), child: ElevatedButton(onPressed: loading ? null : apply, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size(60, 50)), child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Apply'))),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Test Vouchers', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 4),
              Text('FREE1 (1 Day) • FREE3 (3 Days) • FREE7 (7 Days)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// ACCOUNT SCREEN
// ============================================================
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final db = DB();
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    user = await db.getCurrentUser();
    setState(() => loading = false);
  }

  Future<void> logout() async {
    await db.logout();
    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Account')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.cyan.withOpacity(0.2), Colors.cyan.withOpacity(0.05)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyan.withOpacity(0.2))),
                    child: Row(children: [
                      Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.cyan, width: 2)), child: Center(child: Text((user?['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.cyan, fontSize: 30, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user?['name'] ?? 'Guest', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(user?['phone'] ?? '', style: TextStyle(color: Colors.grey[400]))])),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  if (user?['role'] == 'admin')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: () => Get.toNamed('/admin'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Dashboard'))),
                      ]),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: logout, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Logout'))),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// ADMIN DASHBOARD (with Gateway Toggle)
// ============================================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = DB();
  Map<String, dynamic> stats = {};
  bool _gatewayEnabled = false;

  @override
  void initState() {
    super.initState();
    load();
    _loadGatewayState();
  }

  Future<void> _loadGatewayState() async {
    final enabled = await db.getGatewayMode();
    setState(() => _gatewayEnabled = enabled);
  }

  Future<void> load() async {
    final users = await db.getUsers();
    final payments = await db.getPayments();
    final total = payments.where((p) => p['status'] == 'success').fold(0.0, (s, p) => s + (p['amount'] ?? 0));
    setState(() => stats = {'users': users.length, 'payments': payments.length, 'revenue': total});
  }

  void _startGateway() {
    VpnService.startGateway();
    Get.snackbar('Gateway', 'Gateway mode enabled – sharing your internet.',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void _stopGateway() {
    VpnService.stopGateway();
    Get.snackbar('Gateway', 'Gateway mode disabled.', backgroundColor: Colors.orange, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Admin'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)]),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1F3A),
        child: Column(children: [
          Container(padding: const EdgeInsets.symmetric(vertical: 30), child: const Center(child: Text('SPENIX ADMIN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
          _drawerItem(Icons.dashboard, 'Dashboard', '/admin'),
          _drawerItem(Icons.people, 'Users', '/admin/users'),
          _drawerItem(Icons.shopping_bag, 'Packages', '/admin/packages'),
          _drawerItem(Icons.payment, 'Payments', '/admin/payments'),
          _drawerItem(Icons.card_giftcard, 'Vouchers', '/admin/vouchers'),
          const Spacer(),
          _drawerItem(Icons.logout, 'Logout', '/login', color: Colors.red),
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _statCard('Users', '${stats['users'] ?? 0}', Icons.people, Colors.blue),
              _statCard('Payments', '${stats['payments'] ?? 0}', Icons.payment, Colors.green),
              _statCard('Revenue', 'UGX ${(stats['revenue'] ?? 0).toStringAsFixed(0)}', Icons.money, Colors.orange),
              _statCard('Status', 'Online', Icons.wifi, Colors.cyan),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _actionBtn('Users', Icons.people, Colors.blue, '/admin/users'),
                _actionBtn('Packages', Icons.shopping_bag, Colors.green, '/admin/packages'),
                _actionBtn('Payments', Icons.payment, Colors.red, '/admin/payments'),
                _actionBtn('Vouchers', Icons.card_giftcard, Colors.purple, '/admin/vouchers'),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          // ===================== GATEWAY TOGGLE =====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gatewayEnabled ? Colors.green : Colors.grey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _gatewayEnabled ? Icons.settings_ethernet : Icons.settings_ethernet_outlined,
                      color: _gatewayEnabled ? Colors.green : Colors.cyan,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gateway Mode',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _gatewayEnabled ? 'Active – Sharing your internet' : 'Inactive',
                          style: TextStyle(color: _gatewayEnabled ? Colors.green : Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _gatewayEnabled,
                  onChanged: (value) async {
                    setState(() => _gatewayEnabled = value);
                    await db.setGatewayMode(value);
                    if (value) {
                      _startGateway();
                    } else {
                      _stopGateway();
                    }
                  },
                  activeColor: Colors.cyan,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.cyan),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: () {
        Get.back();
        if (route == '/login') {
          db.logout();
          Get.offAllNamed('/login');
        } else {
          Get.toNamed(route);
        }
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color), const Spacer(), Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]), Text(label, style: TextStyle(color: Colors.grey[400]))]));
  }

  Widget _actionBtn(String label, IconData icon, Color color, String route) {
    return ElevatedButton.icon(onPressed: () => Get.toNamed(route), icon: Icon(icon, size: 16), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.3)))));
  }
}

// ============================================================
// ADMIN USERS SCREEN
// ============================================================
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final db = DB();
  List<Map<String, dynamic>> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    users = await db.getUsers();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Users')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text((u['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'] ?? '', style: const TextStyle(color: Colors.white)), Text(u['phone'] ?? '', style: TextStyle(color: Colors.grey[400])), Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: u['role'] == 'admin' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text((u['role'] ?? 'user').toUpperCase(), style: TextStyle(color: u['role'] == 'admin' ? Colors.orange : Colors.blue, fontSize: 10)))])),
                    IconButton(icon: Icon(u['isActive'] ? Icons.check_circle : Icons.block, color: u['isActive'] ? Colors.green : Colors.red), onPressed: () async {
                      final index = users.indexWhere((x) => x['id'] == u['id']);
                      if (index != -1) {
                        users[index]['isActive'] = !users[index]['isActive'];
                        await db.saveUsers(users);
                        load();
                      }
                    }),
                  ]),
                );
              },
            ),
    );
  }
}

// ============================================================
// ADMIN PACKAGES SCREEN
// ============================================================
class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  final db = DB();
  List<Map<String, dynamic>> packages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    packages = await db.getPackages();
    setState(() => loading = false);
  }

  void addDialog() {
    final name = TextEditingController();
    final price = TextEditingController();
    final days = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Add Package', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey))),
          const SizedBox(height: 12),
          TextField(controller: price, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: Colors.grey))),
          const SizedBox(height: 12),
          TextField(controller: days, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Days', labelStyle: TextStyle(color: Colors.grey))),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await db.addPackage({'id': const Uuid().v4(), 'name': name.text.trim(), 'price': double.tryParse(price.text) ?? 0, 'durationDays': int.tryParse(days.text) ?? 1, 'isActive': true, 'createdAt': DateTime.now().toIso8601String()});
              Get.back();
              load();
              Get.snackbar('Success', 'Package added', backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: const Text('Add', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Packages'), actions: [IconButton(icon: const Icon(Icons.add, color: Colors.cyan), onPressed: addDialog)]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: packages.length,
              itemBuilder: (context, i) {
                final p = packages[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('UGX ${p['price']} • ${p['durationDays']} days', style: TextStyle(color: Colors.grey[400]))])),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await db.deletePackage(p['id']);
                      load();
                    }),
                  ]),
                );
              },
            ),
    );
  }
}

// ============================================================
// ADMIN PAYMENTS SCREEN
// ============================================================
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final db = DB();
  List<Map<String, dynamic>> payments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    payments = await db.getPayments();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Payments')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, i) {
                final p = payments[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(p['status'] == 'success' ? Icons.check_circle : Icons.pending, color: p['status'] == 'success' ? Colors.green : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('UGX ${p['amount'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(p['method'] ?? '', style: TextStyle(color: Colors.grey[400]))])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (p['status'] == 'success' ? Colors.green : Colors.orange).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text((p['status'] ?? '').toUpperCase(), style: TextStyle(color: p['status'] == 'success' ? Colors.green : Colors.orange, fontSize: 10))),
                  ]),
                );
              },
            ),
    );
  }
}

// ============================================================
// ADMIN VOUCHERS SCREEN
// ============================================================
class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  final db = DB();
  List<Map<String, dynamic>> vouchers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    vouchers = await db.getVouchers();
    setState(() => loading = false);
  }

  void generate() {
    final count = TextEditingController();
    final days = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Generate Vouchers', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: count, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Count', labelStyle: TextStyle(color: Colors.grey))),
          const SizedBox(height: 12),
          TextField(controller: days, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Days', labelStyle: TextStyle(color: Colors.grey))),
        ]),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final c = int.tryParse(count.text) ?? 5;
              final d = int.tryParse(days.text) ?? 1;
              final List<Map<String, dynamic>> newVouchers = [];
              for (int i = 0; i < c; i++) {
                newVouchers.add({
                  'id': const Uuid().v4(),
                  'code': 'FREE${DateTime.now().millisecondsSinceEpoch % 10000}',
                  'durationDays': d,
                  'isUsed': false,
                  'createdAt': DateTime.now().toIso8601String()
                });
              }
              final all = await db.getVouchers();
              all.addAll(newVouchers);
              await db.saveVouchers(all);
              Get.back();
              load();
              Get.snackbar('Success', '$c vouchers generated', backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: const Text('Generate', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Vouchers'), actions: [IconButton(icon: const Icon(Icons.add, color: Colors.cyan), onPressed: generate)]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vouchers.length,
              itemBuilder: (context, i) {
                final v = vouchers[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1F3A), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(v['code'] ?? '', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold))),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (v['isUsed'] ? Colors.grey : Colors.green).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(v['isUsed'] ? 'USED' : 'VALID', style: TextStyle(color: v['isUsed'] ? Colors.grey : Colors.green, fontSize: 10))),
                    const SizedBox(width: 8),
                    Text('${v['durationDays']}d', style: const TextStyle(color: Colors.white)),
                  ]),
                );
              },
            ),
    );
  }
}
