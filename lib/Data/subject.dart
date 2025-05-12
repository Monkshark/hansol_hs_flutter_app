class Subject {
  final String subjectName;
  final int subjectClass;

  Subject({required this.subjectName, required this.subjectClass});

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
