import 'package:flutter/material.dart';
import 'dart:convert';

class UserInfoScreen extends StatelessWidget {
  final String? userInfo;
  final String? error;

  const UserInfoScreen({this.userInfo, this.error, super.key});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (error != null) {
      content = Text(error!, style: const TextStyle(color: Colors.red, fontSize: 18));
    } else if (userInfo != null) {
      try {
        final data = jsonDecode(userInfo!);
        if (data is Map<String, dynamic>) {
          content = Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      child: Text(
                        (data['full_name'] ?? data['username'] ?? 'U')[0].toUpperCase(),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('User Info', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _infoTile(Icons.person, 'Username', data['username']),
                    _infoTile(Icons.email, 'Email', data['email']),
                    _infoTile(Icons.badge, 'Full Name', data['full_name']),
                    _infoTile(Icons.phone, 'Mobile', data['mobile_number']),
                    _infoTile(Icons.flag, 'Country', data['country']),
                    _infoTile(Icons.business, 'Company', data['company']),
                    _infoTile(Icons.verified_user, 'Role', data['role']),
                  ],
                ),
              ),
            ),
          );
        } else {
          content = Text(userInfo!);
        }
      } catch (e) {
        content = Text(userInfo!);
      }
    } else {
      content = const Text('No data');
    }
    return Scaffold(
      appBar: AppBar(title: const Text('User Info'), centerTitle: true),
      body: content,
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label),
      subtitle: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
} 