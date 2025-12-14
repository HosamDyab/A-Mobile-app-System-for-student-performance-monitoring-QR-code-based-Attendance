import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://nsovrjjfimaqlpnmhpun.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zb3ZyampmaW1hcWxwbm1ocHVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTQxNzcsImV4cCI6MjA4MDg3MDE3N30.Hczv1ZOiMwWWfitzG8b6TxAxku-OP0VaTUdngcAAhTA',
    );
  }
}
