import 'package:sip_ua/sip_ua.dart';

class CallScreenListener implements SipUaHelperListener {
  final String? callId;
  final Function(Call, CallState) onCallStateChanged;

  CallScreenListener({required this.callId, required this.onCallStateChanged});

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void callStateChanged(Call call, CallState state) {
    if (call.id == callId) {
      onCallStateChanged(call, state);
    }
  }

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}
}
