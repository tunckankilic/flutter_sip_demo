import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sip_demo/screens/call_screen.dart';
import 'package:flutter_sip_demo/service/auth_provider.dart';
import 'package:flutter_sip_demo/service/sip_provider.dart';
import 'package:flutter_sip_demo/sip_ua_listener.dart';
import 'package:provider/provider.dart';
import 'package:sip_ua/sip_ua.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // SIP kaydı başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sipProvider = Provider.of<SipProvider>(context, listen: false);
      sipProvider.register();

      // Kullanıcı durumunu online yap
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUserStatus(true);

      // Call state değişikliklerini dinle
      sipProvider.helper.addSipUaHelperListener(
        MySipUaHelperListener(
          onCallStateChangedCallback: (Call call, CallState state) {
            if (state.state == CallStateEnum.CALL_INITIATION ||
                state.state == CallStateEnum.PROGRESS) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallScreen(call: call)),
              );
            }
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    // Kullanıcı durumunu offline yap
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.updateUserStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sipProvider = Provider.of<SipProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIP Uygulamamız'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              sipProvider.unregister();
              authProvider.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SIP Durum bilgisi
          Container(
            color: sipProvider.registered ? Colors.green[100] : Colors.red[100],
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sipProvider.registered ? Icons.check_circle : Icons.error,
                  color: sipProvider.registered ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  sipProvider.registered
                      ? 'SIP Bağlantısı Aktif'
                      : 'SIP Bağlantısı Yok',
                ),
              ],
            ),
          ),

          // Kullanıcı listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('online', isEqualTo: true)
                      .where('email', isNotEqualTo: authProvider.user?.email)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Çevrimiçi kullanıcı bulunamadı'),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['name'][0] ?? '?'),
                      ),
                      title: Text(user['name'] ?? 'İsimsiz'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: () {
                          sipProvider.makeCall(user['sipUsername']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
