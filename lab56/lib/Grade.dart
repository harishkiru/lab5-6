import 'package:cloud_firestore/cloud_firestore.dart';

class Grade {
  String id;
  String sid;
  String grade;
  DocumentReference? reference;

  Grade({required this.id, required this.sid, required this.grade, this.reference});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sid': sid,
      'grade': grade,
    };
  }

  static Grade fromMap(Map<String, dynamic> map, {DocumentReference? reference}) {
    return Grade(
      id: map['id'],
      sid: map['sid'],
      grade: map['grade'],
      reference: reference,
    );
  }

  static Grade fromSnapshot(DocumentSnapshot snapshot) {
    return Grade(
      id: snapshot.id,
      sid: snapshot['sid'],
      grade: snapshot['grade'],
      reference: snapshot.reference,
    );
  }
}
