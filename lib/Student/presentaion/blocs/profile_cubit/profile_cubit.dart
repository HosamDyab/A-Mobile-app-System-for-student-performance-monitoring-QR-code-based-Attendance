
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Student/presentaion/blocs/profile_cubit/profile_state.dart';

import '../../../domain/StudentRepository.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final StudentRepository repository;

  StudentProfileCubit(this.repository) : super(StudentProfileInitial());

  Future<void> loadStudentProfile(String studentId) async {
    emit(StudentProfileLoading());
    try {
      final student = await repository.getStudentById(studentId);
      if (student != null) {
        emit(StudentProfileLoaded(student));
      } else {
        emit(StudentProfileError("Student not found"));
      }
    } catch (e) {
      emit(StudentProfileError(e.toString()));
    }
  }
}
