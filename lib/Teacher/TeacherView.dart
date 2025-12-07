/// Teacher Portal View - Main entry point for teachers/faculty
///
/// ⚠️ DEPRECATED: This file is kept for backward compatibility only.
/// Please use TeacherViewWrapper from screens/teacher_view_wrapper.dart instead.
///
/// The Teacher module has been refactored into multiple clean, organized files:
/// - screens/teacher_view_wrapper.dart - BLoC providers setup
/// - screens/teacher_main_screen.dart - Main navigation screen
/// - screens/teacher_profile_screen.dart - Profile screen
/// - widgets/profile_header_widget.dart - Profile header component
/// - widgets/profile_menu_widget.dart - Profile menu component
///
/// This improves:
/// - Code organization and maintainability
/// - Single Responsibility Principle
/// - Testability
/// - Reusability of components
library;

export 'screens/teacher_view_wrapper.dart';
export 'screens/teacher_main_screen.dart';
export 'screens/teacher_profile_screen.dart';

// For backward compatibility, create an alias
import 'screens/teacher_view_wrapper.dart';

/// Alias for backward compatibility
/// @deprecated Use TeacherViewWrapper instead
typedef TeacherView = TeacherViewWrapper;
