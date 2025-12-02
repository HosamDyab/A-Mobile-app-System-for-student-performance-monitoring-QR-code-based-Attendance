import 'package:flutter/material.dart';
import 'package:qra/Teacher/models/student_entity.dart';

class StudentCard extends StatelessWidget {
  final StudentEntity student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 24, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName ?? student.studentCode, // ← Use fullName if available, otherwise fallback to studentCode
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        student.major,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      student.academicLevel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'GPA: ${student.currentGpa.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.remove_red_eye, color: Color(0xFFE67E22), size: 18),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit, color: Color(0xFFE67E22), size: 18),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.message, color: Color(0xFFE67E22), size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
