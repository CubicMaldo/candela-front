

// ─── Badge levels ─────────────────────────────────────────────────────────────
enum BadgeLevel {
  newcomer('Nuevo en la vuelta'),
  streetwise('Callejero'),
  regular('Parroquiano'),
  veteran('Teso'),
  legend('Leyenda');

  final String label;
  const BadgeLevel(this.label);

  static BadgeLevel from(Object? value) {
    if (value is String) {
      for (final b in BadgeLevel.values) {
        if (b.label == value) return b;
      }
    }
    return BadgeLevel.newcomer;
  }
}

enum PrivacyMode {
  public('PUBLIC'),
  friends('FRIENDS'),
  private('PRIVATE');

  final String raw;
  const PrivacyMode(this.raw);

  static PrivacyMode from(Object? value) {
    if (value is String) {
      for (final p in PrivacyMode.values) {
        if (p.raw == value.toUpperCase()) return p;
      }
    }
    return PrivacyMode.friends;
  }
}

enum PlanStatus {
  pending('PENDIENTE'),
  accepted('ACEPTADO'),
  completed('CONCRETADO'),
  failed('NO_CONCRETADO'),
  declined('DECLINADO');

  final String raw;
  const PlanStatus(this.raw);

  static PlanStatus from(Object? value) {
    if (value is String) {
      for (final s in PlanStatus.values) {
        if (s.raw == value.toUpperCase()) return s;
      }
    }
    return PlanStatus.pending;
  }
}

/// Who can see and join a plan.
///   public  — anyone can discover and join (no invitee).
///   friends — only the creator's friends can discover and join (no invitee).
///   invite  — a single friend is invited directly (the classic 1:1 flow).
enum PlanVisibility {
  public('PUBLIC'),
  friends('FRIENDS'),
  invite('INVITE');

  final String raw;
  const PlanVisibility(this.raw);

  static PlanVisibility from(Object? value) {
    if (value is String) {
      for (final v in PlanVisibility.values) {
        if (v.raw == value.toUpperCase()) return v;
      }
    }
    return PlanVisibility.invite;
  }
}

DateTime parseDate(Object? v) =>
    DateTime.tryParse(v?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime? parseDateOrNull(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

int parseInt(Object? v) => (v as num?)?.toInt() ?? 0;

