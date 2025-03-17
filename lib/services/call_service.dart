import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Yeni arama başlatıldığında kayıt oluştur
  Future<String> createCallRecord(
    String receiverId,
    String receiverName,
    String callType,
  ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Kullanıcı bilgilerini al
      final callerDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final callerData = callerDoc.data();
      final callerName = callerData?['name'] ?? 'Unknown User';

      // Yeni arama kaydı oluştur
      final callRef = await _firestore.collection('calls').add({
        'callerId': currentUser.uid,
        'callerName': callerName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'startTime': FieldValue.serverTimestamp(),
        'callType': callType, // 'audio' veya 'video'
        'status': 'initiated', // başlangıç durumu
      });

      return callRef.id;
    } catch (e) {
      throw Exception('Arama kaydı oluşturulamadı: $e');
    }
  }

  // Arama sonlandığında kaydı güncelle
  Future<void> updateCallRecord(
    String callId,
    String status, {
    int? duration,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'endTime': FieldValue.serverTimestamp(),
        'status': status, // 'answered', 'missed', 'rejected'
      };

      if (duration != null) {
        updateData['duration'] = duration;
      }

      await _firestore.collection('calls').doc(callId).update(updateData);
    } catch (e) {
      throw Exception('Arama kaydı güncellenemedi: $e');
    }
  }

  // Kullanıcının arama geçmişini getir
  Stream<QuerySnapshot> getCallHistory(String userId) {
    return _firestore
        .collection('calls')
        .where(
          Filter.or(
            Filter('callerId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots();
  }
}
