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
    try {
      final response = await UserService.fetchCurrentUser();
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() { userInfo = data; loading = false; });
        } else {
          setState(() { error = 'Unexpected response format'; loading = false; });
        }
      } else if (response.statusCode == 401) {
        setState(() { error = 'Session expired. Please log in again.'; loading = false; });
      } else {
        setState(() { error = 'Failed to fetch user info (${response.statusCode})'; loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'Error: $e'; loading = false; });
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
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerName = userInfo?['full_name'] ?? userInfo?['username'] ?? 'User';
    final headerEmail = userInfo?['email'] ?? '';
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF5A4FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(error!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchUser, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      (headerName as String)[0].toUpperCase(),
                                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          headerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          headerEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                    tooltip: 'Logout',
                                    onPressed: () => _logout(context),
                                  ),
                                ],
                              ),
                            ),
                            // Chips/Stats using real fields
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _infoChip(Icons.verified_user, (userInfo?['role'] ?? '-').toString(), Colors.purple),
                                  _infoChip(Icons.business, (userInfo?['company'] ?? '-').toString(), Colors.orange),
                                  _infoChip(Icons.flag, (userInfo?['country'] ?? '-').toString(), Colors.blue),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Main info card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 8, bottom: 16),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.person, 'Username', userInfo?['username']),
                                    _infoRow(Icons.badge, 'Full Name', userInfo?['full_name']),
                                    _infoRow(Icons.phone, 'Mobile', userInfo?['mobile_number']),
                                    _infoRow(Icons.flag, 'Country', userInfo?['country']),
                                    _infoRow(Icons.business, 'Company', userInfo?['company']),
                                    _infoRow(Icons.stars, 'Subscription', userInfo?['subscription_tier']),
                                    _infoRow(Icons.vpn_key, 'Client ID', userInfo?['client_id']),
                                    _infoRow(Icons.check_circle, 'Active', (userInfo?['is_active'] ?? '').toString()),
                                    _infoRow(Icons.verified, 'Superuser', (userInfo?['is_superuser'] ?? '').toString()),
                                  ],
                                ),
                              ),
                            ),
                            // Action button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code_scanner, size: 28),
                                  label: const Text('Scan QR Code', style: TextStyle(fontSize: 18)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelPadding: const EdgeInsets.only(left: 4, right: 8),
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
} 