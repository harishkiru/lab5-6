import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'GradesModel.dart';
import 'Grade.dart';
import 'GradeForm.dart';
import 'data_search.dart';

enum SortOption { sidIncreasing, sidDecreasing, gradeIncreasing, gradeDecreasing }

class ListGrades extends StatefulWidget {
  @override
  _ListGradesState createState() => _ListGradesState();
}

class _ListGradesState extends State<ListGrades> {
  List<Grade> sortedGrades = [];
  List<Grade> displayGrades = [];
  SortOption currentSortOption = SortOption
      .sidIncreasing;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Grades'),
        actions: <Widget>[
          PopupMenuButton<SortOption>(
            onSelected: _sortGrades,
            itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.sidIncreasing,
                child: Text('Sort by SID Increasing'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.sidDecreasing,
                child: Text('Sort by SID Decreasing'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.gradeIncreasing,
                child: Text('Sort by Grade Increasing'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.gradeDecreasing,
                child: Text('Sort by Grade Decreasing'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: DataSearch(this.sortedGrades));
            },
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () =>
                _showDataTableAndChart(),
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _importCsv,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportGradesToCsv,
          ),
        ],
      ),
      body: StreamBuilder<List<Grade>>(
        stream: GradesModel.instance.getGradesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          sortedGrades = snapshot.data ?? [];
          _updateDisplayGrades();

          return ListView.builder(
            itemCount: displayGrades.length,
            itemBuilder: (context, index) {
              var grade = displayGrades[index];
              return Dismissible(
                key: Key(grade.id),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                  setState(() {
                    GradesModel.instance.deleteGrade(grade);
                    sortedGrades.removeWhere((g) => g.id == grade.id);
                    displayGrades.removeWhere((g) => g.id == grade.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Grade deleted")));
                },
                child: ListTile(
                  title: Text(grade.sid),
                  subtitle: Text(grade.grade),
                  onLongPress: () => _editGrade(grade),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGrade,
        child: Icon(Icons.add),
      ),
    );
  }

  void _addGrade() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GradeForm(),
      ),
    );

    if (result != null && result is Grade) {
      await GradesModel.instance.insertGrade(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Grade added: ${result.sid} - ${result.grade}")),
      );
    }
  }

  void _editGrade(Grade grade) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GradeForm(grade: grade),
      ),
    );

    if (result != null && result is Grade) {
      await GradesModel.instance.updateGrade(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Grade updated: ${result.sid} - ${result.grade}")),
      );
    }
  }


  void _sortGrades(SortOption option) {
    setState(() {
      currentSortOption = option;
      _updateDisplayGrades();
    });
  }


  void _updateDisplayGrades() {
    displayGrades =
        List.from(sortedGrades);

    print(
        "Before Sorting: ${displayGrades.map((g) => '${g.sid}:${g.grade}').join(
            ', ')}");

    switch (currentSortOption) {
      case SortOption.sidIncreasing:
        displayGrades.sort((a, b) => a.sid.compareTo(b.sid));
        break;
      case SortOption.sidDecreasing:
        displayGrades.sort((a, b) => b.sid.compareTo(a.sid));
        break;
      case SortOption.gradeIncreasing:
        displayGrades.sort((a, b) {
          final gradeA = _parseGrade(a.grade);
          final gradeB = _parseGrade(b.grade);
          return gradeB.compareTo(gradeA);
        });
        break;
      case SortOption.gradeDecreasing:
        displayGrades.sort((a, b) {
          final gradeA = _parseGrade(a.grade);
          final gradeB = _parseGrade(b.grade);
          return gradeA.compareTo(gradeB);
        });
        break;
    }

    print(
        "After Sorting: ${displayGrades.map((g) => '${g.sid}:${g.grade}').join(
            ', ')}");
  }

  dynamic _parseGrade(String grade) {
    final numericGrade = double.tryParse(grade);
    if (numericGrade != null) {
      return numericGrade;
    } else {
      return grade;
    }
  }


  void mergeSort(List<Grade> grades, int Function(Grade, Grade) compare) {
    if (grades.length <= 1) {
      return;
    }

    final int mid = grades.length ~/ 2;
    final List<Grade> left = grades.sublist(0, mid);
    final List<Grade> right = grades.sublist(mid);

    mergeSort(left, compare);
    mergeSort(right, compare);

    int i = 0,
        j = 0,
        k = 0;

    while (i < left.length && j < right.length) {
      if (compare(left[i], right[j]) <= 0) {
        grades[k++] = left[i++];
      } else {
        grades[k++] = right[j++];
      }
    }

    while (i < left.length) {
      grades[k++] = left[i++];
    }

    while (j < right.length) {
      grades[k++] = right[j++];
    }
  }


  void _showDataTableAndChart() {
    final Map<String, int> gradeFrequency = {};
    for (var grade in displayGrades) {
      String normalizedGrade = grade.grade.toLowerCase();
      gradeFrequency[normalizedGrade] =
          (gradeFrequency[normalizedGrade] ?? 0) + 1;
    }

    final sortedGrades = gradeFrequency.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedGrades.length; i++) {
      final grade = sortedGrades[i];
      final frequency = gradeFrequency[grade];

      final barGroup = BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: frequency!.toDouble(),
            color: Colors.blue,
          ),
        ],
      );
      barGroups.add(barGroup);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Grades Data'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  width: 400,
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(sortedGrades[value.toInt()]),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(new CsvToListConverter())
          .toList();

      for (var field in fields) {
        String sid = field[0].toString();
        String grade = field[1].toString();
        Grade newGrade = Grade(id: "", sid: sid, grade: grade);
        FirebaseFirestore.instance.collection('grades').add(newGrade.toMap());
      }
    }
  }

  Future<void> _exportGradesToCsv() async {
    final List<List<dynamic>> rows = [];
    rows.add(['SID', 'Grade']);
    for (var grade in displayGrades) {
      rows.add([grade.sid, grade.grade]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/grades.csv');
    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Complete'),
          content: Text('The grades have been exported to ${file.path}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
