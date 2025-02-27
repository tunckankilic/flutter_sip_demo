import 'package:sip_ua/sip_ua.dart';

class MySipUaHelperListener implements SipUaHelperListener {
  final Function(Call, CallState) onCallStateChangedCallback;

  MySipUaHelperListener({required this.onCallStateChangedCallback});

  @override
  void callStateChanged(Call call, CallState state) {
    onCallStateChangedCallback(call, state);
  }

  @override
  void registrationStateChanged(RegistrationState state) {}

  @override
  void transportStateChanged(TransportState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}
}
