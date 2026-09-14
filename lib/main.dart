// ============================================================
// SPENIX INTERNET
// COMPLETE MAIN.DART
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'services/vpn_service.dart';
import 'services/gateway_service.dart';

// ============================================================
// DATABASE
// ============================================================

class DB {
  static late SharedPreferences prefs;

  static const String usersKey = 'users';
  static const String packagesKey = 'packages';
  static const String subscriptionsKey = 'subscriptions';
  static const String vouchersKey = 'vouchers';
  static const String paymentsKey = 'payments';

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(usersKey)) {
      await saveUsers([
        {
          'id': 'admin-001',
          'name': 'Administrator',
          'phone': '0771208144',
          'password': 'Admin@2024',
          'role': 'admin',
        },
        {
          'id': 'user-001',
          'name': 'Test User',
          'phone': '0700000001',
          'password': 'User@2024',
          'role': 'user',
        },
      ]);
    }

    if (!prefs.containsKey(packagesKey)) {
      await savePackages([
        {
          'id': 'daily',
          'name': 'Daily',
          'price': 0,
          'days': 1,
        },
        {
          'id': 'weekly',
          'name': 'Weekly',
          'price': 0,
          'days': 7,
        },
        {
          'id': 'monthly',
          'name': 'Monthly',
          'price': 0,
          'days': 30,
        },
      ]);
    }

    if (!prefs.containsKey(subscriptionsKey)) {
      await prefs.setString(subscriptionsKey, jsonEncode([]));
    }

    if (!prefs.containsKey(vouchersKey)) {
      await prefs.setString(vouchersKey, jsonEncode([]));
    }

    if (!prefs.containsKey(paymentsKey)) {
      await prefs.setString(paymentsKey, jsonEncode([]));
    }
  }

  static List<Map<String, dynamic>> _readList(String key) {
    final String? value = prefs.getString(key);

    if (value == null || value.isEmpty) {
      return [];
    }

    final dynamic decoded = jsonDecode(value);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static Future<void> _writeList(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    await prefs.setString(key, jsonEncode(data));
  }

  // ----------------------------------------------------------
  // USERS
  // ----------------------------------------------------------

  static List<Map<String, dynamic>> getUsers() {
    return _readList(usersKey);
  }

  static Future<void> saveUsers(
    List<Map<String, dynamic>> users,
  ) async {
    await _writeList(usersKey, users);
  }

  static Future<void> addUser(
    Map<String, dynamic> user,
  ) async {
    final users = getUsers();
    users.add(user);
    await saveUsers(users);
  }

  static Map<String, dynamic>? login(
    String phone,
    String password,
  ) {
    final users = getUsers();

    for (final user in users) {
      if (user['phone'] == phone &&
          user['password'] == password) {
        return user;
      }
    }

    return null;
  }

  // ----------------------------------------------------------
  // PACKAGES
  // ----------------------------------------------------------

  static List<Map<String, dynamic>> getPackages() {
    return _readList(packagesKey);
  }

  static Future<void> savePackages(
    List<Map<String, dynamic>> packages,
  ) async {
    await _writeList(packagesKey, packages);
  }

  static Future<void> addPackage(
    Map<String, dynamic> package,
  ) async {
    final packages = getPackages();
    packages.add(package);
    await savePackages(packages);
  }

  static Future<void> deletePackage(
    String id,
  ) async {
    final packages = getPackages();

    packages.removeWhere(
      (package) => package['id'] == id,
    );

    await savePackages(packages);
  }

  // ----------------------------------------------------------
  // SUBSCRIPTIONS
  // ----------------------------------------------------------

  static List<Map<String, dynamic>> getSubscriptions() {
    return _readList(subscriptionsKey);
  }

  static Future<void> saveSubscriptions(
    List<Map<String, dynamic>> subscriptions,
  ) async {
    await _writeList(
      subscriptionsKey,
      subscriptions,
    );
  }

  static Future<void> addSubscription(
    Map<String, dynamic> subscription,
  ) async {
    final subscriptions = getSubscriptions();

    subscriptions.add(subscription);

    await saveSubscriptions(subscriptions);
  }

  static Map<String, dynamic>? getActiveSubscription(
    String userId,
  ) {
    final subscriptions = getSubscriptions();

    final now = DateTime.now();

    for (final subscription in subscriptions.reversed) {
      if (subscription['userId'] != userId) {
        continue;
      }

      final expiry = DateTime.tryParse(
        subscription['expiresAt']?.toString() ?? '',
      );

      if (expiry != null && expiry.isAfter(now)) {
        return subscription;
      }
    }

    return null;
  }

  // ----------------------------------------------------------
  // VOUCHERS
  // ----------------------------------------------------------

  static List<Map<String, dynamic>> getVouchers() {
    return _readList(vouchersKey);
  }

  static Future<void> saveVouchers(
    List<Map<String, dynamic>> vouchers,
  ) async {
    await _writeList(vouchersKey, vouchers);
  }

  static Future<void> addVoucher(
    Map<String, dynamic> voucher,
  ) async {
    final vouchers = getVouchers();

    vouchers.add(voucher);

    await saveVouchers(vouchers);
  }

  static Map<String, dynamic>? getVoucher(
    String code,
  ) {
    final vouchers = getVouchers();

    for (final voucher in vouchers) {
      if (voucher['code']?.toString().toUpperCase() ==
          code.toUpperCase()) {
        return voucher;
      }
    }

    return null;
  }

  static Future<bool> useVoucher(
    String code,
    String userId,
  ) async {
    final vouchers = getVouchers();

    for (final voucher in vouchers) {
      if (voucher['code']?.toString().toUpperCase() ==
          code.toUpperCase()) {
        if (voucher['used'] == true) {
          return false;
        }

        voucher['used'] = true;
        voucher['usedBy'] = userId;
        voucher['usedAt'] =
            DateTime.now().toIso8601String();

        await saveVouchers(vouchers);

        return true;
      }
    }

    return false;
  }

  // ----------------------------------------------------------
  // PAYMENTS
  // ----------------------------------------------------------

  static List<Map<String, dynamic>> getPayments() {
    return _readList(paymentsKey);
  }

  static Future<void> savePayments(
    List<Map<String, dynamic>> payments,
  ) async {
    await _writeList(paymentsKey, payments);
  }

  static Future<void> addPayment(
    Map<String, dynamic> payment,
  ) async {
    final payments = getPayments();

    payments.add(payment);

    await savePayments(payments);
  }
}

// ============================================================
// SESSION
// ============================================================

class Session {
  static Map<String, dynamic>? currentUser;

  static bool get loggedIn =>
      currentUser != null;

  static bool get isAdmin =>
      currentUser?['role'] == 'admin';

  static String get userId =>
      currentUser?['id']?.toString() ?? '';

  static String get phone =>
      currentUser?['phone']?.toString() ?? '';

  static String get name =>
      currentUser?['name']?.toString() ?? 'User';

  static void logout() {
    currentUser = null;
  }
}

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DB.init();

  runApp(
    const SpenixApp(),
  );
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
        scaffoldBackgroundColor:
            const Color(0xFF061316),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
// COMMON UI
// ============================================================

class SpenixLogo extends StatelessWidget {
  final double size;

  const SpenixLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.cyan,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(.25),
            blurRadius: 20,
          ),
        ],
      ),
      child: Icon(
        Icons.wifi,
        size: size * .55,
        color: Colors.cyan,
      ),
    );
  }
}

class SpenixScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const SpenixScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B2025),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.cyan,
              size: 30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

    Future.delayed(
      const Duration(seconds: 2),
      () {
        Get.offAllNamed('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SpenixLogo(size: 100),
            const SizedBox(height: 25),
            const Text(
              'SPENIX',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
                color: Colors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fast • Stable • Unlimited',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 35),
            const CircularProgressIndicator(
              color: Colors.cyan,
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
  final phoneController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    final phone =
        phoneController.text.trim();

    final password =
        passwordController.text;

    if (phone.isEmpty ||
        password.isEmpty) {
      Get.snackbar(
        'Login',
        'Enter phone number and password.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    final user =
        DB.login(phone, password);

    setState(() {
      loading = false;
    });

    if (user == null) {
      Get.snackbar(
        'Login failed',
        'Wrong phone number or password.',
      );
      return;
    }

    Session.currentUser = user;

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SpenixLogo(size: 90),
                const SizedBox(height: 20),
                const Text(
                  'SPENIX INTERNET',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to your account',
                ),
                const SizedBox(height: 35),
                TextField(
                  controller: phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon:
                        Icon(Icons.phone),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller:
                      passwordController,
                  obscureText: hidePassword,
                  decoration:
                      InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                              !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                    border:
                        const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
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
                    'Create new account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER
// ============================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final nameController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  Future<void> register() async {
    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    final password =
        passwordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      Get.snackbar(
        'Registration',
        'Fill in all fields.',
      );
      return;
    }

    final users = DB.getUsers();

    final exists = users.any(
      (user) => user['phone'] == phone,
    );

    if (exists) {
      Get.snackbar(
        'Registration',
        'Phone number already exists.',
      );
      return;
    }

    await DB.addUser({
      'id': const Uuid().v4(),
      'name': name,
      'phone': phone,
      'password': password,
      'role': 'user',
    });

    Get.snackbar(
      'Success',
      'Account created successfully.',
    );

    Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SpenixScaffold(
      title: 'Create Account',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(
                labelText: 'Full name',
                prefixIcon:
                    Icon(Icons.person),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText: 'Phone number',
                prefixIcon:
                    Icon(Icons.phone),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller:
                  passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText: 'Password',
                prefixIcon:
                    Icon(Icons.lock),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: register,
                child: const Text(
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
// HOME
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  GatewayStatus gateway =
      GatewayStatus.waiting();

  Timer? timer;

  bool connecting = false;

  // IMPORTANT:
  // Prevents another gateway check from starting
  // while the previous check is still running.
  bool checkingGateway = false;

  @override
  void initState() {
    super.initState();

    refreshGateway();

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        refreshGateway();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refreshGateway() async {
    // Prevent overlapping checks.
    if (checkingGateway) {
      return;
    }

    checkingGateway = true;

    try {
      final result =
          await GatewayService.check();

      if (!mounted) return;

      setState(() {
        gateway = result;
      });
    } finally {
      checkingGateway = false;
    }
  }

  Future<void> connect() async {
    if (connecting) return;

    setState(() {
      connecting = true;
    });

    final result =
        await VpnService.connect();

    if (mounted) {
      setState(() {
        connecting = false;
      });
    }

    if (!result) {
      Get.snackbar(
        'Spenix VPN',
        VpnService.message.value,
      );
      return;
    }

    await refreshGateway();

    Get.snackbar(
      'Connected',
      'Spenix VPN is connected.',
    );
  }

  Future<void> disconnect() async {
    await VpnService.disconnect();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpenixScaffold(
      title: 'Spenix Internet',
      actions: [
        IconButton(
          onPressed: () {
            Get.toNamed('/account');
          },
          icon: const Icon(Icons.person),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: refreshGateway,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hello, ${Session.name}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'FREE TEST MODE',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: const Color(0xFF0B2025),
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.public,
                      size: 55,
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 12),

                    // IMPORTANT:
                    // Obx makes the VPN message update
                    // immediately when its value changes.
                    Obx(
                      () => Text(
                        VpnService.message.value,
                        textAlign:
                            TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Obx(
                      () => SizedBox(
                        width:
                            double.infinity,
                        height: 60,
                        child: FilledButton(
                          onPressed:
                              connecting
                                  ? null
                                  : VpnService
                                          .isConnected
                                      ? disconnect
                                      : connect,
                          child: connecting
                              ? const CircularProgressIndicator()
                              : Text(
                                  VpnService
                                          .isConnected
                                      ? 'DISCONNECT'
                                      : 'CONNECT SPENIX VPN',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            InfoCard(
              title: 'Gateway',
              value: gateway.online &&
                      gateway.internetWorking
                  ? 'ONLINE'
                  : 'OFFLINE',
              icon: Icons.router,
            ),

            InfoCard(
              title: 'Gateway Internet',
              value:
                  gateway.internetWorking
                      ? 'Working'
                      : 'Not working',
              icon:
                  Icons.wifi_tethering,
            ),

            InfoCard(
              title: 'Your Current Speed',
              value:
                  '${gateway.userSpeeds[Session.userId] ?? gateway.userSpeeds[Session.phone] ?? 0.0} Mbps',
              icon:
                  Icons.speed,
            ),

            const SizedBox(height: 15),

            ListTile(
              leading: const Icon(
                Icons.local_offer,
                color: Colors.cyan,
              ),
              title: const Text(
                'Packages',
              ),
              subtitle: const Text(
                'View available internet packages',
              ),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/packages');
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.confirmation_number,
                color: Colors.cyan,
              ),
              title: const Text(
                'Voucher',
              ),
              subtitle: const Text(
                'Redeem an internet voucher',
              ),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/voucher');
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.cyan,
              ),
              title: const Text(
                'My Account',
              ),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/account');
              },
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

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() =>
      _PackagesScreenState();
}

class _PackagesScreenState
    extends State<PackagesScreen> {
  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();

    packages = DB.getPackages();
  }

  Future<void> activatePackage(
    Map<String, dynamic> package,
  ) async {
    final days =
        int.tryParse(
              package['days']
                      ?.toString() ??
                  '1',
            ) ??
            1;

    final started =
        DateTime.now();

    final expires =
        started.add(
      Duration(days: days),
    );

    await DB.addSubscription({
      'id': const Uuid().v4(),
      'userId': Session.userId,
      'packageId':
          package['id'],
      'packageName':
          package['name'],
      'startedAt':
          started.toIso8601String(),
      'expiresAt':
          expires.toIso8601String(),
      'source': 'package',
    });

    await DB.addPayment({
      'id': const Uuid().v4(),
      'userId': Session.userId,
      'amount':
          package['price'] ?? 0,
      'package':
          package['name'],
      'status': 'completed',
      'date':
          DateTime.now()
              .toIso8601String(),
    });

    Get.snackbar(
      'Package Activated',
      '${package['name']} package activated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpenixScaffold(
      title: 'Internet Packages',
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
                      const Color(0xFF0B2025),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          package['name']
                              .toString(),
                          style:
                              const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Colors.cyan,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          '${package['days']} day(s)',
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Price: ${package['price']}',
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              FilledButton(
                            onPressed: () =>
                                activatePackage(
                              package,
                            ),
                            child:
                                const Text(
                              'ACTIVATE',
                            ),
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

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() =>
      _VoucherScreenState();
}

class _VoucherScreenState
    extends State<VoucherScreen> {
  final controller =
      TextEditingController();

  bool loading = false;

  Future<void> redeem() async {
    final code =
        controller.text.trim();

    if (code.isEmpty) {
      Get.snackbar(
        'Voucher',
        'Enter voucher code.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final voucher =
        DB.getVoucher(code);

    if (voucher == null) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Voucher',
        'Voucher not found.',
      );
      return;
    }

    if (voucher['used'] == true) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Voucher',
        'This voucher has already been used.',
      );
      return;
    }

    final success =
        await DB.useVoucher(
      code,
      Session.userId,
    );

    if (!success) {
      setState(() {
        loading = false;
      });

      Get.snackbar(
        'Voucher',
        'Voucher could not be used.',
      );
      return;
    }

    final days =
        int.tryParse(
              voucher['days']
                      ?.toString() ??
                  '1',
            ) ??
            1;

    final started =
        DateTime.now();

    final expires =
        started.add(
      Duration(days: days),
    );

    await DB.addSubscription({
      'id': const Uuid().v4(),
      'userId': Session.userId,
      'packageId': 'voucher',
      'packageName':
          voucher['packageName'] ??
              'Voucher',
      'startedAt':
          started.toIso8601String(),
      'expiresAt':
          expires.toIso8601String(),
      'source': 'voucher',
    });

    await DB.addPayment({
      'id': const Uuid().v4(),
      'userId': Session.userId,
      'amount':
          voucher['amount'] ?? 0,
      'package':
          voucher['packageName'] ??
              'Voucher',
      'status': 'voucher',
      'date':
          DateTime.now()
              .toIso8601String(),
    });

    setState(() {
      loading = false;
    });

    controller.clear();

    Get.snackbar(
      'Success',
      'Voucher redeemed successfully.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpenixScaffold(
      title: 'Redeem Voucher',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.confirmation_number,
              size: 80,
              color: Colors.cyan,
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your Spenix voucher code.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            TextField(
              controller: controller,
              textCapitalization:
                  TextCapitalization.characters,
              decoration:
                  const InputDecoration(
                labelText: 'Voucher code',
                hintText: 'SPX-XXXXXXXX',
                prefixIcon:
                    Icon(Icons.confirmation_number),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                    loading ? null : redeem,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'REDEEM VOUCHER',
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
// ACCOUNT
// ============================================================

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() =>
      _AccountScreenState();
}

class _AccountScreenState
    extends State<AccountScreen> {
  GatewayStatus gateway =
      GatewayStatus.waiting();

  bool checkingGateway = false;

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    if (checkingGateway) {
      return;
    }

    checkingGateway = true;

    try {
      final result =
          await GatewayService.check();

      if (!mounted) return;

      setState(() {
        gateway = result;
      });
    } finally {
      checkingGateway = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription =
        DB.getActiveSubscription(
      Session.userId,
    );

    return SpenixScaffold(
      title: 'My Account',
      actions: [
        IconButton(
          onPressed: () {
            Session.logout();

            VpnService.disconnect();

            Get.offAllNamed('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: SpenixLogo(size: 85),
          ),
          const SizedBox(height: 20),

          InfoCard(
            title: 'Name',
            value: Session.name,
            icon: Icons.person,
          ),

          InfoCard(
            title: 'Phone',
            value: Session.phone,
            icon: Icons.phone,
          ),

          InfoCard(
            title: 'Subscription',
            value: subscription == null
                ? 'No active package'
                : '${subscription['packageName']}',
            icon: Icons.card_membership,
          ),

          if (subscription != null)
            InfoCard(
              title: 'Expires',
              value:
                  subscription['expiresAt']
                      .toString()
                      .replaceFirst('T', ' '),
              icon: Icons.timer,
            ),

          InfoCard(
            title: 'Current Speed',
            value:
                '${gateway.userSpeeds[Session.userId] ?? gateway.userSpeeds[Session.phone] ?? 0.0} Mbps',
            icon: Icons.speed,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Get.toNamed('/packages');
              },
              child: const Text(
                'VIEW PACKAGES',
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Get.toNamed('/voucher');
              },
              child: const Text(
                'REDEEM VOUCHER',
              ),
            ),
          ),
        ],
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
  GatewayStatus gateway =
      GatewayStatus.waiting();

  Timer? timer;

  bool checkingGateway = false;

  @override
  void initState() {
    super.initState();

    refresh();

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        refresh();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    // Prevent overlapping requests.
    if (checkingGateway) {
      return;
    }

    checkingGateway = true;

    try {
      final result =
          await GatewayService.check();

      if (!mounted) return;

      setState(() {
        gateway = result;
      });
    } finally {
      checkingGateway = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final users =
        DB.getUsers();

    final payments =
        DB.getPayments();

    final vouchers =
        DB.getVouchers();

    return SpenixScaffold(
      title: 'Spenix Control Center',
      actions: [
        IconButton(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () {
            Session.logout();

            Get.offAllNamed('/login');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'GATEWAY STATUS',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            InfoCard(
              title: 'Gateway',
              value: gateway.online
                  ? 'ONLINE'
                  : 'OFFLINE',
              icon: Icons.router,
            ),

            InfoCard(
              title: 'Gateway Internet',
              value: gateway.internetWorking
                  ? 'WORKING'
                  : 'NOT WORKING',
              icon: Icons.public,
            ),

            InfoCard(
              title: 'Incoming Gateway',
              value:
                  '${gateway.incomingMbps.toStringAsFixed(2)} Mbps',
              icon: Icons.download,
            ),

            InfoCard(
              title: 'Total Mbps Used',
              value:
                  '${gateway.usedMbps.toStringAsFixed(2)} Mbps',
              icon: Icons.upload,
            ),

            InfoCard(
              title: 'Online Users',
              value:
                  '${gateway.onlineUsers}',
              icon: Icons.people,
            ),

            Card(
              color:
                  const Color(0xFF0B2025),
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOMMENDATION',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gateway.recommendation,
                      style:
                          const TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gateway.message,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'USER SPEEDS',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _buildUserSpeeds(users),

            const SizedBox(height: 20),

            const Text(
              'CONTROL CENTER',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.people,
              ),
              title:
                  const Text('Users'),
              subtitle:
                  Text('${users.length} users'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed('/admin/users');
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.local_offer,
              ),
              title:
                  const Text('Packages'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  '/admin/packages',
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.payments,
              ),
              title:
                  const Text('Payments'),
              subtitle:
                  Text('${payments.length} payments'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  '/admin/payments',
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.confirmation_number,
              ),
              title:
                  const Text('Vouchers'),
              subtitle:
                  Text('${vouchers.length} vouchers'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  '/admin/vouchers',
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.settings,
              ),
              title:
                  const Text('Settings'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  '/admin/settings',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSpeeds(
    List<Map<String, dynamic>> users,
  ) {
    if (users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No users found.',
          ),
        ),
      );
    }

    return Column(
      children: users.map((user) {
        final id =
            user['id']?.toString() ?? '';

        final phone =
            user['phone']?.toString() ?? '';

        final speed =
            gateway.userSpeeds[id] ??
                gateway.userSpeeds[phone] ??
                0.0;

        return Card(
          color:
              const Color(0xFF0B2025),
          child: ListTile(
            leading: const Icon(
              Icons.person,
              color: Colors.cyan,
            ),
            title: Text(
              user['name']?.toString() ??
                  'User',
            ),
            subtitle: Text(phone),
            trailing: Text(
              '${speed.toStringAsFixed(2)} Mbps',
              style: const TextStyle(
                color: Colors.cyan,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// ADMIN USERS
// ============================================================

class AdminUsersScreen
    extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final users =
        DB.getUsers();

    return SpenixScaffold(
      title: 'Users',
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder:
            (context, index) {
          final user =
              users[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child:
                    Icon(Icons.person),
              ),
              title: Text(
                user['name']
                    .toString(),
              ),
              subtitle: Text(
                '${user['phone']} • ${user['role']}',
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
  Future<void> addPackage() async {
    final nameController =
        TextEditingController();

    final priceController =
        TextEditingController();

    final daysController =
        TextEditingController();

    final result =
        await Get.dialog<bool>(
      AlertDialog(
        title:
            const Text('Add Package'),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            TextField(
              controller:
                  nameController,
              decoration:
                  const InputDecoration(
                labelText: 'Package name',
              ),
            ),
            TextField(
              controller:
                  priceController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Price',
              ),
            ),
            TextField(
              controller:
                  daysController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Days',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(result: false),
            child:
                const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name =
                  nameController
                      .text
                      .trim();

              final price =
                  double.tryParse(
                        priceController
                            .text
                            .trim(),
                      ) ??
                      0;

              final days =
                  int.tryParse(
                        daysController
                            .text
                            .trim(),
                      ) ??
                      1;

              if (name.isEmpty) {
                return;
              }

              await DB.addPackage({
                'id':
                    const Uuid().v4(),
                'name': name,
                'price': price,
                'days': days,
              });

              Get.back(
                result: true,
              );
            },
            child:
                const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> deletePackage(
    String id,
  ) async {
    await DB.deletePackage(id);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final packages =
        DB.getPackages();

    return SpenixScaffold(
      title: 'Manage Packages',
      actions: [
        IconButton(
          onPressed: addPackage,
          icon:
              const Icon(Icons.add),
        ),
      ],
      body: ListView.builder(
        padding:
            const EdgeInsets.all(12),
        itemCount:
            packages.length,
        itemBuilder:
            (context, index) {
          final package =
              packages[index];

          return Card(
            child: ListTile(
              title: Text(
                package['name']
                    .toString(),
              ),
              subtitle: Text(
                '${package['days']} days • Price ${package['price']}',
              ),
              trailing:
                  IconButton(
                onPressed: () =>
                    deletePackage(
                  package['id']
                      .toString(),
                ),
                icon:
                    const Icon(
                  Icons.delete,
                  color:
                      Colors.redAccent,
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
// ADMIN PAYMENTS
// ============================================================

class AdminPaymentsScreen
    extends StatelessWidget {
  const AdminPaymentsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final payments =
        DB.getPayments();

    return SpenixScaffold(
      title: 'Payments',
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
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons.payments,
                      color:
                          Colors.cyan,
                    ),
                    title: Text(
                      '${payment['package']}',
                    ),
                    subtitle: Text(
                      'User: ${payment['userId']}\n'
                      'Status: ${payment['status']}',
                    ),
                    trailing: Text(
                      '${payment['amount']}',
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
  String generateCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final random =
        DateTime.now()
            .microsecondsSinceEpoch;

    String code = '';

    for (int i = 0; i < 10; i++) {
      final index =
          (random + i * 17) %
              chars.length;

      code += chars[index];
    }

    return 'SPX-$code';
  }

  Future<void> createVoucher() async {
    final packageController =
        TextEditingController(
      text: 'Daily',
    );

    final daysController =
        TextEditingController(
      text: '1',
    );

    final amountController =
        TextEditingController(
      text: '0',
    );

    final result =
        await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'Create Voucher',
        ),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            TextField(
              controller:
                  packageController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Package name',
              ),
            ),
            TextField(
              controller:
                  daysController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Days',
              ),
            ),
            TextField(
              controller:
                  amountController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Get.back(
              result: false,
            ),
            child:
                const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code =
                  generateCode();

              final days =
                  int.tryParse(
                        daysController
                            .text,
                      ) ??
                      1;

              final amount =
                  double.tryParse(
                        amountController
                            .text,
                      ) ??
                      0;

              await DB.addVoucher({
                'id':
                    const Uuid().v4(),
                'code': code,
                'packageName':
                    packageController
                        .text
                        .trim(),
                'days': days,
                'amount':
                    amount,
                'used': false,
                'createdAt':
                    DateTime.now()
                        .toIso8601String(),
              });

              Get.back(
                result: true,
              );

              Get.snackbar(
                'Voucher Created',
                code,
              );
            },
            child:
                const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final vouchers =
        DB.getVouchers();

    return SpenixScaffold(
      title: 'Vouchers',
      actions: [
        IconButton(
          onPressed:
              createVoucher,
          icon:
              const Icon(Icons.add),
        ),
      ],
      body: vouchers.isEmpty
          ? const Center(
              child: Text(
                'No vouchers created.',
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  vouchers.length,
              itemBuilder:
                  (context, index) {
                final voucher =
                    vouchers[index];

                return Card(
                  child: ListTile(
                    leading:
                        const Icon(
                      Icons
                          .confirmation_number,
                      color:
                          Colors.cyan,
                    ),
                    title: Text(
                      voucher['code']
                          .toString(),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    subtitle: Text(
                      '${voucher['packageName']} • ${voucher['days']} day(s)',
                    ),
                    trailing: Text(
                      voucher['used'] == true
                          ? 'USED'
                          : 'ACTIVE',
                      style: TextStyle(
                        color:
                            voucher['used'] ==
                                    true
                                ? Colors.red
                                : Colors.green,
                        fontWeight:
                            FontWeight
                                .bold,
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
  final gatewayController =
      TextEditingController(
    text: GatewayService.defaultEndpoint,
  );

  final phoneController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final endpoint =
        await GatewayService.getEndpoint();

    final prefs =
        await SharedPreferences
            .getInstance();

    if (!mounted) return;

    setState(() {
      gatewayController.text =
          endpoint;

      phoneController.text =
          prefs.getString(
                'admin_phone',
              ) ??
              '0771208144';

      passwordController.text =
          prefs.getString(
                'admin_password',
              ) ??
              'Admin@2024';
    });
  }

  Future<void> save() async {
    await GatewayService.setEndpoint(
      gatewayController.text.trim(),
    );

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      'admin_phone',
      phoneController.text.trim(),
    );

    await prefs.setString(
      'admin_password',
      passwordController.text,
    );

    Get.snackbar(
      'Settings',
      'Settings saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpenixScaffold(
      title: 'Admin Settings',
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'GATEWAY API',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller:
                gatewayController,
            decoration:
                const InputDecoration(
              labelText:
                  'Gateway API endpoint',
              hintText:
                  'http://10.8.0.1:8080',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'ADMIN ACCOUNT',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller:
                phoneController,
            keyboardType:
                TextInputType.phone,
            decoration:
                const InputDecoration(
              labelText:
                  'Admin phone',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller:
                passwordController,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Admin password',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: save,
              child:
                  const Text(
                'SAVE SETTINGS',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
