class Subject {
  final String subjectName;
  final int subjectClass;
  final String? category;
  final bool isOriginal;

  Subject({
    required this.subjectName,
    required this.subjectClass,
    this.category,
    this.isOriginal = false,
  });

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'subjectClass': subjectClass,
        if (category != null) 'category': category,
        'isOriginal': isOriginal,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        subjectName: json['subjectName'],
        subjectClass: json['subjectClass'],
        category: json['category'],
        isOriginal: json['isOriginal'] ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          subjectName == other.subjectName &&
          subjectClass == other.subjectClass;

  @override
  int get hashCode => subjectName.hashCode ^ subjectClass.hashCode;
}
