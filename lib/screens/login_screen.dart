import 'package:flutter/material.dart';
import 'package:flutter_sip_demo/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isLogin) {
        await authProvider.signIn(_email, _password);
      } else {
        await authProvider.signUp(_name, _email, _password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Giriş Yap' : 'Kaydol'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Icon(
                    Icons.sip,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 30),
                if (!_isLogin)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'İsim',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen isminizi girin';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value!,
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Lütfen geçerli bir e-posta girin';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  textInputAction:
                      _isLogin ? TextInputAction.done : TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value!,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isLogin ? 'GİRİŞ YAP' : 'KAYDOL',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Hesabınız yok mu? Kaydolun'
                        : 'Zaten hesabınız var mı? Giriş yapın',
                    style: TextStyle(color: Theme.of(context).primaryColor),
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
