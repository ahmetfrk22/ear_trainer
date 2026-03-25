import 'package:flutter/material.dart';
// NOT: Proje adın 'muzik_kulagi' değilse, aşağıdaki yolları pubspec.yaml'daki 'name' ile değiştir.
import 'package:muzik_kulagi/features/pitch_matching/pitch_matching_screen.dart';
import 'package:muzik_kulagi/features/interval/interval_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13111C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Ana Başlık
              const Text(
                'Müzik\nKulağı',
                style: TextStyle(
                  fontFamily: 'Playfair',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEDE9FE),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kulağını her gün biraz daha geliştir.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C6F9E),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              // Altın Vurgu Çizgisi
              Container(
                width: 48,
                height: 1.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFA78BFA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 40),

              // Modül Listesi
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. MODÜL: SES VERME (Vokal Eşleştirme)
                    _ModuleCard(
                      icon: Icons.mic_rounded,
                      title: 'Ses Verme',
                      subtitle: '1, 2 veya 3 sesi vokal olarak eşleştir',
                      accentColor: const Color(0xFFA78BFA),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PitchMatchingScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. MODÜL: ARALIK TANIMA (Teorik/İşitsel Test)
                    _ModuleCard(
                      icon: Icons.piano_rounded,
                      title: 'Aralık Tanıma',
                      subtitle: 'İki nota arasındaki mesafeyi bul',
                      accentColor: const Color(0xFF6EE7B7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const IntervalScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. MODÜL: SOLFEJ (Gelecek Özellik)
                    _ModuleCard(
                      icon: Icons.library_music_rounded,
                      title: 'Solfej',
                      subtitle: 'Nota kağıdından solfej oku',
                      accentColor: const Color(0xFF93C5FD),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Solfej modülü yakında eklenecek!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4. MODÜL: İLERLEME (İstatistikler)
                    _ModuleCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'İlerleme',
                      subtitle: 'İstatistiklerini ve rekorlarını gör',
                      accentColor: const Color(0xFFC4B5FD),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Alt Bilgi: Streak Göstergesi
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFA78BFA),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Günlük seri: 0 gün',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF7C6F9E).withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1A2E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accentColor.withOpacity(0.08),
        highlightColor: accentColor.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // İkon Kutusu
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 16),
              // Metin Alanı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEDE9FE),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C6F9E),
                      ),
                    ),
                  ],
                ),
              ),
              // Sağ Ok Simgesi
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}