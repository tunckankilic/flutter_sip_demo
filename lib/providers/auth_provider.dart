import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Giriş Fonksiyonu
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Kayıt Fonksiyonu
  Future<void> signUp(String name, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // SIP kullanıcı adını ve şifresini güvenli bir şekilde oluştur
      final String sipUsername = email
          .split('@')[0]
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      // Güvenli rastgele şifre oluştur
      final String sipPassword =
          List.generate(12, (index) {
            final random =
                Random().nextInt(94) + 33; // ASCII 33-126 arası karakterler
            return String.fromCharCode(random);
          }).join();

      // Kullanıcı bilgilerini Firestore'a kaydet
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'sipUsername': sipUsername,
        'sipPassword': sipPassword,
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'allowVideoCall': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış Fonksiyonu
  Future<void> signOut() async {
    try {
      // Çıkış yapmadan önce kullanıcının online durumunu false yap
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Kullanıcı Durumunu Güncelleme
  Future<void> updateUserStatus(bool isOnline) async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'online': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
      });
    }
  }
}
