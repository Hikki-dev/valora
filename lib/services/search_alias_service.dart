class SearchAliasService {
  static const Map<String, String> _aliases = {
    'gta': 'Grand Theft Auto',
    'cod': 'Call of Duty',
    're': 'Resident Evil',
    'mgs': 'Metal Gear Solid',
    'loz': 'Legend of Zelda',
    'botw': 'Breath of the Wild',
    'totk': 'Tears of the Kingdom',
    'ff': 'Final Fantasy',
    'dq': 'Dragon Quest',
    'dmc': 'Devil May Cry',
    'go': 'God of War',
    'gow': 'God of War',
    'hzd': 'Horizon Zero Dawn',
    'hfw': 'Horizon Forbidden West',
    'tlou': 'The Last of Us',
    'sh': 'Silent Hill',
    'kh': 'Kingdom Hearts',
    'ac': 'Assassins Creed',
    'sw': 'Star Wars',
    'mc': 'Minecraft',
  };

  /// Expands abbreviations like "GTA" to "Grand Theft Auto".
  /// Handles case-insensitivity.
  String expandQuery(String query) {
    final lowerQuery = query.toLowerCase().trim();

    // Check for exact alias match
    if (_aliases.containsKey(lowerQuery)) {
      return _aliases[lowerQuery]!;
    }

    // Check if the query starts with an alias followed by a number or space (e.g., "GTA 6" -> "Grand Theft Auto 6")
    for (final entry in _aliases.entries) {
      final alias = entry.key;
      final fullTitle = entry.value;

      if (lowerQuery.startsWith('$alias ')) {
        return lowerQuery.replaceFirst(alias, fullTitle);
      }

      // Handle "GTA6" -> "Grand Theft Auto 6"
      final numberRegex = RegExp('^$alias(\\d+)\$');
      final match = numberRegex.firstMatch(lowerQuery);
      if (match != null) {
        final number = match.group(1);
        return '$fullTitle $number';
      }
    }

    return query;
  }

  /// Returns a list of query variations if the original might be too specific.
  List<String> getVariations(String query) {
    final expanded = expandQuery(query);
    if (expanded != query) {
      return [query, expanded];
    }
    return [query];
  }
}
