/// `GET /v1/agent/criteria-history/:buyerId` snapshot.
final class CriteriaHistoryEntry {
  const CriteriaHistoryEntry({
    required this.id,
    this.searchText,
    this.criteria,
    this.resultCount,
    this.createdAt,
  });

  final String id;
  final String? searchText;
  final Map<String, dynamic>? criteria;
  final int? resultCount;
  final String? createdAt;

  factory CriteriaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CriteriaHistoryEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      searchText: json['searchText'] as String?,
      criteria: json['criteria'] is Map<String, dynamic>
          ? json['criteria'] as Map<String, dynamic>
          : null,
      resultCount: (json['resultCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
    );
  }
}

enum CriteriaChangeKind { added, removed, changed }

final class CriteriaChange {
  const CriteriaChange({
    required this.kind,
    required this.path,
    required this.label,
    this.oldValue,
    this.newValue,
  });

  final CriteriaChangeKind kind;
  final String path;
  final String label;
  final Object? oldValue;
  final Object? newValue;
}

abstract final class CriteriaDiff {
  static List<CriteriaChange> diff(
    Map<String, dynamic>? previous,
    Map<String, dynamic>? current,
  ) {
    final Map<String, Object?> a = flatten(previous);
    final Map<String, Object?> b = flatten(current);
    final Set<String> keys = <String>{...a.keys, ...b.keys};
    final List<CriteriaChange> changes = <CriteriaChange>[];
    for (final String key in keys) {
      final bool inA = a.containsKey(key);
      final bool inB = b.containsKey(key);
      if (inA && inB) {
        if (!_equal(a[key], b[key])) {
          changes.add(
            CriteriaChange(
              kind: CriteriaChangeKind.changed,
              path: key,
              label: labelFor(key),
              oldValue: a[key],
              newValue: b[key],
            ),
          );
        }
      } else if (inB) {
        changes.add(
          CriteriaChange(
            kind: CriteriaChangeKind.added,
            path: key,
            label: labelFor(key),
            newValue: b[key],
          ),
        );
      } else {
        changes.add(
          CriteriaChange(
            kind: CriteriaChangeKind.removed,
            path: key,
            label: labelFor(key),
            oldValue: a[key],
          ),
        );
      }
    }
    changes.sort(
      (CriteriaChange x, CriteriaChange y) => x.label.compareTo(y.label),
    );
    return changes;
  }

  static Map<String, Object?> flatten(
    Object? input, {
    String prefix = '',
    int depth = 0,
  }) {
    final Map<String, Object?> out = <String, Object?>{};
    void walk(Object? value, String path, int currentDepth) {
      if (value is List) {
        if (path.isNotEmpty) out[path] = value;
        return;
      }
      if (value is! Map || currentDepth > 3) {
        if (path.isNotEmpty) out[path] = value;
        return;
      }
      if (value.isEmpty) {
        if (path.isNotEmpty) out[path] = <String, Object?>{};
        return;
      }
      value.forEach((Object? key, Object? child) {
        final String next = path.isEmpty ? '$key' : '$path.$key';
        if (child is Map && child is! List) {
          walk(child, next, currentDepth + 1);
        } else {
          out[next] = child;
        }
      });
    }

    walk(input, prefix, depth);
    return out;
  }

  static String labelFor(String path) {
    return path
        .split('.')
        .map((String seg) {
          final String spaced = seg
              .replaceAll(RegExp(r'[_-]+'), ' ')
              .replaceAllMapped(
                RegExp(r'([a-z])([A-Z])'),
                (Match m) => '${m[1]} ${m[2]}',
              );
          return spaced
              .split(' ')
              .where((String part) => part.isNotEmpty)
              .map(
                (String part) =>
                    part[0].toUpperCase() + part.substring(1),
              )
              .join(' ');
        })
        .join(' › ');
  }

  static String formatValue(Object? value) {
    if (value == null || value == '') return '—';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num || value is String) return '$value';
    if (value is List) {
      if (value.isEmpty) return '—';
      return value.map(formatValue).join(', ');
    }
    if (value is Map) {
      try {
        final String text = value.toString();
        return text.length > 80 ? '${text.substring(0, 77)}…' : text;
      } on Object {
        return '[object]';
      }
    }
    return '$value';
  }

  static bool _equal(Object? a, Object? b) {
    if (identical(a, b) || a == b) return true;
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }
}
