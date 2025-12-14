import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/SearchCuit.dart';
import 'faculty_details_page.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/hover_scale_widget.dart';
import '../../../shared/widgets/loading_animation.dart';

class FacultySearchPage extends StatefulWidget {
  const FacultySearchPage({super.key});

  @override
  State<FacultySearchPage> createState() => _FacultySearchPageState();
}

class _FacultySearchPageState extends State<FacultySearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    context.read<StudentSearchCubit>().loadAllFaculty();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _controller.text.trim();
      context.read<StudentSearchCubit>().filterFaculty(query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_search_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "My Faculty",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search Field
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFE6ED),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDFE6ED).withOpacity(0.6),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: "Search faculty by name or email...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                child: const Icon(Icons.search_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  context
                                      .read<StudentSearchCubit>()
                                      .filterFaculty('');
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFDFE6ED),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: BlocBuilder<StudentSearchCubit, StudentSearchState>(
                    builder: (context, state) {
                      if (state.isLoadingFaculty && state.faculty.isEmpty) {
                        return const Center(
                          child: LoadingAnimation(
                              color: AppColors.primaryBlue, size: 60),
                        );
                      }

                      if (state.faculty.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded,
                                  size: 80,
                                  color:
                                  colorScheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 24),
                              Text(
                                _controller.text.isEmpty
                                    ? "No faculty members found"
                                    : "No match for \"${_controller.text}\"",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: state.faculty.length,
                        itemBuilder: (context, index) {
                          final faculty = state.faculty[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                            Duration(milliseconds: 350 + (index * 70)),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: HoverScaleWidget(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        AdvancedSlidePageRoute(
                                          page: FacultyDetailsPage(
                                              faculty: faculty),
                                          direction: SlideDirection.right,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDFE6ED),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primaryBlue
                                              .withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFDFE6ED)
                                                .withOpacity(0.6),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              gradient:
                                              AppColors.secondaryGradient,
                                              borderRadius:
                                              BorderRadius.circular(16),
                                            ),
                                            child: Center(
                                              child: Text(
                                                faculty.fullName.isNotEmpty
                                                    ? faculty.fullName[0]
                                                    .toUpperCase()
                                                    : "?",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  faculty.fullName,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF2C3E50),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  faculty.email,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                if (faculty.depCode != null) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primaryBlue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          4),
                                                    ),
                                                    child: Text(
                                                      faculty.depCode!,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        color: AppColors
                                                            .primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_ios_rounded,
                                              size: 18,
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.6)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}