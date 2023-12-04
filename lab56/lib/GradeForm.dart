import 'package:flutter/material.dart';
import 'Grade.dart';

class GradeForm extends StatefulWidget {
  final Grade? grade;

  GradeForm({this.grade});

  @override
  _GradeFormState createState() => _GradeFormState();
}

class _GradeFormState extends State<GradeForm> {
  final TextEditingController _sidController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.grade != null) {
      _sidController.text = widget.grade!.sid;
      _gradeController.text = widget.grade!.grade;
    }
  }

  @override
  void dispose() {
    _sidController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grade == null ? 'Add Grade' : 'Edit Grade')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _sidController,
              decoration: InputDecoration(labelText: 'Student ID'),
            ),
            TextField(
              controller: _gradeController,
              decoration: InputDecoration(labelText: 'Grade'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGrade,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGrade() {
    if (_sidController.text.isNotEmpty && _gradeController.text.isNotEmpty) {
      final updatedGrade = Grade(
        id: widget.grade?.id ?? '',
        sid: _sidController.text,
        grade: _gradeController.text,
        reference: widget.grade?.reference,
      );
      Navigator.pop(context, updatedGrade);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
    }
  }
}
