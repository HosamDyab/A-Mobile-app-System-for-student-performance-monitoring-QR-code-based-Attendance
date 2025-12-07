import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../Student/presentaion/blocs/attendace_bloc/attendance_cubit.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttendanceCubit>();
    final studentId = "100002";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.fetchStudentAttendance(studentId);
    });

    final orangeColor = const Color(0xFFD97A27);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'Attendance Records',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (context, state) {
                  if (state is AttendanceLoading) {
                    return const Center(child: CircularProgressIndicator(
                      color:  Color(0xFFD97A27),
                    ));
                  } else if (state is AttendanceLoaded) {
                    final records = state.attendances;
                    if (records.isEmpty) {
                      return const Center(
                        child: Text(
                          "No attendance records found.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final r = records[index];
                        final formattedTime = DateFormat('yyyy-MM-dd – hh:mm a')
                            .format(r.scanTime.toLocal());
                        final isPresent =
                            r.status.toLowerCase() == 'present';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: isPresent
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              child: Icon(
                                isPresent ? Icons.check_circle : Icons.cancel,
                                color: isPresent ? Colors.green : Colors.red,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              "Session: ${r.instanceId}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Scanned at: $formattedTime\nStatus: ${r.status}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is AttendanceError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(
                        "Load attendance data...",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),


      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: orangeColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text(
          "Refresh",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => cubit.fetchStudentAttendance(studentId),
      ),
    );
  }
}
