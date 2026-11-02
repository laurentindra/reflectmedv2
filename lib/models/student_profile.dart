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
    this.geminiApiKey = 'tk-gw-1497088843dae48fd56bf0ea0ff10a52ea80886e047360371e1aab2f9d00c394',
    this.geminiModelName = 'glm-5.3-flash',
    this.apiBaseUrl = 'https://tokengateway.dev/v1',
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
    final key = (savedKey != null &&
            savedKey.trim().isNotEmpty &&
            !savedKey.contains('tk-gw-46b82e15'))
        ? savedKey.trim()
        : 'tk-gw-1497088843dae48fd56bf0ea0ff10a52ea80886e047360371e1aab2f9d00c394';

    final savedModel = json['geminiModelName'] as String?;
    final model = (savedModel != null &&
            savedModel.trim().isNotEmpty &&
            !savedModel.contains('deepseek') &&
            !savedModel.contains('pass-glm') &&
            !savedModel.contains('gemini'))
        ? savedModel.trim()
        : 'glm-5.3-flash';

    final savedUrl = json['apiBaseUrl'] as String?;
    final url = (savedUrl != null &&
            savedUrl.trim().isNotEmpty &&
            !savedUrl.contains('tokengateway.ai.id'))
        ? savedUrl.trim()
        : 'https://tokengateway.dev/v1';

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
