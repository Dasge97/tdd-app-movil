import 'user.dart';

class Debate {
  final int id;
  final String title;
  final String context;
  final String? question;
  final String? cardSummary;
  final String? sourceName;
  final String? sourceUrl;
  final String? authorType;
  final String? generationModel;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? dayDate;
  final User createdBy;
  final int? commentCount;

  const Debate({
    required this.id,
    required this.title,
    required this.context,
    this.question,
    this.cardSummary,
    this.sourceName,
    this.sourceUrl,
    this.authorType = 'ai',
    this.generationModel,
    this.publishedAt,
    this.createdAt,
    this.dayDate,
    required this.createdBy,
    this.commentCount,
  });

  factory Debate.fromJson(Map<String, dynamic> j) => Debate(
        id: j['id'] as int,
        title: j['title'] as String,
        context: j['context'] as String,
        question: j['question'] as String?,
        cardSummary: j['cardSummary'] as String?,
        sourceName: j['sourceName'] as String?,
        sourceUrl: j['sourceUrl'] as String?,
        authorType: (j['authorType'] as String?) ?? 'ai',
        generationModel: j['generationModel'] as String?,
        publishedAt: j['publishedAt'] != null
            ? DateTime.parse(j['publishedAt'] as String)
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : null,
        dayDate: j['dayDate'] != null
            ? DateTime.parse(j['dayDate'] as String)
            : null,
        createdBy:
            User.fromJson(j['createdBy'] as Map<String, dynamic>),
        commentCount: j['commentCount'] as int?,
      );
}
