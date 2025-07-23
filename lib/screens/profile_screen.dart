import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'dart:convert';
import '../utils/secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userInfo;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() { loading = true; error = null; });
    final response = await UserService.fetchCurrentUser();
    if (response.statusCode == 200) {
      setState(() {
        userInfo = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        error = 'Failed to fetch user info (${response.statusCode})';
        loading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await SecureStorage.write('access_token', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logged out successfully', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top orange curve
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6A3D), Color(0xFFFFA53D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Bottom blue curve
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomCurveClipper(),
              child: Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : error != null
                      ? Text(error!, style: const TextStyle(color: Colors.red))
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 60),
                                const Text(
                                  'My Profile',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: const Color(0xFF36D1DC).withOpacity(0.2),
                                        child: Text(
                                          (userInfo?['full_name'] ?? userInfo?['username'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF36D1DC),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _profileTile(Icons.person, 'Username', userInfo?['username']),
                                      _profileTile(Icons.email, 'Email', userInfo?['email']),
                                      _profileTile(Icons.badge, 'Full Name', userInfo?['full_name']),
                                      _profileTile(Icons.phone, 'Mobile', userInfo?['mobile_number']),
                                      _profileTile(Icons.flag, 'Country', userInfo?['country']),
                                      _profileTile(Icons.business, 'Company', userInfo?['company']),
                                      _profileTile(Icons.verified_user, 'Role', userInfo?['role']),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text('Scan QR Code'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF36D1DC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.logout, color: Colors.red),
                                      tooltip: 'Logout',
                                      onPressed: () => _logout(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF36D1DC)),
      title: Text(label),
      subtitle: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// Reuse the same clippers as login page
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 60);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 60);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 