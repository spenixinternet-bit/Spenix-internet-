// ============================================================
// SPENIX INTERNET - COMPLETE MAIN.DART
// FREE INTERNET TEST VERSION
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'services/vpn_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SpenixApp());
}

// ============================================================
// COLORS
// ============================================================

const Color spenixCyan = Color(0xFF00E5FF);
const Color spenixDark = Color(0xFF050A10);
const Color spenixCard = Color(0xFF0D1620);
const Color spenixGreen = Color(0xFF00E676);
const Color spenixRed = Color(0xFFFF5252);

// ============================================================
// PHONE HELPERS
// ============================================================

String normalizeUgandaPhone(String input) {
  String phone = input.trim().replaceAll(RegExp(r'\s+'), '');

  if (phone.startsWith('+256')) {
    phone = '0${phone.substring(4)}';
  } else if (phone.startsWith('256')) {
    phone = '0${phone.substring(3)}';
  }

  return phone;
}

bool isValidUgandaPhone(String phone) {
  return RegExp(r'^0[0-9]{9}$').hasMatch(phone);
}

// ============================================================
// VOUCHER GENERATOR
// ============================================================

String generateSecureVoucherCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();

  final code = List.generate(
    16,
    (_) => chars[random.nextInt(chars.length)],
  ).join();

  return 'SPX-$code';
}

// ============================================================
// DATABASE
// ============================================================

class DB {
  static final DB _instance = DB._internal();

  factory DB() => _instance;

  DB._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _seed();
  }

  SharedPreferences get prefs => _prefs!;

  // ==========================================================
  // USERS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = prefs.getString('users');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> saveUsers(
    List<Map<String, dynamic>> users,
  ) async {
    await prefs.setString(
      'users',
      jsonEncode(users),
    );
  }

  Future<void> addUser(
    Map<String, dynamic> user,
  ) async {
    final users = await getUsers();

    users.add(user);

    await saveUsers(users);
  }

  Future<Map<String, dynamic>?> getUserByPhone(
    String phone,
  ) async {
    final users = await getUsers();

    final normalized = normalizeUgandaPhone(phone);

    for (final user in users) {
      if (normalizeUgandaPhone(
            user['phone'] ?? '',
          ) ==
          normalized) {
        return user;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> login(
    String phone,
    String password,
  ) async {
    final user = await getUserByPhone(phone);

    if (user == null) return null;

    if (user['password'] != password) return null;

    if (user['active'] == false) return null;

    await prefs.setString(
      'user',
      jsonEncode(user),
    );

    return user;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final data = prefs.getString('user');

    if (data == null) return null;

    return Map<String, dynamic>.from(
      jsonDecode(data),
    );
  }

  Future<void> logout() async {
    await prefs.remove('user');
  }

  Future<bool> updateUser(
    String userId,
    Map<String, dynamic> changes,
  ) async {
    final users = await getUsers();

    final index = users.indexWhere(
      (u) => u['id'] == userId,
    );

    if (index == -1) return false;

    users[index] = {
      ...users[index],
      ...changes,
    };

    await saveUsers(users);

    final current = await getCurrentUser();

    if (current != null &&
        current['id'] == userId) {
      await prefs.setString(
        'user',
        jsonEncode(users[index]),
      );
    }

    return true;
  }

  // ==========================================================
  // PACKAGES
  // ==========================================================

  Future<List<Map<String, dynamic>>> getPackages() async {
    final data = prefs.getString('packages');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> savePackages(
    List<Map<String, dynamic>> packages,
  ) async {
    await prefs.setString(
      'packages',
      jsonEncode(packages),
    );
  }

  Future<void> addPackage(
    Map<String, dynamic> package,
  ) async {
    final packages = await getPackages();

    packages.add(package);

    await savePackages(packages);
  }

  Future<void> deletePackage(String id) async {
    final packages = await getPackages();

    packages.removeWhere(
      (p) => p['id'] == id,
    );

    await savePackages(packages);
  }

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  Future<List<Map<String, dynamic>>>
      getSubscriptions() async {
    final data = prefs.getString('subscriptions');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> saveSubscriptions(
    List<Map<String, dynamic>> subscriptions,
  ) async {
    await prefs.setString(
      'subscriptions',
      jsonEncode(subscriptions),
    );
  }

  Future<void> addSubscription(
    Map<String, dynamic> subscription,
  ) async {
    final subscriptions =
        await getSubscriptions();

    subscriptions.add(subscription);

    await saveSubscriptions(subscriptions);
  }

  Future<Map<String, dynamic>?>
      getActiveSubscription() async {
    final user = await getCurrentUser();

    if (user == null) return null;

    final subscriptions =
        await getSubscriptions();

    final now = DateTime.now();

    for (final sub in subscriptions.reversed) {
      if (sub['userId'] != user['id']) {
        continue;
      }

      final expiry = DateTime.tryParse(
        sub['expiresAt'] ?? '',
      );

      if (expiry != null &&
          expiry.isAfter(now)) {
        return sub;
      }
    }

    return null;
  }

  // ==========================================================
  // VOUCHERS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getVouchers() async {
    final data = prefs.getString('vouchers');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> saveVouchers(
    List<Map<String, dynamic>> vouchers,
  ) async {
    await prefs.setString(
      'vouchers',
      jsonEncode(vouchers),
    );
  }

  Future<Map<String, dynamic>?> getVoucherByCode(
    String code,
  ) async {
    final vouchers = await getVouchers();

    final normalized =
        code.trim().toUpperCase();

    for (final voucher in vouchers) {
      if ((voucher['code'] ?? '')
              .toString()
              .toUpperCase() ==
          normalized) {
        return voucher;
      }
    }

    return null;
  }

  Future<bool> useVoucher(String code) async {
    final vouchers = await getVouchers();

    final normalized =
        code.trim().toUpperCase();

    final index = vouchers.indexWhere(
      (v) =>
          (v['code'] ?? '')
                  .toString()
                  .toUpperCase() ==
              normalized &&
          v['used'] != true,
    );

    if (index == -1) return false;

    vouchers[index]['used'] = true;

    vouchers[index]['usedAt'] =
        DateTime.now().toIso8601String();

    final user = await getCurrentUser();

    if (user != null) {
      vouchers[index]['usedBy'] =
          user['id'];
    }

    await saveVouchers(vouchers);

    return true;
  }

  // ==========================================================
  // PAYMENTS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getPayments() async {
    final data = prefs.getString('payments');

    if (data == null) return [];

    final List decoded = jsonDecode(data);

    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> addPayment(
    Map<String, dynamic> payment,
  ) async {
    final payments = await getPayments();

    payments.add(payment);

    await prefs.setString(
      'payments',
      jsonEncode(payments),
    );
  }

  // ==========================================================
  // GATEWAY
  // ==========================================================

  Future<bool> getGatewayMode() async {
    return prefs.getBool(
          'gateway_mode',
        ) ??
        false;
  }

  Future<void> setGatewayMode(
    bool value,
  ) async {
    await prefs.setBool(
      'gateway_mode',
      value,
    );
  }

  // ==========================================================
  // SEED
  // ==========================================================

  Future<void> _seed() async {
    final users = await getUsers();

    if (users.isEmpty) {
      await saveUsers([
        {
          'id': 'admin_1',
          'name': 'Admin',
          'phone': '0771208144',
          'password': 'Admin@2024',
          'role': 'admin',
          'active': true,
          'createdAt':
              DateTime.now().toIso8601String(),
        },
        {
          'id': 'user_1',
          'name': 'Test User',
          'phone': '0700000001',
          'password': 'User@2024',
          'role': 'user',
          'active': true,
          'createdAt':
              DateTime.now().toIso8601String(),
        },
      ]);
    }

    final packages =
        await getPackages();

    if (packages.isEmpty) {
      await savePackages([
        {
          'id': const Uuid().v4(),
          'name': 'Daily Plan',
          'durationDays': 1,
          'price': 0,
        },
        {
          'id': const Uuid().v4(),
          'name': 'Weekly Plan',
          'durationDays': 7,
          'price': 0,
        },
        {
          'id': const Uuid().v4(),
          'name': 'Monthly Plan',
          'durationDays': 30,
          'price': 0,
        },
      ]);
    }
  }
}

// ============================================================
// APP
// ============================================================

class SpenixApp extends StatelessWidget {
  const SpenixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spenix Internet',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: spenixDark,
        primaryColor: spenixCyan,
        colorScheme: const ColorScheme.dark(
          primary: spenixCyan,
          secondary: spenixGreen,
        ),
        inputDecorationTheme:
            const InputDecorationTheme(
          filled: true,
          fillColor: spenixCard,
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterScreen(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
        ),
      ],
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await DB().init();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final user =
        await DB().getCurrentUser();

    if (user != null) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi,
              size: 90,
              color: spenixCyan,
            ),
            SizedBox(height: 20),
            Text(
              'SPENIX INTERNET',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: spenixCyan,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Connecting the world',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final p =
        normalizeUgandaPhone(phone.text);

    if (!isValidUgandaPhone(p)) {
      Get.snackbar(
        'Error',
        'Enter a valid Uganda phone number.',
      );
      return;
    }

    if (password.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Enter your password.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await DB().init();

    final user = await DB().login(
      p,
      password.text,
    );

    setState(() {
      loading = false;
    });

    if (user == null) {
      Get.snackbar(
        'Login Failed',
        'Wrong phone number or password.',
      );
      return;
    }

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spenix Internet',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.wifi,
              size: 80,
              color: spenixCyan,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: phone,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText:
                    'Phone Number',
                prefixIcon:
                    Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: password,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText: 'Password',
                prefixIcon:
                    Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Get.toNamed('/register');
              },
              child: const Text(
                'Create New Account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER
// ============================================================

class RegisterScreen
    extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

  Future<void> register() async {
    final p =
        normalizeUgandaPhone(phone.text);

    if (name.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Enter your name.',
      );
      return;
    }

    if (!isValidUgandaPhone(p)) {
      Get.snackbar(
        'Error',
        'Enter a valid Uganda phone number.',
      );
      return;
    }

    if (password.text.length < 4) {
      Get.snackbar(
        'Error',
        'Password must be at least 4 characters.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await DB().init();

    final existing =
        await DB().getUserByPhone(p);

    if (existing != null) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Already Registered',
        'This phone number already has an account.',
      );

      return;
    }

    final user = {
      'id': const Uuid().v4(),
      'name': name.text.trim(),
      'phone': p,
      'password': password.text,
      'role': 'user',
      'active': true,
      'createdAt':
          DateTime.now().toIso8601String(),
    };

    await DB().addUser(user);

    await DB().login(
      p,
      password.text,
    );

    setState(() {
      loading = false;
    });

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Text(
              'CREATE ACCOUNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: spenixCyan,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: name,
              decoration:
                  const InputDecoration(
                labelText: 'Full Name',
                prefixIcon:
                    Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phone,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText:
                    'Phone Number',
                prefixIcon:
                    Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: password,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText: 'Password',
                prefixIcon:
                    Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    loading ? null : register,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'CREATE ACCOUNT',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen
    extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  bool _vpnConnected = false;
  bool _connecting = false;

  StreamSubscription?
      _vpnSubscription;

  Map<String, dynamic>?
      user;

  @override
  void initState() {
    super.initState();

    _loadUser();

    _vpnSubscription =
        VpnService.status.listen(
      (status) {
        if (!mounted) return;

        setState(() {
          _vpnConnected =
              status == 'connected';
        });
      },
    );
  }

  Future<void> _loadUser() async {
    await DB().init();

    final current =
        await DB().getCurrentUser();

    if (!mounted) return;

    setState(() {
      user = current;
    });
  }

  @override
  void dispose() {
    _vpnSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================
  // CONNECT
  // IMPORTANT:
  // NO VOUCHER CHECK
  // NO PAYMENT CHECK
  // NO SUBSCRIPTION CHECK
  // ==========================================================

  Future<void> _handleConnect() async {
    if (_connecting) return;

    if (_vpnConnected) {
      await _disconnect();
      return;
    }

    setState(() {
      _connecting = true;
    });

    try {
      await VpnService.connect(
        username:
            user?['id'] ?? 'user',
        password: 'pass',
      );

      final connected =
          await VpnService.isConnected
              .timeout(
        const Duration(
          seconds: 15,
        ),
        onTimeout: () => false,
      );

      if (!connected) {
        throw Exception(
          'VPN connection failed.',
        );
      }

      if (!mounted) return;

      setState(() {
        _vpnConnected = true;
      });

      Get.snackbar(
        'Connected',
        'Spenix Internet is connected.',
        backgroundColor:
            spenixGreen,
        colorText: Colors.black,
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Connection Failed',
        e.toString(),
        backgroundColor:
            spenixRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await VpnService.disconnect();

      if (!mounted) return;

      setState(() {
        _vpnConnected = false;
      });

      Get.snackbar(
        'Disconnected',
        'Spenix Internet disconnected.',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not disconnect VPN.',
      );
    }
  }

  Future<void> _logout() async {
    await DB().logout();

    try {
      await VpnService.disconnect();
    } catch (_) {}

    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SPENIX INTERNET',
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            Text(
              'Welcome, ${user?['name'] ?? 'User'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'FREE TEST MODE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: spenixGreen,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // STATUS
            Container(
              padding:
                  const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(
                color: spenixCard,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _vpnConnected
                        ? Icons.wifi
                        : Icons.wifi_off,
                    size: 80,
                    color: _vpnConnected
                        ? spenixGreen
                        : spenixRed,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _vpnConnected
                        ? 'CONNECTED'
                        : 'DISCONNECTED',
                    style:
                        TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                      color: _vpnConnected
                          ? spenixGreen
                          : spenixRed,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // CONNECT BUTTON
            SizedBox(
              height: 65,
              child: ElevatedButton(
                onPressed:
                    _connecting
                        ? null
                        : _handleConnect,
                style:
                    ElevatedButton.styleFrom(
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      35,
                    ),
                  ),
                ),
                child: _connecting
                    ? const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          SizedBox(
                            width: 25,
                            height: 25,
                            child:
                                CircularProgressIndicator(),
                          ),
                          SizedBox(width: 15),
                          Text(
                            'CONNECTING...',
                          ),
                        ],
                      )
                    : Text(
                        _vpnConnected
                            ? 'DISCONNECT'
                            : 'CONNECT SPENIX',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            // FREE INTERNET MESSAGE
            Container(
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: spenixCard,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: spenixCyan,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can connect for free during testing. No voucher or payment is required.',
                      style: TextStyle(
                        color:
                            Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
