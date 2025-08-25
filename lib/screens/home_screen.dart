import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastScanAt;

  int? extractUserId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
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

  bool _shouldThrottleScan() {
    final now = DateTime.now();
    if (_lastScanAt == null) {
      _lastScanAt = now;
      return false;
    }
    final diff = now.difference(_lastScanAt!).inMilliseconds;
    if (diff < 1200) {
      return true;
    }
    _lastScanAt = now;
    return false;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned || _shouldThrottleScan()) return;
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

    try {
      final response = await UserService.lookupUserById(userId);
      setState(() { _loading = false; });

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        if (!mounted) return;
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
        final bodySnippet = response.body.toString();
        final preview = bodySnippet.length > 140 ? bodySnippet.substring(0, 140) + '…' : bodySnippet;
        setState(() {
          _error = 'Status ${response.statusCode}: $preview';
          _scanned = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
        _scanned = false;
      });
      if (!mounted) return;
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
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan frame overlay
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
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))],
                ),
              ),
            ),
          ),
          if (_qrText != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _qrText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _qrText == null ? null : () async {
                      await Clipboard.setData(ClipboardData(text: _qrText!));
                      if (!mounted) return; 
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')), 
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white),
                  ),
                ],
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
          // Camera flip button
          Positioned(
            top: 32,
            left: 32,
            child: FloatingActionButton(
              heroTag: 'flip',
              backgroundColor: theme.colorScheme.primary,
              onPressed: () async { await _controller.switchCamera(); },
              child: const Icon(Icons.cameraswitch, color: Colors.white),
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
    Future.delayed(const Duration(seconds: 2), () { Navigator.of(context).pop(); });
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
            const Text('Verified!', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
} 