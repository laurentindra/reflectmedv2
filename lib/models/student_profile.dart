class StudentProfile {
  String fullName;
  String studentId; // NIM
  String university;
  String currentDepartment; // Stase / Rotasi Aktif
  String teachingHospital;
  String supervisorName; // Nama DPJP / Dosen Pembimbing
  String geminiApiKey;
  String geminiModelName;
  String apiBaseUrl;

  StudentProfile({
    this.fullName = 'dr. Muda / Mahasiswa Kedokteran',
    this.studentId = '2024010099',
    this.university = 'Fakultas Kedokteran',
    this.currentDepartment = 'Ilmu Penyakit Dalam',
    this.teachingHospital = 'RSUP Pendidikan Utama',
    this.supervisorName = 'dr. Sp.PD, Subsp. (K)',
    this.geminiApiKey = '',
    this.geminiModelName = 'gemini-2.5-flash',
    this.apiBaseUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'studentId': studentId,
    'university': university,
    'currentDepartment': currentDepartment,
    'teachingHospital': teachingHospital,
    'supervisorName': supervisorName,
    'geminiApiKey': geminiApiKey,
    'geminiModelName': geminiModelName,
    'apiBaseUrl': apiBaseUrl,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final savedKey = json['geminiApiKey'] as String?;
    final key = savedKey?.trim() ?? '';

    final savedModel = json['geminiModelName'] as String?;
    final savedModelTrimmed = savedModel?.trim() ?? '';
    final isGeminiKey =
        key.startsWith('AIzaSy') || key.startsWith('AQ.Ab');
    final model = isGeminiKey
        ? (savedModelTrimmed.isEmpty ||
                savedModelTrimmed.contains('deepseek') ||
                savedModelTrimmed.contains('pass-glm') ||
                savedModelTrimmed.contains('glm'))
            ? 'gemini-2.5-flash'
            : savedModelTrimmed
        : (savedModelTrimmed.isNotEmpty &&
                !savedModelTrimmed.contains('deepseek') &&
                !savedModelTrimmed.contains('pass-glm'))
            ? savedModelTrimmed
            : 'glm-5.3-flash';

    final savedUrl = json['apiBaseUrl'] as String?;
    final url = savedUrl?.trim() ?? '';

    return StudentProfile(
      fullName: json['fullName'] ?? 'dr. Muda / Mahasiswa Kedokteran',
      studentId: json['studentId'] ?? '2024010099',
      university: json['university'] ?? 'Fakultas Kedokteran',
      currentDepartment: json['currentDepartment'] ?? 'Ilmu Penyakit Dalam',
      teachingHospital: json['teachingHospital'] ?? 'RSUP Pendidikan Utama',
      supervisorName: json['supervisorName'] ?? 'dr. Sp.PD, Subsp. (K)',
      geminiApiKey: key,
      geminiModelName: model,
      apiBaseUrl: url,
    );
  }
}
