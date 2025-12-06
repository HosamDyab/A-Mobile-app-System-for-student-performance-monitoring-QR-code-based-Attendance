import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../helpers/LocalDatabase GPA calculator.dart';
import '../../data/models/Course.dart';
import '../../data/models/Semester.dart';
import '../blocs/gpa cubit.dart';
import '../blocs/gpa state.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/hover_scale_widget.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

/// Screen that allows the student to manage semesters/courses
/// and visualises GPA progress with a chart and summary cards.
class GpaCalcPage extends StatefulWidget {
  const GpaCalcPage({super.key});

  @override
  State<GpaCalcPage> createState() => _GpaCalcPageState();
}

class _GpaCalcPageState extends State<GpaCalcPage> {
  late GpaCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = context.read<GpaCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // Prevent back navigation - stay in app
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'GPA Calculator',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            const ThemeToggleButton(),
            LogoutButton(showAsIcon: true),
          ],
        ),
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: BlocBuilder<GpaCubit, GpaState>(
              builder: (context, state) {
                if (state is GpaLoading || state is GpaInitial) {
                  return Center(
                    child: LoadingAnimation(
                      color: AppColors.primaryBlue,
                      size: 50,
                    ),
                  );
                } else if (state is GpaError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.accentRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.accentRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is GpaLoaded) {
                  final semesters = state.semesters;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryCard(context, state.cumulativeGpa, semesters),
                        const SizedBox(height: 24),
                        if (semesters.isNotEmpty) ...[
                          _buildGpaChart(context, semesters),
                          const SizedBox(height: 24),
                        ],
                        ...semesters.map((s) => _semesterCard(context, s)),
                        const SizedBox(height: 20),
                        HoverScaleWidget(
                          onTap: _showAddSemesterDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryOrange
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded,
                                    color: Colors.white, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Semester',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
      BuildContext context, double cumulative, List<Semester> semesters) {
    final theme = Theme.of(context);
    final semCount = semesters.length;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Cumulative GPA',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cumulative.toStringAsFixed(2),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Semesters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$semCount',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Line chart that shows GPA trend over semesters.
  Widget _buildGpaChart(BuildContext context, List<Semester> semesters) {
    final theme = Theme.of(context);
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "GPA Trend",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < semesters.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'S${value.toInt() + 1}',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: semesters.reversed.toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.gpa);
                    }).toList(),
                    isCurved: true,
                    gradient: AppColors.primaryGradient,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: AppColors.secondaryOrange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.1),
                          AppColors.primaryBlue.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 4.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card that displays a single semester with its GPA and all courses.
  Widget _semesterCard(BuildContext context, Semester s) {
    final theme = Theme.of(context);
    final gpaColor = s.gpa >= 3.5
        ? AppColors.accentGreen
        : s.gpa >= 2.5
            ? AppColors.secondaryOrange
            : AppColors.accentRed;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: gpaColor.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gpaColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Container(
                            //   padding: const EdgeInsets.all(10),
                            //   decoration: BoxDecoration(
                            //     gradient: AppColors.primaryGradient,
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: const Icon(Icons.calendar_today_rounded,
                            //       color: Colors.white, size: 20),
                            // ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13
                                ),
                                maxLines: 2,           // allow up to 2 lines
                                overflow: TextOverflow.ellipsis, // show ... if still too long
                                softWrap: true,        // allow wrapping
                              ),
                            ),

                          ],
                        ),
                      ),
                      Row(
                        children: [
                         Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [gpaColor, gpaColor.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'GPA: ${s.gpa.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showEditSemesterDialog(s),
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.primaryBlue),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteSemester(s),
                            icon: const Icon(Icons.delete_rounded,
                                color: AppColors.accentRed),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Course',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Credits',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Grade',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...s.courses.map((c) => _courseRow(context, c)),
                  const SizedBox(height: 12),
                  HoverScaleWidget(
                    onTap: () => _showAddCourseDialog(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondaryOrange.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: AppColors.secondaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Course',
                            style: TextStyle(
                              color: AppColors.secondaryOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Row representing a single course inside a semester card.
  Widget _courseRow(BuildContext context, Course c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _inputBox(
              initialValue: c.name,
              onTap: () => _showEditCourseDialog(c),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: _inputBox(
              initialValue: '${c.credits}',
              onTap: () => _showEditCourseDialog(c),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: _inputBox(
              initialValue: c.grade,
              onTap: () => _showEditCourseDialog(c),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFD9534F)),
            onPressed: () => _confirmDeleteCourse(c),
          ),
        ],
      ),
    );
  }

  /// Dialog to create a new semester record.
  Future<void> _showAddSemesterDialog() async {
    String selectedSemester = 'Semester 1';
    final rankCtrl = TextEditingController();

    final semesterOptions = [
      'Semester 1',
      'Semester 2',
      'Semester 3',
      'Semester 4',
      'Semester 5',
      'Semester 6',
      'Semester 7',
      'Semester 8',
      'Summer Semester',
      'Winter Semester',
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Add Semester'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSemester,
                decoration: InputDecoration(
                  labelText: 'Select Semester',
                  labelStyle: TextStyle(color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                items: semesterOptions.map((semester) {
                  return DropdownMenuItem(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSemester = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // TextField(
              //   controller: rankCtrl,
              //   decoration: InputDecoration(
              //     labelText: 'Rank (optional)',
              //     labelStyle: TextStyle(color: AppColors.primaryBlue),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //       borderSide: BorderSide(
              //         color: AppColors.primaryBlue,
              //         width: 2,
              //       ),
              //     ),
              //     prefixIcon: Icon(
              //       Icons.numbers_rounded,
              //       color: AppColors.primaryBlue,
              //     ),
              //   ),
              //   keyboardType: TextInputType.number,
              // ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final rank = int.tryParse(rankCtrl.text.trim()) ?? 0;
                cubit.addSemester(selectedSemester, rank: rank);
                Navigator.pop(context);
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog to edit an existing semester (title and rank only).
  Future<void> _showEditSemesterDialog(Semester s) async {
    final titleCtrl = TextEditingController(text: s.title);
    final rankCtrl = TextEditingController(text: s.rank.toString());
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Semester'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: rankCtrl,
              decoration: const InputDecoration(labelText: 'Rank (optional)'),
              keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final rank = int.tryParse(rankCtrl.text.trim()) ?? 0;
              if (title.isNotEmpty) {
                final updated = Semester(
                  id: s.id,
                  title: title,
                  gpa: s.gpa,
                  rank: rank,
                  totalCredits: s.totalCredits,
                );
                await LocalDb.updateSemester(updated);
                await cubit.loadAll();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  /// Confirmation dialog before deleting a semester and all its courses.
  Future<void> _confirmDeleteSemester(Semester s) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text(
            'Are you sure you want to delete "${s.title}" and all its courses?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true && s.id != null) {
      await cubit.deleteSemester(s.id!);
    }
  }

  /// Dialog to add a new course to the provided semester.
  Future<void> _showAddCourseDialog(Semester s) async {
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController();
    String grade = 'A';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Course'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Course name')),
          TextField(
              controller: creditsCtrl,
              decoration: const InputDecoration(labelText: 'Credits'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: grade,
            items: [
              'A+',
              'A',
              'A-',
              'B+',
              'B',
              'B-',
              'C+',
              'C',
              'C-',
              'D+',
              'D'
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) {
              if (v != null) grade = v;
            },
            decoration: const InputDecoration(labelText: 'Grade'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final credits = int.tryParse(creditsCtrl.text.trim()) ?? 0;
              if (name.isNotEmpty && credits > 0 && s.id != null) {
                await cubit.addCourse(s.id!, name, credits, grade);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  /// Dialog to edit an existing course (name, credits, grade).
  Future<void> _showEditCourseDialog(Course c) async {
    final nameCtrl = TextEditingController(text: c.name);
    final creditsCtrl = TextEditingController(text: c.credits.toString());
    String grade = c.grade;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Course'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Course name')),
          TextField(
              controller: creditsCtrl,
              decoration: const InputDecoration(labelText: 'Credits'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: grade,
            items: [
              'A+',
              'A',
              'A-',
              'B+',
              'B',
              'B-',
              'C+',
              'C',
              'C-',
              'D+',
              'D'
            ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) {
              if (v != null) grade = v;
            },
            decoration: const InputDecoration(labelText: 'Grade'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final credits = int.tryParse(creditsCtrl.text.trim()) ?? 0;
              if (name.isNotEmpty && credits > 0) {
                final updated = Course(
                    id: c.id,
                    semesterId: c.semesterId,
                    name: name,
                    credits: credits,
                    grade: grade);
                await cubit.updateCourse(updated);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  /// Confirmation dialog before removing a single course from a semester.
  Future<void> _confirmDeleteCourse(Course c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Delete course "${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true && c.id != null) {
      await cubit.deleteCourse(c.id!, c.semesterId);
    }
  }
}

/// Small read‑only input-like box used inside the GPA tables.
Widget _inputBox({
  required String initialValue,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFE0D6CC), width: 1.6),
        color: Colors.white,
      ),
      child: Text(
        initialValue,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF4A403A),
        ),
      ),
    ),
  );
}
