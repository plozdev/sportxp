class ProfileLink {
  static const origin = String.fromEnvironment('PROFILE_LINK_ORIGIN');
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static String? parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;
    if (!uri.hasScheme && uri.hasAuthority) return null;
    final String path;
    if (uri.hasScheme) {
      final configured = Uri.tryParse(origin);
      if (uri.scheme == 'sportxp' && uri.host == 'profile') {
        path = '/p${uri.path}';
      } else if (uri.scheme == 'https' &&
          configured != null &&
          configured.hasAuthority &&
          uri.origin == configured.origin) {
        path = uri.fragment.startsWith('/p/') ? uri.fragment : uri.path;
      } else {
        return null;
      }
    } else {
      path = uri.path;
    }
    final parts = path.split('/');
    if (parts.length != 3 || parts[1] != 'p' || !_uuid.hasMatch(parts[2])) {
      return null;
    }
    return parts[2].toLowerCase();
  }

  static String build(String id) {
    if (!_uuid.hasMatch(id)) throw const FormatException('Invalid profile ID');
    final uri = Uri.tryParse(origin);
    if (uri != null && uri.scheme == 'https' && uri.hasAuthority) {
      return '${uri.origin}/#/p/$id';
    }
    return 'sportxp://profile/$id';
  }
}
