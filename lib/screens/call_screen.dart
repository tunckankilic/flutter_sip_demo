import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sip_demo/call_screen_listener.dart';
import 'package:flutter_sip_demo/service/sip_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';

class CallScreen extends StatefulWidget {
  final Call call;

  const CallScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _speakerOn = false;
  bool _holdCall = false;
  String _callState = 'Bağlanıyor...';
  bool _isIncomingCall = false;
  bool _callAccepted = false;
  String _remoteIdentity = '';

  // İstatistikler için
  bool _showStats = false;
  Timer? _statsTimer;
  String _stats = '';

  @override
  void initState() {
    super.initState();
    _isIncomingCall = widget.call.direction == 'INCOMING';
    _remoteIdentity = widget.call.remote_identity ?? 'Bilinmeyen';
    _initRenderers();
    _registerListeners();

    // Video içeriği varsa speakeri açık başlat
    if (widget.call.remote_has_video) {
      _speakerOn = true;
      Helper.setSpeakerphoneOn(_speakerOn);
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final session = widget.call.session;

    if (session.connection != null &&
        session.connection!.getLocalStreams().isNotEmpty) {
      _localRenderer.srcObject = session.connection!.getLocalStreams()[0];
    }

    if (session.connection != null &&
        session.connection!.getRemoteStreams().isNotEmpty) {
      _remoteRenderer.srcObject = session.connection!.getRemoteStreams()[0];
    }
  }

  void _registerListeners() {
    final sipProvider = Provider.of<SipProvider>(context, listen: false);

    sipProvider.helper.addSipUaHelperListener(
      CallScreenListener(
        callId: widget.call.id,
        onCallStateChanged: (Call call, CallState state) {
          if (call.id != widget.call.id) return;

          setState(() {
            switch (state.state) {
              case CallStateEnum.CALL_INITIATION:
                _callState = 'Çağrı başlatılıyor...';
                break;
              case CallStateEnum.CONNECTING:
                _callState = 'Bağlanıyor...';
                break;
              case CallStateEnum.PROGRESS:
                _callState =
                    state.originator == 'local'
                        ? 'Arıyor...'
                        : 'Gelen arama...';
                break;
              case CallStateEnum.ACCEPTED:
                _callState = 'Çağrı kabul edildi';
                _callAccepted = true;
                break;
              case CallStateEnum.CONFIRMED:
                _callState = 'Görüşme sürüyor';
                _callAccepted = true;
                break;
              case CallStateEnum.HOLD:
                _callState = 'Beklemeye alındı';
                _holdCall = true;
                break;
              case CallStateEnum.UNHOLD:
                _callState = 'Görüşme devam ediyor';
                _holdCall = false;
                break;
              case CallStateEnum.MUTED:
                if (state.audio == true) {
                  _audioMuted = true;
                }
                if (state.video == true) {
                  _videoMuted = true;
                }
                break;
              case CallStateEnum.UNMUTED:
                if (state.audio == true) {
                  _audioMuted = false;
                }
                if (state.video == true) {
                  _videoMuted = false;
                }
                break;
              case CallStateEnum.ENDED:
                _callState = state.cause?.cause ?? 'Çağrı sonlandı';
                _closeScreen();
                break;
              case CallStateEnum.FAILED:
                _callState = state.cause?.cause ?? 'Çağrı başarısız oldu';
                _closeScreen();
                break;
              case CallStateEnum.STREAM:
                if (state.originator == 'remote' && state.stream != null) {
                  _remoteRenderer.srcObject = state.stream;
                } else if (state.originator == 'local' &&
                    state.stream != null) {
                  _localRenderer.srcObject = state.stream;
                }
                break;
              default:
                _callState = 'Bilinmeyen durum';
            }
          });
        },
      ),
    );
  }

  void _closeScreen() {
    // Timer'ı temizle
    _statsTimer?.cancel();

    // Sayfayı kapat ama hemen değil
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });
    Helper.setSpeakerphoneOn(_speakerOn);
  }

  void _toggleAudio() {
    setState(() {
      _audioMuted = !_audioMuted;
    });
    if (_audioMuted) {
      widget.call.mute(true, false);
    } else {
      widget.call.unmute(true, false);
    }
  }

  void _toggleVideo() {
    setState(() {
      _videoMuted = !_videoMuted;
    });
    if (_videoMuted) {
      widget.call.mute(false, true);
    } else {
      widget.call.unmute(false, true);
    }
  }

  void _toggleHold() {
    setState(() {
      _holdCall = !_holdCall;
    });
    if (_holdCall) {
      widget.call.hold();
    } else {
      widget.call.unhold();
    }
  }

  void _hangUp() {
    widget.call.hangup();
    Navigator.pop(context);
  }

  void _answerCall() {
    // Aramanın cevaplandığını bildir
    final options = {
      'mediaConstraints': {'audio': true, 'video': true},
      'pcConfig': {
        'iceServers': [
          {'url': 'stun:stun.l.google.com:19302'},
        ],
      },
    };

    // Speakerphone açık/kapalı ayarla
    Helper.setSpeakerphoneOn(widget.call.remote_has_video);

    // Aramayı cevapla
    widget.call.answer(options);

    setState(() {
      _callAccepted = true;
    });
  }

  // Çağrı istatistiklerini gösterme/gizleme
  void _toggleStats() {
    setState(() {
      _showStats = !_showStats;
    });

    if (_showStats) {
      _updateStats();
      _statsTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _updateStats(),
      );
    } else {
      _statsTimer?.cancel();
    }
  }

  // WebRTC istatistiklerini güncelleme
  Future<void> _updateStats() async {
    if (!mounted || widget.call.peerConnection == null) return;

    try {
      final reports = await widget.call.getStats();

      if (reports != null) {
        String statsText = '';

        for (var report in reports) {
          if (report.type == 'inbound-rtp' || report.type == 'outbound-rtp') {
            final values = report.values;
            final mediaType = values['mediaType'] ?? '';

            if (mediaType == 'audio' || mediaType == 'video') {
              statsText += '$mediaType (${report.type}):\n';

              if (values.containsKey('packetsReceived')) {
                statsText += '   Alınan paket: ${values['packetsReceived']}\n';
              }

              if (values.containsKey('packetsSent')) {
                statsText += '   Gönderilen paket: ${values['packetsSent']}\n';
              }

              if (values.containsKey('bytesReceived')) {
                statsText +=
                    '   Alınan veri: ${((values['bytesReceived'] as int) / 1024).toStringAsFixed(2)} KB\n';
              }

              if (values.containsKey('bytesSent')) {
                statsText +=
                    '   Gönderilen veri: ${((values['bytesSent'] as int) / 1024).toStringAsFixed(2)} KB\n';
              }

              if (values.containsKey('jitter')) {
                statsText += '   Jitter: ${values['jitter']} ms\n';
              }

              if (values.containsKey('framesDecoded')) {
                statsText += '   Çözülen kare: ${values['framesDecoded']}\n';
              }

              statsText += '\n';
            }
          }
        }

        if (mounted) {
          setState(() {
            _stats = statsText;
          });
        }
      }
    } catch (e) {
      debugPrint('İstatistik alma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_callState),
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.analytics_outlined : Icons.analytics),
            onPressed: _toggleStats,
            tooltip: 'İstatistikler',
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Uzak video (büyük ekran)
                Container(
                  color: Colors.black,
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

                // Lokal video (küçük ekran, sağ üst köşede)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),

                // İstatistikler penceresi
                if (_showStats)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _stats,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                // Gelen arama yanıtlama ekranı
                if (_isIncomingCall && !_callAccepted)
                  Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 60),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _remoteIdentity,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gelen Arama',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FloatingActionButton(
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.call_end),
                                onPressed: _hangUp,
                              ),
                              const SizedBox(width: 64),
                              FloatingActionButton(
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.call),
                                onPressed: _answerCall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Kontrol butonları (sadece kabul edilen arama durumunda gösterilir)
          if (!_isIncomingCall || _callAccepted)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _audioMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: _toggleAudio,
                  ),
                  IconButton(
                    icon: Icon(
                      _videoMuted ? Icons.videocam_off : Icons.videocam,
                      color: Colors.white,
                    ),
                    onPressed: _toggleVideo,
                  ),
                  IconButton(
                    icon: Icon(
                      _speakerOn ? Icons.volume_up : Icons.volume_down,
                      color: Colors.white,
                    ),
                    onPressed: _toggleSpeaker,
                  ),
                  IconButton(
                    icon: Icon(
                      _holdCall ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                    onPressed: _toggleHold,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end),
                    onPressed: _hangUp,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
