import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/viewmodels/students/students_bloc.dart';
import 'package:qra/Teacher/viewmodels/students/students_state.dart';
import 'widgets/student_card_widget.dart';
import '../widgets/custom_app_bar.dart';

// class StudentsListScreen extends StatelessWidget {
//   const StudentsListScreen({Key? key}) : super(key: key);

//   // Inside your StudentsListScreen class
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: 'Students'),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText: 'Search by name...',
//                 filled: true,
//                 fillColor: Colors.grey[100],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               onChanged: (value) {
//                 context.read<StudentsBloc>().add(SearchStudentsEvent(value));
//               },
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     decoration: InputDecoration(
//                       labelText: 'Level',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                     items:
//                         [
//                           'All Levels',
//                           'Level 1',
//                           'Level 2',
//                           'Level 3',
//                           'Level 4',
//                           'Level 5',
//                         ].map((level) {
//                           return DropdownMenuItem<String>(
//                             value: level,
//                             child: Text(level),
//                           );
//                         }).toList(),
//                     onChanged: (value) {
//                       context.read<StudentsBloc>().add(
//                         FilterStudentsEvent(level: value),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     decoration: InputDecoration(
//                       labelText: 'Attendance',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                     items: ['All Status', 'Present', 'Absent', 'Late'].map((
//                       status,
//                     ) {
//                       return DropdownMenuItem<String>(
//                         value: status,
//                         child: Text(status),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       context.read<StudentsBloc>().add(
//                         FilterStudentsEvent(status: value),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: BlocBuilder<StudentsBloc, StudentsState>(
//                 builder: (context, state) {
//                   if (state is StudentsLoaded) {
//                     return ListView.builder(
//                       itemCount: state.students.length,
//                       itemBuilder: (context, index) {
//                         final student = state.students[index];
//                         return StudentCard(student: student);
//                       },
//                     );
//                   } else if (state is StudentsLoading) {
//                     return const Center(child: CircularProgressIndicator());
//                   } else if (state is StudentsError) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.error, color: Colors.red, size: 48),
//                           const SizedBox(height: 16),
//                           Text(
//                             'Error: ${state.message}',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               color: Colors.red,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: () {
//                               context.read<StudentsBloc>().add(
//                                 LoadStudentsEvent(),
//                               );
//                             },
//                             child: const Text('Retry'),
//                           ),
//                         ],
//                       ),
//                     );
//                   } else {
//                     return const Center(child: Text('No students found.'));
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


class StudentsListScreen extends StatelessWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Students'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by Name, ID, or Code...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<StudentsBloc>().add(SearchStudentsEvent(value));
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Level',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'All Levels',
                      'L1',
                      'L2',
                      'L3',
                      'L4',
                    ].map((level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      context.read<StudentsBloc>().add(FilterStudentsEvent(level: value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Attendance',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'All Status',
                      'Present',
                      'Absent',
                      'Late',
                    ].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      context.read<StudentsBloc>().add(FilterStudentsEvent(status: value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<StudentsBloc, StudentsState>(
                builder: (context, state) {
                  if (state is StudentsLoaded) {
                    return ListView.builder(
                      itemCount: state.students.length,
                      itemBuilder: (context, index) {
                        final student = state.students[index];
                        return StudentCard(student: student);
                      },
                    );
                  } else if (state is StudentsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is StudentsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<StudentsBloc>().add(LoadStudentsEvent());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: Text('No students found.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}