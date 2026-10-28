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
    this.geminiApiKey = 'tk-gw-46b82e15f253e09d47829bd9712d2d3df6104ea2b57af30e88e80aa076a9f7c7',
    this.geminiModelName = 'deepseek-chat',
    this.apiBaseUrl = 'https://tokengateway.ai.id/v1',
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
    final key = (savedKey != null && savedKey.trim().isNotEmpty)
        ? savedKey.trim()
        : 'tk-gw-46b82e15f253e09d47829bd9712d2d3df6104ea2b57af30e88e80aa076a9f7c7';

    final savedModel = json['geminiModelName'] as String?;
    final model = (savedModel != null && savedModel.trim().isNotEmpty)
        ? (savedModel.contains('gemini') && key.startsWith('tk-gw-') ? 'deepseek-chat' : savedModel.trim())
        : (key.startsWith('tk-gw-') ? 'deepseek-chat' : 'gemini-1.5-flash');

    final savedUrl = json['apiBaseUrl'] as String?;
    final url = (savedUrl != null && savedUrl.trim().isNotEmpty)
        ? savedUrl.trim()
        : 'https://tokengateway.ai.id/v1';

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
