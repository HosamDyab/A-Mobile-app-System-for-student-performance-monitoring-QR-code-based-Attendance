import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../manual_grades/manual_grade_entry_screen.dart';

class GradeEntryScreen extends StatefulWidget {
  final String facultyId;
  final String role;

  const GradeEntryScreen({
    super.key,
    required this.facultyId,
    required this.role,
  });

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Grade Entry'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Info Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD88A2D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grade,
                  size: 64,
                  color: Color(0xFFD88A2D),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Grade Entry',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Enter student grades manually through the menu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Manual Grade Entry Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManualGradeEntryScreen(
                        facultyId: widget.facultyId,
                        role: widget.role,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Manual Grade Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD88A2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),

              // Help Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can also access Manual Grade Entry from the Profile menu (⋮)',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
