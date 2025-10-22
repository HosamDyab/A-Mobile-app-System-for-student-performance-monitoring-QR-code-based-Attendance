import 'package:flutter/material.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  final TextEditingController _assessmentNameController =
  TextEditingController();

  String? _selectedType;
  String? _selectedCourse;
  String? _uploadedFileName; // simulated file name

  final List<String> assessmentTypes = ["Midterm", "Quiz", "Assignment"];
  final List<String> courses = [
    "Software Two",
    "Microsystem",
    "Computer Graphics"
  ];

  List<Map<String, String>> existingAssessments = [
    {
      "name": "Midterm Exam",
      "course": "Calculus I",
      "file": "midterm_template.docx"
    },
    {"name": "Final Exam", "course": "Linear Algebra", "file": ""},
    {"name": "Practical Exam", "course": "Physics Lab", "file": ""}
  ];

  // Simulate picking a file by asking user to enter a filename in a dialog
  Future<void> _simulatePickFile() async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulate file pick'),
        content: TextField(
          controller: controller,
          decoration:
          const InputDecoration(hintText: 'Enter filename (e.g., doc.pdf)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      setState(() {
        _uploadedFileName = res;
      });
    }
  }

  void _addAssessment() {
    if (_selectedCourse != null && _selectedType != null) {
      setState(() {
        existingAssessments.add({
          "name": _assessmentNameController.text.isNotEmpty
              ? _assessmentNameController.text
              : "${_selectedType!} Exam",
          "course": _selectedCourse!,
          "file": _uploadedFileName ?? "",
        });
        _assessmentNameController.clear();
        _selectedCourse = null;
        _selectedType = null;
        _uploadedFileName = null;
      });
    } else {
      // show a small message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select Assessment Type and Course'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFCF8C40); // Orange
    final Color bgColor = const Color(0xFFF9F5F0); // Light beige

    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {},
          ),
          title: const Text(
            "Assessments",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Timetable"),BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Assessments"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
              "Add New Assessment",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assessmentNameController,
              decoration: InputDecoration(
                labelText: "Assessment Name",
                hintText: "e.g., Midterm Exam",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: assessmentTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Assessment Type",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedType = val;
                  _assessmentNameController.text = "$val Exam";
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCourse,
              items: courses
                  .map((course) => DropdownMenuItem(
                value: course,
                child: Text(course),
              ))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Course",
                filled: true,
                fillColor: Colors.white,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onChanged: (val) {
                setState(() => _selectedCourse = val);
              },
            ),
            const SizedBox(height: 12),

            // Upload File Section (simulated)
            GestureDetector(
              onTap: _simulatePickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.orange.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        color: primaryColor, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _uploadedFileName != null
                          ? "Uploaded: $_uploadedFileName"
                          : "Tap to simulate upload\nPDF, DOCX, XLSX up to 10MB",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _uploadedFileName != null
                              ? primaryColor
                              : Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
                style: ElevatedButton.styleFrom( backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              onPressed: _addAssessment,
              child: const Text("Add Assessment"),
            ),
              const SizedBox(height: 24),
              const Text(
                "Existing Assessments",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...existingAssessments.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["name"]!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(item["course"]!,
                                  style: TextStyle(color: Colors.grey[600])),
                              if (item["file"]!.isNotEmpty)
                                Text(item["file"]!,
                                    style: TextStyle(
                                        color: primaryColor, fontSize: 13)),
                            ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            existingAssessments.remove(item);
                          });
                        },
                      )
                    ],
                  ),
                );
              })
            ]),
        ),
    );
  }
}