import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  String? _error;
  String? _username;
  String? _message;
  bool _isResending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _username = ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _verify() async {
    if (_username == null) return;
    bool success = await AuthService.verify(_username!, _codeController.text);
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = 'Verification failed');
    }
  }

  void _resendCode() async {
    if (_username == null) return;
    setState(() { _isResending = true; _message = null; });
    bool sent = await AuthService.resendVerification(_username!);
    setState(() {
      _isResending = false;
      _message = sent ? 'Verification code resent!' : 'Failed to resend code.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter verification code for $_username'),
            TextField(controller: _codeController, decoration: InputDecoration(labelText: 'Code')),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            if (_message != null) Text(_message!, style: TextStyle(color: Colors.green)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _verify, child: Text('Verify')),
            SizedBox(height: 8),
            TextButton(
              onPressed: _isResending ? null : _resendCode,
              child: _isResending ? CircularProgressIndicator() : Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
} 