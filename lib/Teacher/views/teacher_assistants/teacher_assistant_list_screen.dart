import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import '../../viewmodels/teacher_assistant/teacher_assistant_state.dart';
import '../widgets/custom_app_bar.dart';

class TeacherAssistantListScreen extends StatefulWidget {
  final String? facultyId;

  const TeacherAssistantListScreen({
    super.key,
    this.facultyId,
  });

  @override
  State<TeacherAssistantListScreen> createState() => _TeacherAssistantListScreenState();
}

class _TeacherAssistantListScreenState extends State<TeacherAssistantListScreen> {
  @override
  void initState() {
    super.initState();
    // Load all TAs or TAs assigned to this faculty
    if (widget.facultyId != null) {
      context.read<TeacherAssistantCubit>().loadTeacherAssistantsByFaculty(widget.facultyId!);
    } else {
      context.read<TeacherAssistantCubit>().loadAllTeacherAssistants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.facultyId != null ? 'Assigned T.As' : 'Teacher Assistants',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by name or email...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<TeacherAssistantCubit>().searchTeacherAssistants(value);
              },
            ),
            const SizedBox(height: 20),
            
            // T.A. List
            Expanded(
              child: BlocBuilder<TeacherAssistantCubit, TeacherAssistantState>(
                builder: (context, state) {
                  if (state is TeacherAssistantLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TeacherAssistantLoaded) {
                    if (state.teacherAssistants.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No teacher assistants found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.teacherAssistants.length,
                      itemBuilder: (context, index) {
                        final ta = state.teacherAssistants[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFD88A2D),
                              child: Text(
                                (ta.fullName ?? 'TA')
                                    .split(' ')
                                    .map((n) => n.isNotEmpty ? n[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              ta.fullName ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ta.email != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ta.email!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'TA ID: ${ta.taId}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Show T.A. details or navigate to their sections
                              _showTADetails(context, ta);
                            },
                          ),
                        );
                      },
                    );
                  } else if (state is TeacherAssistantError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (widget.facultyId != null) {
                                context
                                    .read<TeacherAssistantCubit>()
                                    .loadTeacherAssistantsByFaculty(widget.facultyId!);
                              } else {
                                context
                                    .read<TeacherAssistantCubit>()
                                    .loadAllTeacherAssistants();
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTADetails(BuildContext context, dynamic ta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ta.fullName ?? 'Teacher Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ta.email != null) ...[
              const Text(
                'Email:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(ta.email!),
              const SizedBox(height: 12),
            ],
            const Text(
              'TA ID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(ta.taId),
            const SizedBox(height: 12),
            const Text(
              'User ID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(ta.userId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

