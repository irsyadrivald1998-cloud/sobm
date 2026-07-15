import 'package:flutter/material.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadBaseUrl();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _checkLoginStatus() async {
    if (await _apiService.isLoggedIn()) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  void _loadBaseUrl() async {
    final url = await _apiService.getBaseUrl();
    _urlController.text = url;
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Save custom API Base URL if configured
      await _apiService.saveBaseUrl(_urlController.text.trim());

      try {
        await _apiService.login(
          _employeeIdController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Berhasil'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: const Color(0xFFD13639),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1F),
          title: const Text(
            'Server Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'API BASE URL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0A0E12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD13639), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Default: ${ApiService.defaultBaseUrl}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _urlController.text = ApiService.defaultBaseUrl;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Reset to Default', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD13639),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 30),
                      child: Center(
                        child: Icon(
                          Icons.verified_user_outlined,
                          size: 70,
                          color: const Color(0xFFD13639),
                        ),
                      ),
                    ),

                    // Title
                    const Text(
                      'SOBM Mobile Check-In',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitoring & Reporting App',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 35),

                    // Employee ID Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMPLOYEE ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _employeeIdController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. hk_001',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFF1C1C1F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFF2C2C2F),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            errorStyle: const TextStyle(
                              color: Color(0xFFD13639),
                              fontSize: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Employee ID is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFF1C1C1F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFF2C2C2F),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFFD13639),
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            errorStyle: const TextStyle(
                              color: Color(0xFFD13639),
                              fontSize: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // Login Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD13639),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF7A1F21),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_forward, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Technical Note info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1F),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2C2C2F)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kredensial Default Pekerja:',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• ID: hk_001\n• Password: password123',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
