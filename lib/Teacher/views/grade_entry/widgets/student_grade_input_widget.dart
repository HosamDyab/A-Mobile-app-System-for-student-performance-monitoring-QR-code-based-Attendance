import 'package:flutter/material.dart';

class GradeEntryCard extends StatelessWidget {
  final String studentName;
  final String examGrade;
  final String assignmentGrade;
  final Function(String) onExamGradeChanged;
  final Function(String) onAssignmentGradeChanged;

  const GradeEntryCard({
    super.key,
    required this.studentName,
    required this.examGrade,
    required this.assignmentGrade,
    required this.onExamGradeChanged,
    required this.onAssignmentGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            studentName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GradeInputField(
                  label: 'Exam',
                  value: examGrade,
                  onChanged: onExamGradeChanged,
                  hint: 'e.g. 85',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GradeInputField(
                  label: 'Assignments',
                  value: assignmentGrade,
                  onChanged: onAssignmentGradeChanged,
                  hint: 'e.g. 92',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeInputField extends StatefulWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String hint;

  const _GradeInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hint,
  });

  @override
  State<_GradeInputField> createState() => _GradeInputFieldState();
}

class _GradeInputFieldState extends State<_GradeInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_GradeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          keyboardType: TextInputType.number,
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixText: '%',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (text) {
            // Allow only numbers
            if (text.isEmpty || double.tryParse(text) != null) {
              widget.onChanged(text);
            }
          },
        ),
      ],
    );
  }
}