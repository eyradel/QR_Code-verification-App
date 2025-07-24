import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/user_service.dart';
import 'user_info_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scanned = false;
  String? _qrText;
  bool _loading = false;
  String? _error;
  bool _flashOn = false;
  final MobileScannerController _controller = MobileScannerController();

  int? extractUserId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    print('Scanned URI: ' + uri.toString());
    print('Path segments: ' + uri.pathSegments.toString());
    final segments = uri.pathSegments.map((s) => s.toLowerCase()).toList();
    for (int i = 0; i < segments.length - 2; i++) {
      if (segments[i] == 'auth' && segments[i + 1] == 'users') {
        return int.tryParse(segments[i + 2]);
      }
    }
    if (segments.length >= 2 && segments[0] == 'auth' && segments[1] == 'qr-code') {
      final userId = uri.queryParameters['user_id'];
      return userId != null ? int.tryParse(userId) : null;
    }
    return null;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;
    setState(() {
      _scanned = true;
      _qrText = barcode.rawValue;
      _loading = true;
      _error = null;
    });

    final userId = extractUserId(barcode.rawValue!);
    if (userId == null) {
      setState(() {
        _error = 'Invalid QR code format';
        _loading = false;
        _scanned = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code format'), backgroundColor: Colors.red),
      );
      return;
    }

    final response = await UserService.lookupUserById(userId);
    setState(() {
      _loading = false;
    });

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const VerifiedDialog(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserInfoScreen(
            userInfo: jsonEncode(user),
            error: null,
          ),
        ),
      ).then((_) {
        setState(() {
          _scanned = false;
          _qrText = null;
        });
      });
    } else {
      setState(() {
        _error = 'User not found or not accessible (${response.statusCode})';
        _scanned = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B61FF), Color(0xFF5A4FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Scan QR Code'),
            centerTitle: true,
            leading: BackButton(color: Colors.white),
          ),
        ),
      ),
      body: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          // Glassmorphic overlay for frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Place the code inside the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
                ),
              ),
            ),
          ),
          if (_qrText != null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Extracted: $_qrText',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Floating flashlight button
          Positioned(
            top: 32,
            right: 32,
            child: FloatingActionButton(
              heroTag: 'flashlight',
              backgroundColor: theme.colorScheme.primary,
              onPressed: () async {
                final newState = !_flashOn;
                setState(() => _flashOn = newState);
                await _controller.toggleTorch();
              },
              child: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedDialog extends StatelessWidget {
  const VerifiedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
    return Scaffold(
      backgroundColor: Colors.green.withOpacity(0.95),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 120),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verified!',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
} 