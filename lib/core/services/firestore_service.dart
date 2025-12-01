import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Общие методы для работы с Firestore
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  Future<void> setDocument(
      String collection,
      String docId,
      Map<String, dynamic> data, {
        bool merge = false,
      }) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
      String collection,
      String docId,
      Map<String, dynamic> data,
      ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Stream<DocumentSnapshot> watchDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Future<void> runTransaction(
      Future<void> Function(Transaction) transactionHandler,
      ) async {
    await _firestore.runTransaction(transactionHandler);
  }
}
