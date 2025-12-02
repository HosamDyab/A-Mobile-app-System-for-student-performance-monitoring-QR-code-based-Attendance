import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/services/usecases/submit_grades_usecase.dart';
import 'grade_entry_state.dart';
// import '../bloc/grade_entry/grade_entry_cubit.dart';

class GradeEntryCubit extends Cubit<GradeEntryState> {
  final SubmitGradesUseCase submitGradesUseCase;
  
  GradeEntryCubit(this.submitGradesUseCase) : super(GradeEntryInitial());
  
  Future<void> submitGrade({
    required String studentId,
    required String examGrade,
    required String assignmentGrade,
  }) async {
    emit(GradeEntryLoading());
    try {
      final grade = await submitGradesUseCase.execute(
        studentId: studentId,
        examGrade: examGrade,
        assignmentGrade: assignmentGrade,
      );
      emit(GradeEntrySuccess(grade: grade));
    } catch (e) {
      emit(GradeEntryError(message: e.toString()));
    }
  }
  
  void reset() {
    emit(GradeEntryInitial());
  }
}