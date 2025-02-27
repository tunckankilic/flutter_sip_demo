import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:logger/logger.dart';

class SipProvider with ChangeNotifier {
  final SIPUAHelper _helper = SIPUAHelper(
    customLogger: Logger(
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
    ),
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _registered = false;
  Call? _currentCall;
  final List<Call> _calls = [];

  SIPUAHelper get helper => _helper;
  bool get registered => _registered;
  Call? get currentCall => _currentCall;
  List<Call> get calls => _calls;

  SipProvider() {
    _helper.addSipUaHelperListener(
      _SipListener(
        onRegistrationStateChanged: (state) {
          debugPrint('SIP Kayıt Durumu: ${state.state}');
          _registered = state.state == RegistrationStateEnum.REGISTERED;
          notifyListeners();
        },
        onCallStateChanged: (call, state) {
          debugPrint('SIP Çağrı Durumu: ${state.state} - ID: ${call.id}');

          // Mevcut çağrı durumunu güncelle
          _currentCall = call;

          // Çağrılar listesini yönet
          if (state.state == CallStateEnum.CALL_INITIATION) {
            _calls.add(call);
          } else if (state.state == CallStateEnum.ENDED ||
              state.state == CallStateEnum.FAILED) {
            _calls.removeWhere((c) => c.id == call.id);
          }

          notifyListeners();
        },
        onTransportStateChanged: (state) {
          debugPrint('SIP Transport Durumu: ${state.state}');
          notifyListeners();
        },
      ),
    );
  }

  Future<void> register() async {
    try {
      // Kullanıcının SIP bilgilerini Firestore'dan al
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        if (userData != null) {
          final sipUsername = userData['sipUsername'];
          final sipPassword = userData['sipPassword'];

          // FreeSWITCH sunucusu ile bağlantı kur
          final UaSettings settings = UaSettings();

          // WebSocket ayarları
          settings.webSocketUrl = 'ws://127.0.0.1:5066';
          settings.webSocketSettings.allowBadCertificate = true;

          // SIP hesap ayarları
          settings.displayName = user.displayName ?? user.email?.split('@')[0];
          settings.uri = 'sip:$sipUsername@127.0.0.1';
          settings.password = sipPassword;
          settings.authorizationUser = sipUsername;

          await _helper.start(settings);
        }
      }
    } catch (e) {
      debugPrint('SIP Kayıt Hatası: $e');
    }
  }

  void unregister() {
    try {
      _helper.unregister();
      _registered = false;
      notifyListeners();
    } catch (e) {
      debugPrint('SIP Kayıt İptali Hatası: $e');
    }
  }

  void disconnect() {
    try {
      _helper.stop();
      _registered = false;
      _calls.clear();
      _currentCall = null;
      notifyListeners();
    } catch (e) {
      debugPrint('SIP Bağlantı Kapatma Hatası: $e');
    }
  }

  Future<bool> makeCall(
    String targetSipUsername, {
    bool voiceOnly = false,
  }) async {
    if (_helper.connected && _registered) {
      final destination = 'sip:$targetSipUsername@127.0.0.1';
      return await _helper.call(destination, voiceonly: voiceOnly);
    }
    return false;
  }

  void hangUp() {
    if (_currentCall != null) {
      _currentCall!.hangup();
      _currentCall = null;
      notifyListeners();
    }
  }
}

// SIP olaylarını dinleyen yardımcı sınıf
class _SipListener implements SipUaHelperListener {
  final Function(RegistrationState) onRegistrationStateChanged;
  final Function(Call, CallState) onCallStateChanged;
  final Function(TransportState) onTransportStateChanged;

  _SipListener({
    required this.onRegistrationStateChanged,
    required this.onCallStateChanged,
    required this.onTransportStateChanged,
  });

  @override
  void registrationStateChanged(RegistrationState state) {
    onRegistrationStateChanged(state);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    onCallStateChanged(call, state);
  }

  @override
  void transportStateChanged(TransportState state) {
    onTransportStateChanged(state);
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // Bu örnekte kullanılmıyor
  }

  @override
  void onNewNotify(Notify ntf) {
    // Bu örnekte kullanılmıyor
  }
}
