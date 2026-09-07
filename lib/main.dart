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

// ============================================================
// MAIN
// ============================================================

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
// SECURE VOUCHER GENERATOR
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

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
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
    final subscriptions = await getSubscriptions();

    subscriptions.add(subscription);

    await saveSubscriptions(subscriptions);
  }

  Future<Map<String, dynamic>?> getActiveSubscription() async {
    final user = await getCurrentUser();

    if (user == null) return null;

    final subscriptions = await getSubscriptions();

    final now = DateTime.now();

    for (final sub in subscriptions.reversed) {
      if (sub['userId'] != user['id']) continue;

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

    final normalized = code.trim().toUpperCase();

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

    final normalized = code.trim().toUpperCase();

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
      vouchers[index]['usedBy'] = user['id'];
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
    return prefs.getBool('gateway_mode') ?? false;
  }

  Future<void> setGatewayMode(bool value) async {
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

    final packages = await getPackages();

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

    // No automatic vouchers are created.
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

        colorScheme: ColorScheme.fromSeed(
          seedColor: spenixCyan,
          brightness: Brightness.dark,
        ),

        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: spenixCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: spenixCyan,
            foregroundColor: Colors.black,
            minimumSize:
                const Size(
              double.infinity,
              52,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
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
        GetPage(
          name: '/packages',
          page: () => const PackagesScreen(),
        ),
        GetPage(
          name: '/voucher',
          page: () => const VoucherScreen(),
        ),
        GetPage(
          name: '/account',
          page: () => const AccountScreen(),
        ),
        GetPage(
          name: '/admin',
          page: () => const AdminDashboard(),
        ),
        GetPage(
          name: '/admin/users',
          page: () => const AdminUsersScreen(),
        ),
        GetPage(
          name: '/admin/packages',
          page: () => const AdminPackagesScreen(),
        ),
        GetPage(
          name: '/admin/payments',
          page: () => const AdminPaymentsScreen(),
        ),
        GetPage(
          name: '/admin/vouchers',
          page: () => const AdminVouchersScreen(),
        ),
        GetPage(
          name: '/admin/settings',
          page: () => const AdminSettingsScreen(),
        ),
      ],
    );
  }
}

// ============================================================
// COMMON APP BAR
// ============================================================

AppBar spenixAppBar(
  String title, {
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: spenixDark,
    foregroundColor: Colors.white,
    actions: actions,
  );
}

// ============================================================
// PHONE FIELD
// ============================================================

Widget ugandaPhoneField(
  TextEditingController controller, {
  String label = 'Phone Number',
}) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.phone,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ],
    decoration: InputDecoration(
      labelText: label,
      hintText: '07XXXXXXXX',
      prefixIcon: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '🇺🇬',
          style: TextStyle(
            fontSize: 23,
          ),
        ),
      ),
    ),
  );
}

// ============================================================
// SPLASH
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
    start();
  }

  Future<void> start() async {
    final db = DB();

    await db.init();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final user =
        await db.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      if (user['role'] == 'admin') {
        Get.offAllNamed('/admin');
      } else {
        Get.offAllNamed('/home');
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: spenixCyan,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.wifi,
                size: 55,
                color: spenixCyan,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'SPENIX',
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
                color: spenixCyan,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'INTERNET',
              style: TextStyle(
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(
              color: spenixCyan,
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
  final phone =
      TextEditingController();

  final password =
      TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  final db = DB();

  @override
  void initState() {
    super.initState();
    db.init();
  }

  Future<void> doLogin() async {
    final normalized =
        normalizeUgandaPhone(
      phone.text,
    );

    if (!isValidUgandaPhone(
      normalized,
    )) {
      Get.snackbar(
        'Invalid Phone',
        'Enter a valid 10-digit Uganda phone number.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.text.isEmpty) {
      Get.snackbar(
        'Missing Password',
        'Enter your password.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await db.init();

    final user = await db.login(
      normalized,
      password.text,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (user == null) {
      Get.snackbar(
        'Login Failed',
        'Phone number or password is incorrect.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    if (user['role'] == 'admin') {
      Get.offAllNamed('/admin');
    } else {
      Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 50),

              const Icon(
                Icons.wifi,
                color: spenixCyan,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                'Welcome to Spenix',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Connect to the Spenix Internet',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 40),

              ugandaPhoneField(phone),

              const SizedBox(height: 15),

              TextField(
                controller: password,
                obscureText: hidePassword,
                decoration:
                    InputDecoration(
                  labelText:
                      'Password',
                  prefixIcon:
                      const Icon(
                    Icons.lock,
                    color:
                        spenixCyan,
                  ),
                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons
                              .visibility
                          : Icons
                              .visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : doLogin,
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.black,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Get.toNamed(
                    '/register',
                  );
                },
                child: const Text(
                  'Create New Account',
                  style: TextStyle(
                    color:
                        spenixCyan,
                  ),
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
  final name =
      TextEditingController();

  final phone =
      TextEditingController();

  final password =
      TextEditingController();

  final confirm =
      TextEditingController();

  bool loading = false;

  final db = DB();

  Future<void> doRegister() async {
    final normalized =
        normalizeUgandaPhone(
      phone.text,
    );

    if (name.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Name',
        'Enter your name.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    if (!isValidUgandaPhone(
      normalized,
    )) {
      Get.snackbar(
        'Invalid Phone',
        'Enter a valid 10-digit Uganda phone number.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.text.length < 6) {
      Get.snackbar(
        'Weak Password',
        'Password must have at least 6 characters.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.text !=
        confirm.text) {
      Get.snackbar(
        'Password Error',
        'Passwords do not match.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await db.init();

    final existing =
        await db.getUserByPhone(
      normalized,
    );

    if (existing != null) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Already Registered',
        'That phone number is already registered.',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }

    final user = {
      'id': const Uuid().v4(),
      'name': name.text.trim(),
      'phone': normalized,
      'password': password.text,
      'role': 'user',
      'active': true,
      'createdAt':
          DateTime.now()
              .toIso8601String(),
    };

    await db.addUser(user);

    await db.login(
      normalized,
      password.text,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar(
        'Create Account',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Full Name',
                  prefixIcon:
                      Icon(
                    Icons.person,
                    color:
                        spenixCyan,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              ugandaPhoneField(phone),

              const SizedBox(height: 15),

              TextField(
                controller: password,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Password',
                  prefixIcon:
                      Icon(
                    Icons.lock,
                    color:
                        spenixCyan,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirm,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Confirm Password',
                  prefixIcon:
                      Icon(
                    Icons.lock_outline,
                    color:
                        spenixCyan,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed:
                    loading
                        ? null
                        : doRegister,
                child: loading
                    ? const CircularProgressIndicator(
                        color:
                            Colors.black,
                      )
                    : const Text(
                        'CREATE ACCOUNT',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
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
// HOME
// ============================================================

class HomeScreen
    extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final db = DB();

  Map<String, dynamic>? user;

  // Kept for future payments/subscriptions.
  Map<String, dynamic>?
      subscription;

  bool _vpnConnected = false;
  bool _connecting = false;

  Timer? _connectionTimeout;

  late AnimationController
      _ringController;

  StreamSubscription?
      _vpnSubscription;

  @override
  void initState() {
    super.initState();

    _ringController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 1),
    )..repeat();

    load();

    _vpnSubscription =
        VpnService.status.listen(
      (connected) {
        if (!mounted) return;

        setState(() {
          _vpnConnected =
              connected;

          if (connected) {
            _connecting = false;
            _connectionTimeout
                ?.cancel();
          }
        });
      },
    );
  }

  Future<void> load() async {
    await db.init();

    user =
        await db.getCurrentUser();

    // Subscription is only displayed/kept
    // for future use. It does NOT block VPN.
    subscription =
        await db.getActiveSubscription();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _connectionTimeout?.cancel();
    _vpnSubscription?.cancel();
    _ringController.dispose();

    super.dispose();
  }

  // ==========================================================
  // FREE CONNECT
  // ==========================================================

  Future<void> _handleConnect() async {
    // Disconnect if already connected.
    if (_vpnConnected) {
      await _disconnect();
      return;
    }

    // Prevent double taps.
    if (_connecting) return;

    setState(() {
      _connecting = true;
    });

    _connectionTimeout?.cancel();

    _connectionTimeout =
        Timer(
      const Duration(seconds: 15),
      () {
        if (!mounted) return;

        if (!_vpnConnected) {
          setState(() {
            _connecting = false;
          });

          Get.snackbar(
            'Connection Failed',
            'Spenix could not connect. Check your Internet connection and try again.',
            snackPosition:
                SnackPosition.BOTTOM,
            duration:
                const Duration(
              seconds: 5,
            ),
          );
        }
      },
    );

    try {
      await VpnService.connect(
        username:
            user?['id'] ?? 'user',
        password: 'pass',
      );

      // Do not claim connected here.
      // Wait for VpnService.status.

      if (VpnService.isConnected) {
        if (!mounted) return;

        _connectionTimeout?.cancel();

        setState(() {
          _vpnConnected = true;
          _connecting = false;
        });

        Get.snackbar(
          'Connected',
          'Spenix VPN is connected.',
          snackPosition:
              SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      _connectionTimeout?.cancel();

      if (!mounted) return;

      setState(() {
        _connecting = false;
        _vpnConnected = false;
      });

      Get.snackbar(
        'Connection Failed',
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        snackPosition:
            SnackPosition.BOTTOM,
        duration:
            const Duration(seconds: 5),
      );
    }
  }

  Future<void> _disconnect() async {
    _connectionTimeout?.cancel();

    try {
      await VpnService.disconnect();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _vpnConnected = false;
      _connecting = false;
    });

    Get.snackbar(
      'Disconnected',
      'You are disconnected from Spenix.',
      snackPosition:
          SnackPosition.BOTTOM,
    );
  }

  // FREE TEST BUTTON
  Color get buttonColor {
    if (_vpnConnected) {
      return spenixGreen;
    }

    if (_connecting) {
      return spenixCyan;
    }

    return spenixCyan;
  }

  String get buttonText {
    if (_connecting) {
      return 'CONNECTING...';
    }

    if (_vpnConnected) {
      return 'DISCONNECT';
    }

    return 'TAP TO\nCONNECT';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            spenixDark,
        title: const Text(
          'Spenix Internet',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
            ),
            onPressed: () {
              Get.toNamed(
                '/account',
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding:
              const EdgeInsets.all(20),
          children: [
            Text(
              'Hello, ${user?['name'] ?? 'User'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Your Spenix connection',
              style: TextStyle(
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 12),

            // FREE MODE LABEL
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color: spenixGreen
                    .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: spenixGreen
                      .withOpacity(0.30),
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color:
                        spenixGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'FREE TEST MODE',
                    style: TextStyle(
                      color:
                          spenixGreen,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

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
                border: Border.all(
                  color: _vpnConnected
                      ? spenixGreen
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _vpnConnected
                        ? Icons.wifi
                        : Icons.wifi_off,
                    color: _vpnConnected
                        ? spenixGreen
                        : Colors.white54,
                    size: 40,
                  ),

                  const SizedBox(
                    width: 15,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          _vpnConnected
                              ? 'CONNECTED'
                              : _connecting
                                  ? 'CONNECTING...'
                                  : 'DISCONNECTED',
                          style:
                              TextStyle(
                            color:
                                _vpnConnected
                                    ? spenixGreen
                                    : _connecting
                                        ? spenixCyan
                                        : Colors.white70,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          _vpnConnected
                              ? 'Spenix VPN is active'
                              : 'Ready to connect',
                          style:
                              const TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BIG CONNECT BUTTON
            Center(
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  alignment:
                      Alignment.center,
                  children: [
                    if (_connecting)
                      RotationTransition(
                        turns:
                            _ringController,
                        child:
                            Container(
                          width: 205,
                          height: 205,
                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape.circle,
                            border:
                                Border.all(
                              color:
                                  spenixCyan,
                              width: 5,
                            ),
                          ),
                        ),
                      ),

                    if (_connecting)
                      Container(
                        width: 180,
                        height: 180,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                spenixCyan
                                    .withOpacity(
                              0.25,
                            ),
                            width: 5,
                          ),
                        ),
                      ),

                    GestureDetector(
                      onTap:
                          _handleConnect,
                      child:
                          AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds:
                              300,
                        ),
                        width: 160,
                        height: 160,
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color:
                              buttonColor,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  buttonColor
                                      .withOpacity(
                                0.35,
                              ),
                              blurRadius:
                                  30,
                              spreadRadius:
                                  5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                _vpnConnected
                                    ? Icons
                                        .power_settings_new
                                    : Icons.wifi,
                                color:
                                    Colors.black,
                                size: 42,
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                buttonText,
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.black,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize:
                                      14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 35),

            // INFORMATION
            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: spenixCard,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color:
                        spenixCyan,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Spenix is currently in free testing mode. No voucher, package, or payment is required.',
                      style: TextStyle(
                        color:
                            Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // VOUCHER KEPT FOR LATER
            OutlinedButton.icon(
              onPressed: () {
                Get.toNamed(
                  '/voucher',
                );
              },
              icon: const Icon(
                Icons.confirmation_number,
              ),
              label: const Text(
                'USE VOUCHER',
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Get.toNamed(
                  '/packages',
                );
              },
              icon: const Icon(
                Icons.shopping_bag,
              ),
              label: const Text(
                'VIEW PACKAGES',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PACKAGES
// ============================================================

class PackagesScreen
    extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() =>
      _PackagesScreenState();
}

class _PackagesScreenState
    extends State<PackagesScreen> {
  final db = DB();

  List<Map<String, dynamic>>
      packages = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    packages =
        await db.getPackages();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: spenixAppBar(
        'Internet Packages',
      ),
      body: packages.isEmpty
          ? const Center(
              child: Text(
                'No packages available.',
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  packages.length,
              itemBuilder:
                  (context, index) {
                final package =
                    packages[index];

                return Card(
                  color:
                      spenixCard,
                  margin:
                      const EdgeInsets
                          .only(
                    bottom: 15,
                  ),
                  child:
                      Padding(
                    padding:
                        const EdgeInsets
                            .all(
                      18,
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          package[
                                  'name'] ??
                              'Package',
                          style:
                              const TextStyle(
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                            height: 8),

                        Text(
                          '${package['durationDays']} day(s)',
                          style:
                              const TextStyle(
                            color:
                                Colors.white60,
                          ),
                        ),

                        const SizedBox(
                            height: 15),

                        Text(
                          'UGX ${package['price']}',
                          style:
                              const TextStyle(
                            color:
                                spenixCyan,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                            height: 15),

                        ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              '/voucher',
                            );
                          },
                          child:
                              const Text(
                            'ACTIVATE WITH VOUCHER',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// VOUCHER
// ============================================================

class VoucherScreen
    extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() =>
      _VoucherScreenState();
}

class _VoucherScreenState
    extends State<VoucherScreen> {
  final db = DB();

  final code =
      TextEditingController();

  bool loading = false;

  Future<void> apply() async {
    final voucherCode =
        code.text
            .trim()
            .toUpperCase();

    if (voucherCode.isEmpty) {
      Get.snackbar(
        'Voucher Required',
        'Enter your voucher code.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await db.init();

    final voucher =
        await db.getVoucherByCode(
      voucherCode,
    );

    if (voucher == null ||
        voucher['used'] == true) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Invalid Voucher',
        'This voucher is invalid or already used.',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }

    final user =
        await db.getCurrentUser();

    if (user == null) {
      setState(() {
        loading = false;
      });

      Get.offAllNamed('/login');
      return;
    }

    final used =
        await db.useVoucher(
      voucherCode,
    );

    if (!used) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Voucher Error',
        'Unable to use this voucher.',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }

    final days =
        int.tryParse(
              '${voucher['durationDays']}',
            ) ??
            1;

    final expires =
        DateTime.now().add(
      Duration(days: days),
    );

    await db.addSubscription({
      'id': const Uuid().v4(),
      'userId': user['id'],
      'voucher': voucherCode,
      'durationDays': days,
      'startedAt':
          DateTime.now()
              .toIso8601String(),
      'expiresAt':
          expires.toIso8601String(),
    });

    await db.addPayment({
      'id': const Uuid().v4(),
      'userId': user['id'],
      'voucher': voucherCode,
      'amount':
          voucher['price'] ?? 0,
      'status': 'completed',
      'createdAt':
          DateTime.now()
              .toIso8601String(),
    });

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    Get.snackbar(
      'Subscription Activated',
      'Your Spenix subscription is active.',
      snackPosition:
          SnackPosition.BOTTOM,
    );

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar('Voucher'),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.confirmation_number,
              color: spenixCyan,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Enter your Spenix voucher',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: code,
              textCapitalization:
                  TextCapitalization
                      .characters,
              decoration:
                  const InputDecoration(
                labelText:
                    'Voucher Code',
                hintText:
                    'SPX-XXXXXXXXXXXX',
                prefixIcon:
                    Icon(
                  Icons.key,
                  color:
                      spenixCyan,
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  loading
                      ? null
                      : apply,
              child: loading
                  ? const CircularProgressIndicator(
                      color:
                          Colors.black,
                    )
                  : const Text(
                      'ACTIVATE VOUCHER',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT
// ============================================================

class AccountScreen
    extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {
  final db = DB();

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    user =
        await db.getCurrentUser();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> logout() async {
    await db.logout();

    try {
      await VpnService.disconnect();
    } catch (_) {}

    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar('My Account'),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor:
                  spenixCyan,
              child: Icon(
                Icons.person,
                color: Colors.black,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              user?['name'] ?? '',
              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              user?['phone'] ?? '',
              style:
                  const TextStyle(
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 35),

            if (user?['role'] ==
                'admin')
              ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(
                    '/admin',
                  );
                },
                icon:
                    const Icon(
                  Icons
                      .admin_panel_settings,
                ),
                label: const Text(
                  'ADMIN PANEL',
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: logout,
              icon: const Icon(
                Icons.logout,
                color: spenixRed,
              ),
              label: const Text(
                'LOGOUT',
                style: TextStyle(
                  color: spenixRed,
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
// ADMIN DASHBOARD
// ============================================================

class AdminDashboard
    extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {
  final db = DB();

  bool gateway = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    gateway =
        await db.getGatewayMode();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleGateway(
    bool value,
  ) async {
    try {
      if (value) {
        await VpnService
            .startGateway();
      } else {
        await VpnService
            .stopGateway();
      }

      await db.setGatewayMode(
        value,
      );

      if (!mounted) return;

      setState(() {
        gateway = value;
      });

      Get.snackbar(
        'Gateway',
        value
            ? 'Gateway started.'
            : 'Gateway stopped.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gateway Error',
        e.toString(),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> logout() async {
    await db.logout();

    try {
      await VpnService.disconnect();
    } catch (_) {}

    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar(
        'Admin Dashboard',
      ),

      drawer: Drawer(
        backgroundColor:
            spenixDark,
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .admin_panel_settings,
                      color:
                          spenixCyan,
                      size: 60,
                    ),
                    SizedBox(
                        height: 10),
                    Text(
                      'SPENIX ADMIN',
                      style:
                          TextStyle(
                        color:
                            spenixCyan,
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.wifi,
                  color:
                      spenixCyan,
                ),
                title: const Text(
                  'Connect / Home',
                ),
                onTap: () {
                  Get.back();
                  Get.offAllNamed(
                    '/home',
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading:
                    const Icon(
                  Icons.dashboard,
                ),
                title: const Text(
                  'Dashboard',
                ),
                onTap: () {
                  Get.back();
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.people,
                ),
                title: const Text(
                  'Users',
                ),
                onTap: () {
                  Get.toNamed(
                    '/admin/users',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.shopping_bag,
                ),
                title: const Text(
                  'Packages',
                ),
                onTap: () {
                  Get.toNamed(
                    '/admin/packages',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.payment,
                ),
                title: const Text(
                  'Payments',
                ),
                onTap: () {
                  Get.toNamed(
                    '/admin/payments',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.confirmation_number,
                ),
                title: const Text(
                  'Vouchers',
                ),
                onTap: () {
                  Get.toNamed(
                    '/admin/vouchers',
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading:
                    const Icon(
                  Icons.settings,
                ),
                title: const Text(
                  'Admin Account Settings',
                ),
                onTap: () {
                  Get.toNamed(
                    '/admin/settings',
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons.logout,
                  color:
                      spenixRed,
                ),
                title: const Text(
                  'Logout',
                  style:
                      TextStyle(
                    color:
                        spenixRed,
                  ),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const Text(
            'Spenix Control Center',
            style: TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          Card(
            color: spenixCard,
            child:
                SwitchListTile(
              title: const Text(
                'Gateway Mode',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              subtitle: Text(
                gateway
                    ? 'Gateway is ON'
                    : 'Gateway is OFF',
              ),
              value: gateway,
              activeColor:
                  spenixCyan,
              onChanged:
                  toggleGateway,
            ),
          ),

          const SizedBox(height: 20),

          _adminCard(
            Icons.people,
            'Manage Users',
            () => Get.toNamed(
              '/admin/users',
            ),
          ),

          _adminCard(
            Icons.shopping_bag,
            'Manage Packages',
            () => Get.toNamed(
              '/admin/packages',
            ),
          ),

          _adminCard(
            Icons.confirmation_number,
            'Manage Vouchers',
            () => Get.toNamed(
              '/admin/vouchers',
            ),
          ),

          _adminCard(
            Icons.payment,
            'View Payments',
            () => Get.toNamed(
              '/admin/payments',
            ),
          ),

          _adminCard(
            Icons.settings,
            'Admin Account Settings',
            () => Get.toNamed(
              '/admin/settings',
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminCard(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      color: spenixCard,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: spenixCyan,
        ),
        title: Text(title),
        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// ADMIN USERS
// ============================================================

class AdminUsersScreen
    extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
  });

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  final db = DB();

  List<Map<String, dynamic>>
      users = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    users = await db.getUsers();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> toggleUser(
    Map<String, dynamic> user,
  ) async {
    if (user['role'] ==
        'admin') {
      Get.snackbar(
        'Protected',
        'Admin account cannot be disabled here.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    await db.updateUser(
      user['id'],
      {
        'active':
            !(user['active'] ==
                true),
      },
    );

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar('Users'),
      body: ListView.builder(
        padding:
            const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder:
            (context, index) {
          final user =
              users[index];

          return Card(
            color: spenixCard,
            child: ListTile(
              leading:
                  CircleAvatar(
                backgroundColor:
                    user['role'] ==
                            'admin'
                        ? spenixCyan
                        : Colors.white12,
                child: Icon(
                  user['role'] ==
                          'admin'
                      ? Icons
                          .admin_panel_settings
                      : Icons.person,
                  color: user[
                              'role'] ==
                          'admin'
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              title: Text(
                user['name'] ??
                    '',
              ),
              subtitle: Text(
                user['phone'] ??
                    '',
              ),
              trailing:
                  user['role'] ==
                          'admin'
                      ? const Text(
                          'ADMIN',
                          style:
                              TextStyle(
                            color:
                                spenixCyan,
                          ),
                        )
                      : Switch(
                          value:
                              user['active'] ==
                                  true,
                          onChanged:
                              (_) =>
                                  toggleUser(
                            user,
                          ),
                        ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ADMIN PACKAGES
// ============================================================

class AdminPackagesScreen
    extends StatefulWidget {
  const AdminPackagesScreen({
    super.key,
  });

  @override
  State<AdminPackagesScreen> createState() =>
      _AdminPackagesScreenState();
}

class _AdminPackagesScreenState
    extends State<AdminPackagesScreen> {
  final db = DB();

  List<Map<String, dynamic>>
      packages = [];

  final name =
      TextEditingController();

  final days =
      TextEditingController();

  final price =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    packages =
        await db.getPackages();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> addPackage() async {
    if (name.text.trim().isEmpty) {
      return;
    }

    final duration =
        int.tryParse(days.text) ??
            1;

    final amount =
        double.tryParse(
              price.text,
            ) ??
            0;

    await db.addPackage({
      'id': const Uuid().v4(),
      'name': name.text.trim(),
      'durationDays':
          duration,
      'price': amount,
    });

    name.clear();
    days.clear();
    price.clear();

    await load();
  }

  Future<void> deletePackage(
    String id,
  ) async {
    await db.deletePackage(id);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar(
        'Manage Packages',
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Create Package',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: name,
            decoration:
                const InputDecoration(
              labelText:
                  'Package Name',
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: days,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Duration Days',
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: price,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText:
                  'Price UGX',
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed:
                addPackage,
            child: const Text(
              'ADD PACKAGE',
            ),
          ),

          const SizedBox(height: 25),

          ...packages.map(
            (package) => Card(
              color:
                  spenixCard,
              child: ListTile(
                title: Text(
                  package['name'] ??
                      '',
                ),
                subtitle:
                    Text(
                  '${package['durationDays']} days • UGX ${package['price']}',
                ),
                trailing:
                    IconButton(
                  icon:
                      const Icon(
                    Icons.delete,
                    color:
                        spenixRed,
                  ),
                  onPressed:
                      () =>
                          deletePackage(
                    package[
                        'id'],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN PAYMENTS
// ============================================================

class AdminPaymentsScreen
    extends StatefulWidget {
  const AdminPaymentsScreen({
    super.key,
  });

  @override
  State<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState
    extends State<AdminPaymentsScreen> {
  final db = DB();

  List<Map<String, dynamic>>
      payments = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    payments =
        await db.getPayments();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar(
        'Payments',
      ),
      body: payments.isEmpty
          ? const Center(
              child: Text(
                'No payments yet.',
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  payments.length,
              itemBuilder:
                  (context, index) {
                final payment =
                    payments[index];

                return Card(
                  color:
                      spenixCard,
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.payment,
                      color:
                          spenixGreen,
                    ),
                    title: Text(
                      'UGX ${payment['amount'] ?? 0}',
                    ),
                    subtitle:
                        Text(
                      'Voucher: ${payment['voucher'] ?? '-'}\nStatus: ${payment['status'] ?? '-'}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// ADMIN VOUCHERS
// ============================================================

class AdminVouchersScreen
    extends StatefulWidget {
  const AdminVouchersScreen({
    super.key,
  });

  @override
  State<AdminVouchersScreen> createState() =>
      _AdminVouchersScreenState();
}

class _AdminVouchersScreenState
    extends State<AdminVouchersScreen> {
  final db = DB();

  List<Map<String, dynamic>>
      vouchers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    vouchers =
        await db.getVouchers();

    if (mounted) {
      setState(() {});
    }
  }

  Future<String>
      uniqueVoucherCode() async {
    while (true) {
      final code =
          generateSecureVoucherCode();

      final existing =
          await db.getVoucherByCode(
        code,
      );

      if (existing == null) {
        return code;
      }
    }
  }

  // ==========================================================
  // GENERATE VOUCHERS
  // ==========================================================

  Future<void>
      generateVoucher() async {
    final daysController =
        TextEditingController(
      text: '1',
    );

    final countController =
        TextEditingController(
      text: '1',
    );

    final result =
        await Get.dialog<
            Map<String, int>>(
      AlertDialog(
        backgroundColor:
            spenixCard,
        title: const Text(
          'Generate Secure Vouchers',
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            TextField(
              controller:
                  countController,
              keyboardType:
                  TextInputType
                      .number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Number of Vouchers',
              ),
            ),

            const SizedBox(
                height: 12),

            TextField(
              controller:
                  daysController,
              keyboardType:
                  TextInputType
                      .number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Duration Days',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(),
            child:
                const Text(
              'CANCEL',
            ),
          ),

          ElevatedButton(
            onPressed: () {
              final count =
                  int.tryParse(
                        countController
                            .text,
                      ) ??
                      1;

              final days =
                  int.tryParse(
                        daysController
                            .text,
                      ) ??
                      1;

              Get.back(
                result: {
                  'count': count,
                  'days': days,
                },
              );
            },
            child:
                const Text(
              'GENERATE',
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    final count =
        result['count'] ?? 1;

    final days =
        result['days'] ?? 1;

    if (count < 1 ||
        count > 500) {
      Get.snackbar(
        'Invalid Count',
        'Choose between 1 and 500 vouchers.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    for (int i = 0;
        i < count;
        i++) {
      final code =
          await uniqueVoucherCode();

      final voucher = {
        'id':
            const Uuid().v4(),
        'code': code,
        'durationDays':
            days,
        'price': 0,
        'used': false,
        'createdAt':
            DateTime.now()
                .toIso8601String(),
      };

      vouchers.add(
        voucher,
      );
    }

    await db.saveVouchers(
      vouchers,
    );

    await load();

    Get.snackbar(
      'Vouchers Created',
      '$count secure voucher(s) created.',
      snackPosition:
          SnackPosition.BOTTOM,
    );
  }

  // ==========================================================
  // MANUAL VOUCHER
  // ==========================================================

  Future<void>
      createManualVoucher() async {
    final codeController =
        TextEditingController();

    final daysController =
        TextEditingController(
      text: '1',
    );

    final result =
        await Get.dialog<
            Map<String, dynamic>>(
      AlertDialog(
        backgroundColor:
            spenixCard,
        title: const Text(
          'Create Manual Voucher',
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            TextField(
              controller:
                  codeController,
              textCapitalization:
                  TextCapitalization
                      .characters,
              decoration:
                  const InputDecoration(
                labelText:
                    'Your Voucher Code',
                hintText:
                    'MY-SPENIX-001',
              ),
            ),

            const SizedBox(
                height: 12),

            TextField(
              controller:
                  daysController,
              keyboardType:
                  TextInputType
                      .number,
              decoration:
                  const InputDecoration(
                labelText:
                    'Duration Days',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(),
            child:
                const Text(
              'CANCEL',
            ),
          ),

          ElevatedButton(
            onPressed: () {
              final code =
                  codeController
                      .text
                      .trim()
                      .toUpperCase();

              final days =
                  int.tryParse(
                        daysController
                            .text,
                      ) ??
                      0;

              if (code.length < 6) {
                Get.snackbar(
                  'Invalid Code',
                  'Voucher code must have at least 6 characters.',
                  snackPosition:
                      SnackPosition
                          .BOTTOM,
                );
                return;
              }

              if (days < 1) {
                Get.snackbar(
                  'Invalid Duration',
                  'Duration must be at least 1 day.',
                  snackPosition:
                      SnackPosition
                          .BOTTOM,
                );
                return;
              }

              Get.back(
                result: {
                  'code': code,
                  'days': days,
                },
              );
            },
            child:
                const Text(
              'CREATE',
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    final voucherCode =
        result['code'] as String;

    final existing =
        await db.getVoucherByCode(
      voucherCode,
    );

    if (existing != null) {
      Get.snackbar(
        'Code Already Exists',
        'Choose another voucher code.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    vouchers.add({
      'id':
          const Uuid().v4(),
      'code':
          voucherCode,
      'durationDays':
          result['days'],
      'price': 0,
      'used': false,
      'manual': true,
      'createdAt':
          DateTime.now()
              .toIso8601String(),
    });

    await db.saveVouchers(
      vouchers,
    );

    await load();

    Get.snackbar(
      'Voucher Created',
      voucherCode,
      snackPosition:
          SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          spenixAppBar(
        'Manage Vouchers',
      ),

      floatingActionButton:
          FloatingActionButton
              .extended(
        backgroundColor:
            spenixCyan,
        foregroundColor:
            Colors.black,
        onPressed:
            generateVoucher,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'GENERATE',
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child:
                OutlinedButton.icon(
              onPressed:
                  createManualVoucher,
              icon: const Icon(
                Icons.edit,
              ),
              label: const Text(
                'CREATE MY OWN VOUCHER CODE',
              ),
            ),
          ),

          Expanded(
            child: vouchers.isEmpty
                ? const Center(
                    child: Text(
                      'No vouchers created.',
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    itemCount:
                        vouchers.length,
                    itemBuilder:
                        (context,
                            index) {
                      final voucher =
                          vouchers[index];

                      final used =
                          voucher[
                                  'used'] ==
                              true;

                      return Card(
                        color:
                            spenixCard,
                        child:
                            ListTile(
                          leading:
                              Icon(
                            used
                                ? Icons
                                    .check_circle
                                : Icons
                                    .confirmation_number,
                            color: used
                                ? Colors
                                    .white38
                                : spenixCyan,
                          ),
                          title:
                              Text(
                            voucher[
                                    'code'] ??
                                '',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color: used
                                  ? Colors
                                      .white38
                                  : Colors
                                      .white,
                            ),
                          ),
                          subtitle:
                              Text(
                            '${voucher['durationDays']} day(s) • ${used ? 'USED' : 'AVAILABLE'}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN SETTINGS
// ============================================================

class AdminSettingsScreen
    extends StatefulWidget {
  const AdminSettingsScreen({
    super.key,
  });

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  final db = DB();

  final phone =
      TextEditingController();

  final currentPassword =
      TextEditingController();

  final newPassword =
      TextEditingController();

  final confirmPassword =
      TextEditingController();

  Map<String, dynamic>? admin;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await db.init();

    final current =
        await db.getCurrentUser();

    if (current == null ||
        current['role'] !=
            'admin') {
      Get.offAllNamed('/login');
      return;
    }

    admin = current;

    phone.text =
        current['phone'] ?? '';

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void>
      saveSettings() async {
    if (admin == null) return;

    final newPhone =
        normalizeUgandaPhone(
      phone.text,
    );

    if (!isValidUgandaPhone(
      newPhone,
    )) {
      Get.snackbar(
        'Invalid Phone',
        'Enter a valid 10-digit Uganda phone number.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    final changingPassword =
        newPassword.text.isNotEmpty ||
            confirmPassword
                .text
                .isNotEmpty;

    if (changingPassword) {
      if (currentPassword.text !=
          admin!['password']) {
        Get.snackbar(
          'Wrong Password',
          'Your current password is incorrect.',
          snackPosition:
              SnackPosition.BOTTOM,
        );
        return;
      }

      if (newPassword.text.length <
          6) {
        Get.snackbar(
          'Weak Password',
          'New password must have at least 6 characters.',
          snackPosition:
              SnackPosition.BOTTOM,
        );
        return;
      }

      if (newPassword.text !=
          confirmPassword.text) {
        Get.snackbar(
          'Password Error',
          'New passwords do not match.',
          snackPosition:
              SnackPosition.BOTTOM,
        );
        return;
      }
    }

    final existing =
        await db.getUserByPhone(
      newPhone,
    );

    if (existing != null &&
        existing['id'] !=
            admin!['id']) {
      Get.snackbar(
        'Phone Already Used',
        'Another account already uses this phone number.',
        snackPosition:
            SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final changes =
        <String, dynamic>{
      'phone': newPhone,
    };

    if (changingPassword) {
      changes['password'] =
          newPassword.text;
    }

    await db.updateUser(
      admin!['id'],
      changes,
    );

    admin = {
      ...admin!,
      ...changes,
    };

    currentPassword.clear();
    newPassword.clear();
    confirmPassword.clear();

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    Get.snackbar(
      'Settings Saved',
      'Your admin login details have been updated.',
      snackPosition:
          SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                spenixCyan,
          ),
        ),
      );
    }

    return Scaffold(
      appBar:
          spenixAppBar(
        'Admin Account Settings',
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.admin_panel_settings,
            color: spenixCyan,
            size: 80,
          ),

          const SizedBox(height: 20),

          const Text(
            'Admin Login',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ugandaPhoneField(
            phone,
            label:
                'Admin Phone / Login',
          ),

          const SizedBox(height: 30),

          const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller:
                currentPassword,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Current Password',
              prefixIcon:
                  Icon(
                Icons.lock,
                color:
                    spenixCyan,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                newPassword,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'New Password',
              prefixIcon:
                  Icon(
                Icons.lock_outline,
                color:
                    spenixCyan,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                confirmPassword,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Confirm New Password',
              prefixIcon:
                  Icon(
                Icons.lock_outline,
                color:
                    spenixCyan,
              ),
            ),
          ),

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed:
                saving
                    ? null
                    : saveSettings,
            child: saving
                ? const CircularProgressIndicator(
                    color:
                        Colors.black,
                  )
                : const Text(
                    'SAVE LOGIN DETAILS',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
          ),

          const SizedBox(height: 20),

          const Text(
            'You can change the admin phone/login and password here. For the current offline version, passwords are stored locally.',
            style: TextStyle(
              color:
                  Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
