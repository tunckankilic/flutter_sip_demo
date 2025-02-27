import 'package:sip_ua/sip_ua.dart';

class CallScreenListener implements SipUaHelperListener {
  final String? callId;
  final Function(Call, CallState) onCallStateChanged;

  CallScreenListener({required this.callId, required this.onCallStateChanged});

  @override
  void registrationStateChanged(RegistrationState state) {
    // Kullanılmıyor
  }

  @override
  void callStateChanged(Call call, CallState state) {
    if (call.id == callId) {
      onCallStateChanged(call, state);
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    // Kullanılmıyor
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // Kullanılmıyor
  }

  @override
  void onNewNotify(Notify ntf) {
    // Kullanılmıyor
  }
}
