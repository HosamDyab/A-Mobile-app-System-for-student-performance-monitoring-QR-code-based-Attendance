import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/viewmodels/dashboard/teacher_dashboard_cubit.dart';
import 'package:qra/Teacher/viewmodels/dashboard/teacher_dashboard_state.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_cubit.dart';
import 'package:qra/Teacher/views/live_attendance/live_attendance_screen.dart';
import 'package:qra/Teacher/views/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String facultyName;
  final String facultyId;
  final String role; // 'faculty' or 'teacher_assistant'

  const TeacherDashboardScreen({
    super.key,
    required this.facultyName,
    required this.facultyId,
    required this.role,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Pass both facultyId and role to the cubit
    context.read<TeacherDashboardCubit>().loadTodayCourses(
          widget.facultyId,
          widget.role,
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Dashboard'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<TeacherDashboardCubit>().loadTodayCourses(
                  widget.facultyId,
                  widget.role,
                );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD88A2D),
                        const Color(0xFFD88A2D).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD88A2D).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.waving_hand,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Welcome, ${widget.facultyName}!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('h:mm a').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Statistics
                BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                  builder: (context, state) {
                    if (state is TeacherDashboardLoaded) {
                      return _buildQuickStats(state.courses.length);
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 24),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Lectures',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        context.read<TeacherDashboardCubit>().loadTodayCourses(
                              widget.facultyId,
                              widget.role,
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFFD88A2D)),
                    hintText: 'Search courses by name or code...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD88A2D)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Courses List
                BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                  builder: (context, state) {
                    if (state is TeacherDashboardLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is TeacherDashboardLoaded) {
                      // Filter courses based on search query
                      final filteredCourses = state.courses.where((course) {
                        if (_searchQuery.isEmpty) return true;
                        final query = _searchQuery.toLowerCase();
                        return course.courseTitle
                                .toLowerCase()
                                .contains(query) ||
                            course.courseCode.toLowerCase().contains(query);
                      }).toList();

                      if (filteredCourses.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Column(
                        children: filteredCourses.asMap().entries.map((entry) {
                          final index = entry.key;
                          final course = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 300 + (index * 100)),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCourseCard(course),
                          );
                        }).toList(),
                      );
                    } else if (state is TeacherDashboardError) {
                      return _buildErrorState(state.message);
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionConfigDialog(
    BuildContext context,
    String lectureOfferingId,
    String courseTitle,
    String courseCode,
  ) {
    final durationController = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start Session: $courseTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Course: $courseCode'),
            const SizedBox(height: 16),
            const Text('Set QR Code Validity (Minutes):'),
            const SizedBox(height: 8),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 10',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final duration = int.tryParse(durationController.text) ?? 10;
              Navigator.pop(ctx);
              _startSession(context, lectureOfferingId, courseTitle, duration);
            },
            child: const Text('Generate QR'),
          ),
        ],
      ),
    );
  }

  void _startSession(BuildContext context, String lectureOfferingId,
      String courseTitle, int durationMinutes) {
    // Generate a unique session ID for this lecture instance
    final sessionId = 'LINST-${DateTime.now().millisecondsSinceEpoch}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<LiveAttendanceCubit>(),
          child: LiveAttendanceScreen(
            sessionId: sessionId,
            courseTitle: courseTitle,
            durationMinutes: durationMinutes,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(int todayLectures) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.today,
            title: 'Today',
            value: '$todayLectures',
            subtitle: 'Lectures',
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            title: 'Active',
            value: '0',
            subtitle: 'Sessions',
            color: const Color(0xFFD88A2D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            title: 'Total',
            value: '--',
            subtitle: 'Students',
            color: const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(course) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showSessionConfigDialog(
          context,
          course.lectureOfferingId,
          course.courseTitle,
          course.courseCode,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD88A2D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book,
                  color: Color(0xFFD88A2D),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          course.schedule,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty ? Icons.calendar_today : Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'No lectures scheduled for today'
                  : 'No lectures found matching your search',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Enjoy your day off!'
                  : 'Try different search terms',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TeacherDashboardCubit>().loadTodayCourses(
                      widget.facultyId,
                      widget.role,
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD88A2D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
