import 'package:supabase_flutter/supabase_flutter.dart';

class Database {
  /// Initialize the connection to Supabase.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: "https://vwhpcrbdryxdgwnvkanf.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3aHBjcmJkcnl4ZGd3bnZrYW5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMzQ4NDMsImV4cCI6MjA5MzkxMDg0M30.23EVtbOBFtLwZCPlmzSUMP0_i9anrJsHCbGJkU8bzK8",
    );
  }

  /// The underlying Supabase client.
  static final SupabaseClient client = Supabase.instance.client;
}
