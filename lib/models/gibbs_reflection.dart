class SmartActionPlan {
  String specific;
  String measurable;
  String achievable;
  String relevant;
  String timeBound;

  SmartActionPlan({
    this.specific = '',
    this.measurable = '',
    this.achievable = '',
    this.relevant = '',
    this.timeBound = '',
  });

  Map<String, dynamic> toJson() => {
    'specific': specific,
    'measurable': measurable,
    'achievable': achievable,
    'relevant': relevant,
    'timeBound': timeBound,
  };

  factory SmartActionPlan.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SmartActionPlan();
    return SmartActionPlan(
      specific: json['specific'] ?? '',
      measurable: json['measurable'] ?? '',
      achievable: json['achievable'] ?? '',
      relevant: json['relevant'] ?? '',
      timeBound: json['timeBound'] ?? '',
    );
  }

  bool get isComplete =>
      specific.isNotEmpty &&
      measurable.isNotEmpty &&
      achievable.isNotEmpty &&
      relevant.isNotEmpty &&
      timeBound.isNotEmpty;
}

enum ReflectionDepth {
  superficial,
  analytical,
  transformative,
}

class GibbsReflection {
  final String id;
  final DateTime createdAt;
  String title;
  String studentName;
  String studentId;
  String department;
  String hospital;
  String supervisorName;

  // Gibbs 6 Stages
  String description; // 1. Description
  String feelings;    // 2. Feelings
  String evaluation;  // 3. Evaluation
  String analysis;    // 4. Analysis
  String conclusion;  // 5. Conclusion
  String actionPlan;  // 6. Action Plan

  SmartActionPlan smartAction;
  ReflectionDepth depthLevel;
  String depthRationale;
  String keyTakeaway;

  GibbsReflection({
    required this.id,
    required this.createdAt,
    this.title = 'Refleksi Pengalaman Klinis',
    this.studentName = '',
    this.studentId = '',
    this.department = 'Ilmu Penyakit Dalam',
    this.hospital = 'RSUP Pendidikan Utama',
    this.supervisorName = '',
    this.description = '',
    this.feelings = '',
    this.evaluation = '',
    this.analysis = '',
    this.conclusion = '',
    this.actionPlan = '',
    SmartActionPlan? smartAction,
    this.depthLevel = ReflectionDepth.analytical,
    this.depthRationale = '',
    this.keyTakeaway = '',
  }) : smartAction = smartAction ?? SmartActionPlan();

  String get depthLabel {
    switch (depthLevel) {
      case ReflectionDepth.superficial:
        return 'Superficial (Deskriptif)';
      case ReflectionDepth.analytical:
        return 'Analytical (Reflektif Mendalam)';
      case ReflectionDepth.transformative:
        return 'Transformative (Pergeseran Paradigma)';
    }
  }

  int get completionPercentage {
    int count = 0;
    if (description.trim().isNotEmpty) count++;
    if (feelings.trim().isNotEmpty) count++;
    if (evaluation.trim().isNotEmpty) count++;
    if (analysis.trim().isNotEmpty) count++;
    if (conclusion.trim().isNotEmpty) count++;
    if (actionPlan.trim().isNotEmpty) count++;
    return ((count / 6) * 100).round();
  }

  bool get isComplete => completionPercentage >= 95;

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'title': title,
    'studentName': studentName,
    'studentId': studentId,
    'department': department,
    'hospital': hospital,
    'supervisorName': supervisorName,
    'description': description,
    'feelings': feelings,
    'evaluation': evaluation,
    'analysis': analysis,
    'conclusion': conclusion,
    'actionPlan': actionPlan,
    'smartAction': smartAction.toJson(),
    'depthLevel': depthLevel.name,
    'depthRationale': depthRationale,
    'keyTakeaway': keyTakeaway,
  };

  factory GibbsReflection.fromJson(Map<String, dynamic> json) => GibbsReflection(
    id: json['id'] ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    title: json['title'] ?? 'Refleksi Pengalaman Klinis',
    studentName: json['studentName'] ?? '',
    studentId: json['studentId'] ?? '',
    department: json['department'] ?? '',
    hospital: json['hospital'] ?? '',
    supervisorName: json['supervisorName'] ?? '',
    description: json['description'] ?? '',
    feelings: json['feelings'] ?? '',
    evaluation: json['evaluation'] ?? '',
    analysis: json['analysis'] ?? '',
    conclusion: json['conclusion'] ?? '',
    actionPlan: json['actionPlan'] ?? '',
    smartAction: SmartActionPlan.fromJson(json['smartAction']),
    depthLevel: ReflectionDepth.values.firstWhere(
      (e) => e.name == json['depthLevel'],
      orElse: () => ReflectionDepth.analytical,
    ),
    depthRationale: json['depthRationale'] ?? '',
    keyTakeaway: json['keyTakeaway'] ?? '',
  );
}
