class Task {
  int? id;
  String title;
  String description;
  String dueDate;
  bool isCompleted;
  bool isRepeated;
  String repeatFrequency;
  List<int>? repeatDays;
  double completionPercentage;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeated = false,
    this.repeatFrequency = 'none',
    this.repeatDays,
    this.completionPercentage = 0.0,
  });

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }

  void resetCompletion() {
    final today = DateTime.now().weekday;
    if (isRepeated && repeatDays != null && repeatDays!.contains(today)) {
      isCompleted = false;
      completionPercentage = 0.0;
    }
  }

// Rest of the code...



static const String table = 'tasks';

  static final List<String> fields = [
    'id',
    'title',
    'description',
    'dueDate',
    'isCompleted',
    'isRepeated',
    'repeatFrequency',
    'repeatDays',
    'completionPercentage',
  ];

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate,
    'isCompleted': isCompleted ? 1 : 0,
    'isRepeated': isRepeated ? 1 : 0,
    'repeatFrequency': repeatFrequency,
    'repeatDays': repeatDays?.join(',') ?? '',
    'completionPercentage': completionPercentage,
  };

  static Task fromJson(Map<String, Object?> json) => Task(
    id: json['id'] as int?,
    title: json['title'] as String,
    description: json['description'] as String,
    dueDate: json['dueDate'] as String,
    isCompleted: (json['isCompleted'] as int) == 1,
    isRepeated: (json['isRepeated'] as int) == 1,
    repeatFrequency: json['repeatFrequency'] as String,
    repeatDays: (json['repeatDays'] as String).isNotEmpty
        ? (json['repeatDays'] as String).split(',').map((e) => int.parse(e)).toList()
        : [],
    completionPercentage: json['completionPercentage'] as double,
  );

  Task copy({int? id}) => Task(
    id: id ?? this.id,
    title: title,
    description: description,
    dueDate: dueDate,
    isCompleted: isCompleted,
    isRepeated: isRepeated,
    repeatFrequency: repeatFrequency,
    repeatDays: repeatDays,
    completionPercentage: completionPercentage,
  );}



