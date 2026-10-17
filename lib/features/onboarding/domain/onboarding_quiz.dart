import '../../rankings/domain/rank_tier.dart';

class QuizChoice {
  const QuizChoice(this.label, this.points);
  final String label;
  final int points;
}

class QuizQuestion {
  const QuizQuestion(this.category, this.title, this.choices);
  final String category, title;
  final List<QuizChoice> choices;
}

abstract final class OnboardingQuiz {
  static const baseElo = 300;
  static const maximumInitialElo = 850;
  static const questions = [
    QuizQuestion(
      'Nền tảng đào tạo',
      'Bạn học chơi cầu lông theo hình thức nào?',
      [
        QuizChoice('Tự chơi với bạn bè, chưa từng học qua thầy/lớp cơ bản', 0),
        QuizChoice(
          'Tự tập theo video hướng dẫn (YouTube/TikTok) và có tập bộ chân',
          50,
        ),
        QuizChoice('Đã học lớp cơ bản với HLV (dưới 6 tháng)', 120),
        QuizChoice(
          'Đã học cơ bản và nâng cao bài bản với HLV (trên 6 tháng)',
          200,
        ),
      ],
    ),
    QuizQuestion(
      'Xử lý cầu cuối sân',
      'Khi bị đối thủ phông cầu sâu về sát vạch cuối sân bên phía trái tay (Backhand), bạn thường xử lý thế nào?',
      [
        QuizChoice(
          'Thường bị hụt cầu hoặc chỉ đẩy nhẹ trả qua lưới được nửa sân',
          0,
        ),
        QuizChoice(
          'Cố gắng lùi nhanh để vòng đầu (Overhead) đánh thuận tay trả về cuối sân',
          60,
        ),
        QuizChoice(
          'Vung vợt trái tay (ve cầu) đưa cầu bay qua lưới về giữa sân đối phương',
          100,
        ),
        QuizChoice(
          'Ve cầu (Backhand clear) nổ cầu đi thẳng về cuối sân đối phương hoặc chém cầu chéo sân',
          150,
        ),
      ],
    ),
    QuizQuestion(
      'Chiến thuật đánh đôi',
      'Trong trận đánh đôi, khi đồng đội của bạn lùi về sau nhảy đập cầu (Smash), bạn sẽ làm gì?',
      [
        QuizChoice(
          'Đứng nguyên ở phần sân của mình (chia đôi sân trái – phải) để thủ',
          0,
        ),
        QuizChoice(
          'Chủ động di chuyển lên sát chữ T (trên lưới) để rình chụp cầu và bọc lót',
          100,
        ),
        QuizChoice(
          'Lên lưới bịt góc thẳng, đồng thời quan sát hướng đập của đồng đội để bắt bài đường trả cầu của đối thủ',
          150,
        ),
      ],
    ),
    QuizQuestion(
      'Mức căng cước',
      'Cây vợt bạn đang đánh thường xuyên nhất được đan (căng) ở mức bao nhiêu kg?',
      [
        QuizChoice(
          'Dưới 9.5 kg (hoặc dùng vợt mua sẵn đã có lưới, không nhớ số kg)',
          0,
        ),
        QuizChoice('Từ 9.5 kg – 10.5 kg (khoảng 21 – 23 lbs)', 50),
        QuizChoice('Từ 10.5 kg – 11.5 kg (khoảng 24 – 25 lbs)', 100),
        QuizChoice('Trên 11.5 kg (từ 26 lbs trở lên)', 130),
      ],
    ),
    QuizQuestion(
      'Kinh nghiệm thi đấu',
      'Tần suất ra sân hiện tại và kinh nghiệm thi đấu của bạn?',
      [
        QuizChoice(
          'Thỉnh thoảng mới đánh (1 buổi/tuần hoặc ít hơn), chỉ đánh vui vẻ',
          0,
        ),
        QuizChoice('Đánh đều đặn 2–3 buổi/tuần tại sân cố định', 50),
        QuizChoice(
          'Đánh ≥ 3 buổi/tuần, đã từng tham gia giải nội bộ CLB/Trường/Công ty',
          100,
        ),
        QuizChoice(
          'Đã từng đạt giải (Top 1-2-3) tại các giải phong trào cấp Quận/Thành phố hoặc giải CLB mở rộng',
          150,
        ),
      ],
    ),
  ];

  static int rawElo(List<int> answers) {
    if (answers.length != questions.length) {
      throw ArgumentError('Cần trả lời đủ 5 câu hỏi.');
    }
    var points = baseElo;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] < 0 || answers[i] >= questions[i].choices.length) {
        throw ArgumentError('Đáp án không hợp lệ.');
      }
      points += questions[i].choices[answers[i]].points;
    }
    return points;
  }

  static int initialElo(List<int> answers) =>
      rawElo(answers).clamp(baseElo, maximumInitialElo);
  static RankTier tier(List<int> answers) =>
      RankTier.fromElo(initialElo(answers));
}
