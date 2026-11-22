/// Replace these values with your Supabase project credentials.
/// Find them at: Supabase Dashboard → Project Settings → API
class SupabaseConfig {
  static const String url = 'https://ovyhdwyybzulvewxbupt.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92eWhkd3l5Ynp1bHZld3hidXB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyNzQ3MzMsImV4cCI6MjA5Nzg1MDczM30.dEEXS-8wYGcTnrczgTw_eAPvRAZNiGdkAuHzZC4oTwA';

  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL' && anonKey != 'YOUR_SUPABASE_ANON_KEY';
}
