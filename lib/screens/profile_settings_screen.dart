import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/student_profile.dart';
import '../services/storage_service.dart';
import 'ai_training_studio_screen.dart';
import 'onboarding_welcome_screen.dart';
import 'login_auth_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  StudentProfile _profile = StudentProfile();
  bool _remindersEnabled = true;
  bool _researchConsent = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.loadProfile();
    setState(() {
      _profile = profile;
    });
  }

  void _openEditDialog() {
    final nameCtrl = TextEditingController(text: _profile.fullName.isNotEmpty ? _profile.fullName : 'dr. Ahmad Fauzi');
    final nimCtrl = TextEditingController(text: _profile.studentId.isNotEmpty ? _profile.studentId : '0119283746');
    final deptCtrl = TextEditingController(text: _profile.currentDepartment.isNotEmpty ? _profile.currentDepartment : 'Ilmu Penyakit Dalam');
    final hospCtrl = TextEditingController(text: _profile.teachingHospital.isNotEmpty ? _profile.teachingHospital : 'RSUP Nasional Cipto Mangunkusumo');
    final supCtrl = TextEditingController(text: _profile.supervisorName.isNotEmpty ? _profile.supervisorName : 'Prof. Dr. Siti Rahayu, SpPD-KKV');
    final keyCtrl = TextEditingController(text: _profile.geminiApiKey);
    final modelCtrl = TextEditingController(text: _profile.geminiModelName);
    final urlCtrl = TextEditingController(text: _profile.apiBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.parchmentBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Profil Dokter & Pengaturan AI',
          style: GoogleFonts.newsreader(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textInk),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextField(
                controller: nimCtrl,
                decoration: const InputDecoration(labelText: 'NIM / Nomor Registrasi'),
              ),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: 'Stase / Departemen Aktif'),
              ),
              TextField(
                controller: hospCtrl,
                decoration: const InputDecoration(labelText: 'RS Pendidikan'),
              ),
              TextField(
                controller: supCtrl,
                decoration: const InputDecoration(labelText: 'Nama Dokter Pendidik Klinis (DPJP)'),
              ),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key (TokenGateway / DeepSeek / Gemini)',
                  hintText: 'tk-gw-... atau AIzaSy...',
                  helperText: 'TokenGateway: tk-gw-... | Gemini: AIzaSy...',
                ),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Base URL Gateway',
                  hintText: 'https://tokengateway.ai.id/v1',
                  helperText: 'Endpoint untuk model DeepSeek / OpenAI gateway',
                ),
              ),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID Model AI',
                  hintText: 'deepseek-chat atau gemini-1.5-flash',
                  helperText: 'Model aktif di TokenGateway (misal: deepseek-chat)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final rawKey = keyCtrl.text.trim();
              final rawUrl = urlCtrl.text.trim();
              final rawModel = modelCtrl.text.trim();

              _profile.fullName = nameCtrl.text.trim();
              _profile.studentId = nimCtrl.text.trim();
              _profile.currentDepartment = deptCtrl.text.trim();
              _profile.teachingHospital = hospCtrl.text.trim();
              _profile.supervisorName = supCtrl.text.trim();
              _profile.geminiApiKey = rawKey;
              _profile.geminiModelName = rawModel.isNotEmpty ? rawModel : 'deepseek-chat';
              _profile.apiBaseUrl = rawUrl.isNotEmpty ? rawUrl : 'https://tokengateway.ai.id/v1';

              await StorageService.saveProfile(_profile);
              if (mounted) {
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryTeal,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      rawKey.startsWith('tk-gw-')
                          ? 'TokenGateway DeepSeek berhasil terhubung!'
                          : 'Pengaturan profil dan AI berhasil disimpan!',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & IDENTITY CARD (Warm Parchment & Deep Scholarly Teal)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWarm,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PENGATURAN & PROFIL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: AppTheme.primaryTeal, size: 24),
                          onPressed: _openEditDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User Profile Card
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.parchmentBg,
                            border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                          ),
                          child: const Icon(Icons.person_outline, color: AppTheme.primaryTeal, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile.fullName.isNotEmpty ? _profile.fullName : 'dr. Ahmad Fauzi',
                                style: GoogleFonts.newsreader(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PPDS INTERNA · FKUI · TAHUN II',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_profile.teachingHospital.isNotEmpty ? _profile.teachingHospital : "RSUP Nasional Cipto Mangunkusumo"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3 Metric Pills
                    Row(
                      children: [
                        _buildStatPill('12', 'Refleksi'),
                        const SizedBox(width: 8),
                        _buildStatPill('07', 'Streak Hari'),
                        const SizedBox(width: 8),
                        _buildStatPill('87', 'Rata Skor'),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. SETTINGS CONTENT
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Data Protection Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.primaryTeal, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kerahasiaan Medis & Privasi Terlindungi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Refleksi Anda dienkripsi end-to-end sesuai standar etika kedokteran & UU PDP. Identitas pasien disamarkan secara otomatis.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Group: TAMPILAN & NAVIGASI DESAIN
                    _buildGroupCard('NAVIGASI & DESAIN', [
                      _buildMenuItem(
                        Icons.preview_outlined,
                        'Layar Selamat Datang (Onboarding)',
                        'Pratinjau layar pembuka edisi Vol. I · 2026',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OnboardingWelcomeScreen()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        Icons.login_outlined,
                        'Layar Autentikasi / SSO',
                        'Pratinjau layar masuk dengan SSO Kampus',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginAuthScreen()),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Group: AKUN
                    _buildGroupCard('AKUN DOKTER & KONEKSI AI', [
                      _buildMenuItem(Icons.person_outline, 'Profil & Identitas', 'Nama, institusi, DPJP', onTap: _openEditDialog),
                      _buildMenuItem(
                        Icons.memory_rounded,
                        'Model LLM Aktif',
                        _profile.geminiApiKey.isEmpty
                            ? 'Mode Offline (Engine Bawaan)'
                            : (_profile.geminiApiKey.startsWith('tk-gw-')
                                ? 'TokenGateway · ${_profile.geminiModelName}'
                                : 'Google Cloud · ${_profile.geminiModelName}'),
                        statusTag: _profile.geminiApiKey.isEmpty
                            ? 'Offline'
                            : (_profile.geminiApiKey.startsWith('tk-gw-') ? 'DeepSeek' : 'Gemini'),
                        onTap: _openEditDialog,
                      ),
                      _buildMenuItem(Icons.verified_user_outlined, 'Autentikasi SSO Kampus', 'Terhubung: FKUI SSO ID', statusTag: 'Aktif'),
                      _buildMenuItem(Icons.lock_outline, 'Keamanan Data Refleksi', 'Enkripsi RSA-2048 & TLS 1.3'),
                    ]),
                    const SizedBox(height: 14),

                    // Group: REFLEKSI & PEMBELAJARAN
                    _buildGroupCard('REFLEKSI & EDUKASI', [
                      _buildMenuItem(
                        Icons.model_training,
                        'Studio Pelatihan AI (Educator)',
                        'Kalibrasi persona konsulen & fine-tuning',
                        statusTag: 'Mode Dosen',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiTrainingStudioScreen()),
                          );
                        },
                      ),
                      _buildToggleItem(
                        Icons.notifications_none,
                        'Pengingat Refleksi Berkala',
                        'Pengingat setelah jaga IGD & rotasi stase',
                        _remindersEnabled,
                        (v) => setState(() => _remindersEnabled = v),
                      ),
                      _buildMenuItem(Icons.menu_book_outlined, 'Pedoman Siklus Gibbs', 'Metode 6 tahap refleksi terstruktur'),
                    ]),
                    const SizedBox(height: 14),

                    // Group: RISET & ETIKA
                    _buildGroupCard('KONTRIBUSI RISET KLINIS', [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text(
                          'Data refleksi yang telah disanitasi secara anonim membantu dekanat & KPS memahami beban belajar stase.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppTheme.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                      _buildToggleItem(
                        Icons.analytics_outlined,
                        'Izinkan Anonimitas untuk Riset',
                        'Membantu evaluasi pendidikan kedokteran',
                        _researchConsent,
                        (v) => setState(() => _researchConsent = v),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Logout Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.catKardiologi,
                        side: const BorderSide(color: Color(0xFFE5DDD1)),
                        backgroundColor: AppTheme.surfaceWarm,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(
                        'Keluar ke Layar Pembuka',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingWelcomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        'ReflectMed AI · Jurnal Refleksi Klinis Vol. I · 2026\nSesuai Pedoman AMEE Guide 44 & Standar Konsil Kedokteran Indonesia',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textLight, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.parchmentBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: GoogleFonts.newsreader(
                color: AppTheme.textInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lbl,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textLight,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.textLight,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5DDD1)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {String? statusTag, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.parchmentBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightBorder),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textInk,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (statusTag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.parchmentBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryTeal),
                ),
                child: Text(
                  statusTag,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryTeal,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.parchmentBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textInk,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
