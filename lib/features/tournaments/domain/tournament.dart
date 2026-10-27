class Tournament {
  const Tournament({
    required this.id,
    required this.title,
    required this.venueName,
    required this.address,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.maxSlots,
    required this.currentSlots,
    required this.startDate,
    required this.status,
    this.minTier,
    this.maxTier,
    this.bannerUrl,
  });

  final String id;
  final String title;
  final String venueName;
  final String address;
  final String format; // singles, doubles, mixed
  final double entryFee;
  final double prizePool;
  final int maxSlots;
  final int currentSlots;
  final DateTime startDate;
  final String status; // registering, ongoing, completed
  final String? minTier;
  final String? maxTier;
  final String? bannerUrl;

  bool get isFull => currentSlots >= maxSlots;
  int get availableSlots => (maxSlots - currentSlots).clamp(0, maxSlots);

  String get formatLabel {
    switch (format) {
      case 'singles':
        return 'Đơn Nam / Nữ';
      case 'mixed':
        return 'Đôi Nam Nữ';
      case 'doubles':
      default:
        return 'Đôi Nam / Đôi Nữ';
    }
  }

  String get rankRequirement {
    if (minTier != null && maxTier != null) {
      return '$minTier - $maxTier';
    } else if (minTier != null) {
      return 'Từ $minTier trở lên';
    } else if (maxTier != null) {
      return 'Dưới $maxTier';
    }
    return 'Mọi cấp độ';
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      title: json['title'] as String,
      venueName: json['venue_name'] as String,
      address: json['address'] as String,
      format: json['format'] as String? ?? 'doubles',
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prize_pool'] as num?)?.toDouble() ?? 0.0,
      maxSlots: (json['max_slots'] as num?)?.toInt() ?? 16,
      currentSlots: (json['current_slots'] as num?)?.toInt() ?? 0,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      status: json['status'] as String? ?? 'registering',
      minTier: json['min_tier'] as String?,
      maxTier: json['max_tier'] as String?,
      bannerUrl: json['banner_url'] as String?,
    );
  }
}
