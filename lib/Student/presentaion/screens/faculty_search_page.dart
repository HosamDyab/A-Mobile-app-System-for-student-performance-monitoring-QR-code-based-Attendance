import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/SearchCuit.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/utils/app_colors.dart';
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
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = _controller.text.trim();
      if (query.isEmpty) {
        context.read<StudentSearchCubit>().clearFaculty();
        return;
      }
      context.read<StudentSearchCubit>().searchFaculty(query);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Search Faculty",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedGradientBackground(
        colors: AppColors.animatedGradientColors,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: Opacity(
                        opacity: value,
                        child: TextField(
                          controller: _controller,
                          cursorColor: AppColors.primaryBlue,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: "Search faculty by name...",
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                                width: 2.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BlocBuilder<StudentSearchCubit, StudentSearchState>(
                    builder: (context, state) {
                      if (_controller.text.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Start typing to search faculty...",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.tertiaryLightGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!state.isLoadingFaculty && state.faculty.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_rounded,
                                size: 64,
                                color: AppColors.tertiaryLightGray,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No matching faculty found",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.tertiaryLightGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          ListView.separated(
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: state.faculty.length,
                            itemBuilder: (context, index) {
                              final faculty = state.faculty[index];
                              final initial = faculty.fullName.isNotEmpty
                                  ? faculty.fullName[0].toUpperCase()
                                  : '?';

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: HoverScaleWidget(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                AppColors.secondaryOrange.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppColors.secondaryOrange.withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.secondaryOrange.withOpacity(0.1),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: ExpansionTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                gradient: AppColors.secondaryGradient,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.secondaryOrange.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor: Colors.white,
                                                radius: 20,
                                                child: Text(
                                                  initial,
                                                  style: TextStyle(
                                                    color: AppColors.secondaryOrange,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              faculty.fullName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.tertiaryBlack,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.email_rounded,
                                                    size: 14,
                                                    color: AppColors.tertiaryLightGray,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      faculty.email,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: AppColors.tertiaryLightGray,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            iconColor: AppColors.secondaryOrange,
                                            collapsedIconColor: AppColors.secondaryOrange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (state.isLoadingFaculty)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: LoadingAnimation(
                                    size: 32,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
