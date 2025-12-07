import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://duewvafpukziltqqwtjc.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1ZXd2YWZwdWt6aWx0cXF3dGpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxMDYyMjcsImV4cCI6MjA3NTY4MjIyN30.SP8Zt2MEc8Ts1WWHHU0Ksudejcs9GtUyBduGILCN3zg',
    );
  }
}
