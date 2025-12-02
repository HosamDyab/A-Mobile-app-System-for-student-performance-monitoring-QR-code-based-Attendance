import 'package:qra/ustils/supabase_manager.dart';

Future<String?> getActiveLectureInstance() async {
  final response = await SupabaseManager.client
      .from('LectureInstance')
      .select('instanceid')
      .eq('iscancelled', false)
      .order('meetingdate', ascending: false)
      .limit(1)
      .single();

  if (response['instanceid'] != null) {
    return response['instanceid'];
  }
  return null;
}

Future<void> signIn(String email, String password) async {
  final response = await SupabaseManager.client.auth.signInWithPassword(
    email: email,
    password: password,
  );

  if (response.user != null) {
    print('Signed in as ${response.user!.id}');
  } else {
    print('Sign in failed');
  }
}
