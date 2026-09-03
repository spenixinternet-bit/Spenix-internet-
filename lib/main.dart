import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';
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
// SPLASH SCREEN – DOPE DESIGN
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyan, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi,
                      size: 70,
                      color: Colors.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'SPENIX',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(
                        color: Colors.cyan,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'INTERNET',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.cyan,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'GET READY FOR\nTHE ULTIMATE\nCONNECTION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.withOpacity(0.3), Colors.cyan.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.cyan, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Fast • Stable • Unlimited',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CONNECTING YOU...',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    letterSpacing: 3,
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
// HOME SCREEN – LIVE STATS & DOPE DESIGN
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

  // Live stats (animated)
  double _speed = 0;
  double _uptime = 0;
  int _activeUsers = 1;
  double _dataUsed = 0;
  late AnimationController _statsController;

  @override
  void initState() {
    super.initState();
    _statsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    loadData();
    _listenToVpnStatus();
    _startLiveUpdates();
  }

  void _listenToVpnStatus() {
    VpnService.status.listen((connected) {
      setState(() {
        _vpnConnected = connected;
        if (connected) {
          _statsController.forward();
        } else {
          _statsController.reset();
          _speed = 0;
          _uptime = 0;
          _dataUsed = 0;
        }
      });
    });
  }

  void _startLiveUpdates() {
    // Simulate live data updates
    Future.delayed(Duration.zero, () {
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_vpnConnected) {
          setState(() {
            _speed = 10 + Random().nextInt(50); // 10–60 Mbps
            _uptime += 2; // seconds
            _activeUsers = 1 + Random().nextInt(10);
            _dataUsed += 0.5 + Random().nextDouble() * 1.5;
          });
        }
      });
    });
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    user = await db.getCurrentUser();
    if (user != null) sub = await db.getActiveSubscription(user!['id']);
    setState(() => loading = false);
  }

  Future<void> _handleConnect() async {
    if (sub == null) {
      Get.snackbar('Connection Failed', 'No active subscription. Please buy a package or use a voucher.',
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
        title: Row(
          children: [
            const Text('SPENIX', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 20)),
            const Text('INTERNET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.cyan),
            onPressed: () => Get.toNamed('/account'),
          ),
        ],
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
                    // Welcome
                    Text(
                      'Hello, ${user?['name'] ?? 'Guest'}! 👋',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stay connected with Spenix',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Connection Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _vpnConnected
                              ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)]
                              : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _vpnConnected ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_vpnConnected ? Colors.green : Colors.red).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _vpnConnected ? Colors.green : Colors.red,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_vpnConnected ? Colors.green : Colors.red).withOpacity(0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _vpnConnected ? 'CONNECTED' : 'DISCONNECTED',
                                style: TextStyle(
                                  color: _vpnConnected ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              if (_vpnConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_vpnConnected) ...[
                            // Live stats
                            Row(
                              children: [
                                _buildStat('Speed', '${_speed.toStringAsFixed(0)} Mbps', Icons.speed, Colors.cyan),
                                _buildStat('Uptime', '${(_uptime / 60).toStringAsFixed(0)}m', Icons.timer, Colors.orange),
                                _buildStat('Users', '$_activeUsers', Icons.people, Colors.purple),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStat('Data Used', '${_dataUsed.toStringAsFixed(1)} GB', Icons.storage, Colors.blue),
                                _buildStat('Signal', 'Excellent', Icons.signal_cellular_4_bar, Colors.green),
                                _buildStat('Ping', '${20 + Random().nextInt(40)} ms', Icons.wifi, Colors.yellow),
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
                          ] else ...[
                            const Text(
                              'No Active Connection',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buy a package or use a voucher to connect.',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Round Connect Button
                          Center(
                            child: GestureDetector(
                              onTap: _handleConnect,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _vpnConnected
                                        ? [Colors.green, Colors.green.shade800]
                                        : [Colors.red, Colors.red.shade800],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_vpnConnected ? Colors.green : Colors.red).withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _vpnConnected ? Icons.power_settings_new : Icons.power_off,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _vpnConnected ? 'CONNECTED' : 'TAP TO CONNECT',
                            style: TextStyle(
                              color: _vpnConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_vpnConnected)
                            Text(
                              'Click to disconnect',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            'Buy Package',
                            Icons.shopping_bag,
                            Colors.cyan,
                            () => Get.toNamed('/packages'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            'Use Voucher',
                            Icons.card_giftcard,
                            Colors.orange,
                            () => Get.toNamed('/voucher'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            'My Account',
                            Icons.person,
                            Colors.purple,
                            () => Get.toNamed('/account'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            'Support',
                            Icons.help_outline,
                            Colors.blue,
                            () => Get.snackbar('Support', 'Contact us at support@spenix.com'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, color: Colors.cyan), onPressed: () {}),
            IconButton(icon: const Icon(Icons.shopping_bag, color: Colors.grey), onPressed: () => Get.toNamed('/packages')),
            IconButton(icon: const Icon(Icons.card_giftcard, color: Colors.grey), onPressed: () => Get.toNamed('/voucher')),
            IconButton(icon: const Icon(Icons.person, color: Colors.grey), onPressed: () => Get.toNamed('/account')),
          ],
        ),
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
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// THE REST OF THE SCREENS – KEEP YOUR EXISTING CODE
// (LoginScreen, RegisterScreen, PackagesScreen, VoucherScreen, AccountScreen, AdminScreens, etc.)
// ============================================================
// I'm not repeating them here – use the code you already have.
// Just make sure to include all the DB class and other screens.
// They are unchanged.
