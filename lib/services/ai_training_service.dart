import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_exemplar.dart';
import '../core/constants/prompt_templates.dart';

/// Layanan Pengelolaan Kalibrasi Persona & Pelatihan AI Refleksi
class AiTrainingService {
  static const String _personaKey = 'medireflect_persona_config';
  static const String _exemplarsKey = 'medireflect_training_exemplars';

  static final AiTrainingService _instance = AiTrainingService._internal();
  factory AiTrainingService() => _instance;
  AiTrainingService._internal() {
    _exemplars = _getDefaultExemplars();
  }

  MentorPersonaConfig _currentPersona = MentorPersonaConfig();
  List<TrainingExemplar> _exemplars = [];

  MentorPersonaConfig get currentPersona => _currentPersona;
  List<TrainingExemplar> get exemplars => List.unmodifiable(_exemplars);

  /// Inisialisasi data dari penyimpanan lokal
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Muat konfigurasi persona
    final personaJsonStr = prefs.getString(_personaKey);
    if (personaJsonStr != null) {
      try {
        _currentPersona = MentorPersonaConfig.fromJson(
          jsonDecode(personaJsonStr) as Map<String, dynamic>,
        );
      } catch (_) {
        _currentPersona = MentorPersonaConfig();
      }
    }

    // 2. Muat bank kasus exemplar
    final exemplarsJsonStr = prefs.getString(_exemplarsKey);
    if (exemplarsJsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(exemplarsJsonStr);
        _exemplars = list.map((e) => TrainingExemplar.fromJson(e)).toList();
      } catch (_) {
        _exemplars = _getDefaultExemplars();
      }
    } else {
      _exemplars = _getDefaultExemplars();
    }
  }

  /// Simpan perubahan persona
  Future<void> updatePersona(MentorPersonaConfig config) async {
    _currentPersona = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, jsonEncode(config.toJson()));
  }

  /// Tambah exemplar baru
  Future<void> addExemplar(TrainingExemplar exemplar) async {
    _exemplars.add(exemplar);
    await _persistExemplars();
  }

  /// Hapus exemplar
  Future<void> deleteExemplar(String id) async {
    _exemplars.removeWhere((e) => e.id == id);
    await _persistExemplars();
  }

  /// Reset ke default bawaan sistem
  Future<void> resetToDefaults() async {
    _currentPersona = MentorPersonaConfig();
    _exemplars = _getDefaultExemplars();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, jsonEncode(_currentPersona.toJson()));
    await _persistExemplars();
  }

  Future<void> _persistExemplars() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _exemplars.map((e) => e.toJson()).toList();
    await prefs.setString(_exemplarsKey, jsonEncode(list));
  }

  /// Buat System Prompt Dinamis yang mengintegrasikan kalibrasi persona & few-shot exemplars
  String buildCalibratedSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(PromptTemplates.clinicalMentorSystemPrompt);
    buffer.writeln('\n--- KALIBRASI PERSONA AKTIF OLEH EDUKATOR ---');
    buffer.writeln('1. Skala Empati: ${_currentPersona.empathyLevel.toStringAsFixed(1)} / 5.0 (Tingkat kehangatan dan validasi emosional).');
    buffer.writeln('2. Intensitas Tantangan Sokratik: ${_currentPersona.socraticChallenge.toStringAsFixed(1)} / 5.0 (Kedalaman pertanyaan menggali asumsi implisit mahasiswa).');
    buffer.writeln('3. Ketertiban Akademik: ${_currentPersona.academicScaffolding.toStringAsFixed(1)} / 5.0 (Pematuhan struktur Gibbs 6-fase & rencana SMART).');
    buffer.writeln('4. Kerangka Refleksi Utama: ${_currentPersona.activeFramework}.');

    if (_currentPersona.detectAssessmentTension) {
      buffer.writeln('- ATURAN KHUSUS: Aktifkan perlindungan "Assessment Tension". Tegaskan bahwa percakapan ini murni formatif dan bukan evaluasi nilai kelulusan.');
    }
    if (_currentPersona.autoSuggestLiterature) {
      buffer.writeln('- ANJURAN EBM: Berikan rujukan literatur klinis/etika singkat jika relevan untuk memicu pembelajaran mandiri.');
    }

    // Injeksi Few-shot Exemplars (In-Context Learning)
    if (_exemplars.isNotEmpty) {
      buffer.writeln('\n--- CONTOH TELADAN MENTORING KLINIS (FEW-SHOT TRAINING EXEMPLARS) ---');
      buffer.writeln('Gunakan contoh pasangan dialog berikut sebagai acuan gaya respons ideal Anda:\n');
      for (var i = 0; i < _exemplars.length && i < 4; i++) {
        final ex = _exemplars[i];
        buffer.writeln('Contoh ${i + 1} [Stase ${ex.department} - Target Fase: ${ex.targetGibbsPhase}]:');
        buffer.writeln('Curhat Mahasiswa: "${ex.studentInput}"');
        buffer.writeln('Respons Mentor Ideal: "${ex.idealMentorResponse}"\n');
      }
    }

    return buffer.toString();
  }

  /// Ekspor seluruh bank kasus ke format JSONL Fine-Tuning Google Gemini / Vertex AI
  String exportToJsonl() {
    final systemPrompt = buildCalibratedSystemPrompt();
    final buffer = StringBuffer();
    for (final ex in _exemplars) {
      final jsonMap = ex.toFineTuningFormat(systemPrompt);
      buffer.writeln(jsonEncode(jsonMap));
    }
    return buffer.toString();
  }

  /// Uji coba respons di Playground (Simulasi Offline / Online)
  Future<Map<String, dynamic>> testPlaygroundPrompt({
    required String testInput,
    required String clinicalContext,
  }) async {
    // Simulasi respons terkalibrasi cerdas
    await Future.delayed(const Duration(milliseconds: 650));

    final empathy = _currentPersona.empathyLevel;
    final socratic = _currentPersona.socraticChallenge;

    String responseText = '';
    String depth = 'Analytical';
    double score = 88.0;

    if (testInput.toLowerCase().contains('gagal') ||
        testInput.toLowerCase().contains('panik') ||
        testInput.toLowerCase().contains('salah')) {
      if (empathy >= 4.0) {
        responseText =
            'Terima kasih sudah mau berbagi hal yang berat ini dengan jujur. Menghadapi situasi tidak terduga di $clinicalContext tentu memicu rasa cemas dan bersalah yang sangat wajar bagi seorang calon dokter.\n\n'
            'Mari kita urai bersama secara aman: Saat Anda merasakan kepanikan itu pertama kali, apa faktor lingkungan atau komunikasi yang menurut Anda paling memperberat situasi?';
      } else {
        responseText =
            'Pengalaman klinis di $clinicalContext ini merupakan momen berharga. Mari kita bedah objektif: tindakan apa yang pertama kali Anda ambil, dan bagaimana respon tim saat itu?';
      }
      depth = 'Analytical';
      score = 91.5;
    } else {
      responseText =
          'Refleksi yang sangat baik mengenai kasus di $clinicalContext. Anda telah mulai menghubungkan teori dengan realitas lapangan.\n\n'
          'Jika kita telaah dari kacamata keselamatan pasien, langkah konkret apa yang ingin Anda persiapkan sebelum jaga berikutnya agar respons Anda lebih terstruktur?';
      depth = 'Transformative';
      score = 94.0;
    }

    return {
      'response': responseText,
      'depth': depth,
      'score': score,
      'gibbsPhaseDetected': 'Feelings -> Evaluation',
      'calibratedPersona': {
        'empathy': empathy,
        'socratic': socratic,
      },
    };
  }

  /// Bank Kasus Bawaan Berdasarkan Kasus Nyata Mahasiswa Kedokteran (AMEE Guide 44)
  List<TrainingExemplar> _getDefaultExemplars() {
    return [
      TrainingExemplar(
        id: 'ex-01',
        title: 'Gagal Kanulasi Vena Pasien Pediatri',
        department: 'Ilmu Kesehatan Anak',
        clinicalScenario: 'Koas gagal memasang infus pada balita dehidrasi setelah 2 kali tusukan, ibu pasien menangis dan marah.',
        studentInput: 'Dok, tadi di bangsal anak aku gagal pasang infus balita sampai 2 kali tusuk. Ibunya sampai nangis histeris dan marahin aku. Aku merasa bersalah banget dan merasa ga berbakat jadi dokter.',
        idealMentorResponse: 'Perasaan bersalah dan ragu pada diri sendiri itu sangat wajar dialami setiap dokter saat menghadapi situasi pediatri yang tegang. Mari kita tarik napas sejenak. Secara teknis vena balita memang sangat kolaps saat dehidrasi. Apa yang membuatmu merasa itu kegagalan pribadi, bukan tantangan klinis bersama tim? Dan apa yang bisa kita pelajari dari cara mengelola ekspektasi orang tua sebelum tindakan?',
        targetGibbsPhase: 'Feelings & Analysis',
        targetDepthLevel: 'Analytical',
        tags: ['Pediatri', 'Keterampilan Klinis', 'Manajemen Emosi', 'Komunikasi'],
        isDefault: true,
      ),
      TrainingExemplar(
        id: 'ex-02',
        title: 'Menyampaikan Berita Buruk (SPIKES Protocol)',
        department: 'Ilmu Penyakit Dalam',
        clinicalScenario: 'Konsul keluarga pasien ca kolon metastasis, keluarga menolak pasien diberi tahu diagnosisnya.',
        studentInput: 'Tadi DPJP meminta saya mendampingi saat menyampaikan hasil biopsi ca kolon stadium 4. Tapi anak tertua minta ibunya jangan diberi tahu. Saya bingung antara hak otonomi pasien dan permintaan keluarga.',
        idealMentorResponse: 'Dilema bioetika antara prinsip autonomy pasien dan beneficence/non-maleficence menurut persepsi keluarga adalah salah satu ujian klinis paling kompleks. Saat kamu menyaksikan perdebatan itu tadi, nilai-nilai etis apa yang paling berbenturan di benakmu? Menurutmu bagaimana protokol SPIKES bisa menjembatani kekhawatiran keluarga tanpa melanggar hak informasi pasien?',
        targetGibbsPhase: 'Analysis & Evaluation',
        targetDepthLevel: 'Transformative',
        tags: ['Bioetika', 'Breaking Bad News', 'SPIKES', 'Autonomy'],
        isDefault: true,
      ),
      TrainingExemplar(
        id: 'ex-03',
        title: 'Kejadian Nyaris Cedera (Near-Miss) Dosis Obat',
        department: 'Farmakologi Klinis & IGD',
        clinicalScenario: 'Hampir salah memberikan dosis paracetamol infus pada pasien berat badan rendah karena terburu-buru.',
        studentInput: 'Tadi di IGD rame banget. Aku hampir aja kasih paracetamol 1 gram ke pasien remaja kurus dengan BB 32 kg. Untung perawat senior mengingatkan dosis maksimal mg/kgBB. Aku gemetaran sampai sekarang.',
        idealMentorResponse: 'Sangat bersyukur perawat senior menangkap hal itu tepat waktu—inilah bukti pentingnya kerja sama tim interprofesional (IPE). Jangan hukum dirimu berlebihan, tetapi mari kita ubah rasa gemetar ini menjadi benteng keselamatan pasien. Menurutmu, celah sistem apa saat situasi IGD padat tadi yang memicu kelalaian menghitung dosis? Mekanisme double-check apa yang akan kamu terapkan mulai shift berikutnya?',
        targetGibbsPhase: 'Evaluation & Action Plan',
        targetDepthLevel: 'Transformative',
        tags: ['Patient Safety', 'Near Miss', 'Kolaborasi Interprofesional', 'Dosis'],
        isDefault: true,
      ),
      TrainingExemplar(
        id: 'ex-04',
        title: 'Konflik Hierarki dengan Residen Senior',
        department: 'Ilmu Bedah',
        clinicalScenario: 'Koas ditegur keras di depan pasien dan perawat saat ronde karena lupa hasil lab elektrolit.',
        studentInput: 'Tadi pagi pas ronde bedah, residen senior bentak saya di depan pasien dan suster karena hasil elektrolit belum saya print. Saya malu dan sakit hati sekali, sampai ga bisa konsentrasi belajar seharian.',
        idealMentorResponse: 'Ditegur di depan publik jelas melukai rasa percaya diri dan martabat belajar kita. Emosi sedih, malu, dan marah yang kamu rasakan sangat bisa dipahami. Sekarang, mari pisahkan dua hal: cara penyampaian senior yang kurang ideal, dan tanggung jawab data pasien yang dibutuhkan. Menurutmu, mengapa hasil elektrolit itu begitu krusial bagi keselamatan pasien bedah tadi? Dan bagaimana caramu menjaga profesionalitas sembari tetap merawat kesehatan mentalmu sendiri?',
        targetGibbsPhase: 'Feelings & Analysis',
        targetDepthLevel: 'Analytical',
        tags: ['Hierarki Klinis', 'Kesehatan Mental', 'Profesionalisme', 'Resiliensi'],
        isDefault: true,
      ),
    ];
  }
}
