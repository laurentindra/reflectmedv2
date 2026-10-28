import 'package:flutter/material.dart';

class QuickScenarioChips extends StatelessWidget {
  final Function(String prompt) onSelectScenario;

  const QuickScenarioChips({Key? key, required this.onSelectScenario}) : super(key: key);

  static const List<Map<String, String>> scenarios = [
    {
      'label': '💉 Gagal Pasang Infus / Kanula',
      'prompt': 'Tadi saat jaga bangsal, aku gagal memasang infus ke pasien lansia dengan vena kolaps sampai 3 kali tusukan. Aku merasa sangat bersalah, gugup di depan keluarga pasien, dan merasa keterampilanku kurang.',
    },
    {
      'label': '🗣️ Komplain Pasien / Keluarga',
      'prompt': 'Keluarga pasien mengeluh karena hasil laboratorium terlambat dan menuduh dokter muda tidak tanggap. Aku bingung harus merespons bagaimana dan merasa tertekan.',
    },
    {
      'label': '🚩 Missed Red Flag / Keraguan Klinis',
      'prompt': 'Tadi saat anamnesis pasien nyeri dada, aku lupa menanyakan riwayat radiasi nyeri ke rahang dan punggung. Untungnya konsulen mengingatkan saat visite. Aku merasa malu dan khawatir hampir melewatkan red flag penting.',
    },
    {
      'label': '📋 Umpan Balik Keras dari Konsulen',
      'prompt': 'Saat ronde pagi, konsulen menegurku di depan tim karena presentasi kasusku berbelit-belit dan tidak langsung to-the-point ke temuan klinis utama. Aku merasa down.',
    },
    {
      'label': '⚖️ Dilema Etik & Kerahasiaan',
      'prompt': 'Keluarga pasien meminta agar diagnosis penyakit terminal tidak disampaikan ke pasien terlebih dahulu. Aku merasa bingung antara menghormati otonomi pasien atau keinginan keluarga.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = scenarios[index];
          return ActionChip(
            label: Text(
              item['label']!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F766E),
              ),
            ),
            backgroundColor: const Color(0xFFF0FDFA),
            side: const BorderSide(color: Color(0xFF99F6E4), width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => onSelectScenario(item['prompt']!),
          );
        },
      ),
    );
  }
}
