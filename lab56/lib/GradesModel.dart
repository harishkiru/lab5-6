import 'package:cloud_firestore/cloud_firestore.dart';
import 'Grade.dart';

class GradesModel {
  static final GradesModel instance = GradesModel._privateConstructor();
  GradesModel._privateConstructor();

  final CollectionReference gradeCollection = FirebaseFirestore.instance.collection('grades');

  Stream<List<Grade>> getGradesStream() {
    return gradeCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Grade.fromSnapshot(doc)).toList();
    });
  }

  Future<void> insertGrade(Grade grade) async {
    DocumentReference documentReferencer = gradeCollection.doc();
    grade.id = documentReferencer.id;
    await documentReferencer.set(grade.toMap());
  }

  Future<void> updateGrade(Grade grade) async {
    if (grade.reference != null) {
      await grade.reference!.update(grade.toMap());
    } else {
      print('Error: Cannot update grade without a reference');
    }
  }

  Future<void> deleteGrade(Grade grade) async {
    if (grade.reference != null) {
      await grade.reference!.delete();
    } else {
      print('Error: Cannot delete grade without a reference');
    }
  }
}
