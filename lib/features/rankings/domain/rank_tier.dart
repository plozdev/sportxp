/// Community-style skill bands. Elo boundaries are SportXP policy v2,
/// not a Vietnamese federation or BWF classification.
enum RankGroup {
  newbie('Nhập môn'),
  weak('Yếu'),
  lowerIntermediate('Trung bình yếu'),
  intermediate('Trung bình'),
  upperIntermediate('Trung bình khá'),
  advanced('Khá'),
  strong('Tốt'),
  eliteAmateur('Cao thủ phong trào');

  const RankGroup(this.label);
  final String label;
}

enum RankTier {
  newbie(
    'Nhập môn',
    300,
    RankGroup.newbie,
    'Đang làm quen luật, cách cầm vợt và điểm chạm cầu.',
  ),
  weakMinus(
    'Yếu-',
    400,
    RankGroup.weak,
    'Biết luật cơ bản nhưng còn khó đưa cầu qua lưới ổn định.',
  ),
  weak(
    'Yếu',
    450,
    RankGroup.weak,
    'Duy trì được cầu chậm; giao và phông còn nhiều lỗi.',
  ),
  weakPlus(
    'Yếu+',
    500,
    RankGroup.weak,
    'Đã có giao, phông, bỏ nhỏ cơ bản; di chuyển còn bị động.',
  ),
  lowerIntermediateMinus(
    'TBY-',
    550,
    RankGroup.lowerIntermediate,
    'Biết kỹ thuật nền nhưng điểm chạm và vị trí đứng chưa đều.',
  ),
  lowerIntermediate(
    'TBY',
    600,
    RankGroup.lowerIntermediate,
    'Đánh được các tình huống quen; dễ hụt khi bị đổi hướng.',
  ),
  lowerIntermediatePlus(
    'TBY+',
    650,
    RankGroup.lowerIntermediate,
    'Cơ bản ổn định hơn, bắt đầu giữ vị trí và phối hợp đánh đôi.',
  ),
  intermediateMinus(
    'TB-',
    700,
    RankGroup.intermediate,
    'Có bộ pháp và cầu cơ bản; giảm độ ổn định khi bị ép tốc độ.',
  ),
  intermediate(
    'TB',
    750,
    RankGroup.intermediate,
    'Duy trì được nhịp cầu, phông và phòng thủ cơ bản, biết đổi công thủ.',
  ),
  intermediatePlus(
    'TB+',
    800,
    RankGroup.intermediate,
    'Chủ động khai thác khoảng trống, phối hợp đôi và điều cầu rõ ý đồ.',
  ),
  upperIntermediateMinus(
    'TBK-',
    900,
    RankGroup.upperIntermediate,
    'Nền kỹ thuật chắc; bước đầu tạo và duy trì thế chủ động.',
  ),
  upperIntermediate(
    'TBK',
    950,
    RankGroup.upperIntermediate,
    'Phối hợp nhiều đường cầu, bọc lót và giữ nhịp tốt.',
  ),
  upperIntermediatePlus(
    'TBK+',
    1000,
    RankGroup.upperIntermediate,
    'Đọc tình huống nhanh, điều hướng phòng thủ và ít lỗi cầu thuận lợi.',
  ),
  advancedMinus(
    'Khá-',
    1100,
    RankGroup.advanced,
    'Có nhiều phương án xử lý và giữ được độ ổn định khi bị ép.',
  ),
  advanced(
    'Khá',
    1200,
    RankGroup.advanced,
    'Kiểm soát nhịp, điểm rơi và chuyển trạng thái công thủ hiệu quả.',
  ),
  advancedPlus(
    'Khá+',
    1300,
    RankGroup.advanced,
    'Chiến thuật linh hoạt, tạo áp lực liên tục trước đối thủ mạnh.',
  ),
  strongMinus(
    'Tốt-',
    1400,
    RankGroup.strong,
    'Kỹ thuật và thể lực vững; duy trì chất lượng ở nhịp thi đấu cao.',
  ),
  strong(
    'Tốt',
    1500,
    RankGroup.strong,
    'Đọc trận, xử lý cầu khó và phối hợp đồng đội ở mức phong trào mạnh.',
  ),
  strongPlus(
    'Tốt+',
    1600,
    RankGroup.strong,
    'Độ ổn định rất cao, thích ứng tốt với nhiều lối chơi mạnh.',
  ),
  eliteAmateur(
    'Cao thủ phong trào',
    1700,
    RankGroup.eliteAmateur,
    'Nhóm dẫn đầu trong hệ thống; không tự suy ra danh hiệu bán chuyên hoặc chuyên nghiệp.',
  );

  const RankTier(this.label, this.minimumElo, this.group, this.description);
  final String label, description;
  final int minimumElo;
  final RankGroup group;

  RankTier? get next => index + 1 < values.length ? values[index + 1] : null;
  int? get maximumElo => next == null ? null : next!.minimumElo - 1;

  static RankTier fromElo(int elo) {
    if (elo < 0) throw ArgumentError.value(elo, 'elo');
    // Established ratings may drop below the onboarding floor of 300.
    return values.lastWhere(
      (tier) => elo >= tier.minimumElo,
      orElse: () => newbie,
    );
  }
}
