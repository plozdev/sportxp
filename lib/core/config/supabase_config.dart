class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});
  const SupabaseConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  final String url;
  final String anonKey;
  bool get isValid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        anonKey.isNotEmpty;
  }
}
