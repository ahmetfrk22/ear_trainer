import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:muzik_kulagi/core/audio/audio_player_service.dart';
import 'package:muzik_kulagi/core/audio/microphone_service.dart';
import 'package:muzik_kulagi/core/audio/pitch_analyzer.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';
import 'package:muzik_kulagi/core/utils/color_utils.dart';

enum NoteDuration { half, quarter, eighth }

class SolfegeExerciseNote {
  final NoteModel note;
  final NoteDuration duration;
  final List<NoteModel> accompanimentChords;
  bool? isCorrect;

  SolfegeExerciseNote({
    required this.note,
    required this.duration,
    required this.accompanimentChords,
    this.isCorrect,
  });
}

class SolfegeScreen extends StatefulWidget {
  const SolfegeScreen({super.key});

  @override
  State<SolfegeScreen> createState() => _SolfegeScreenState();
}

class _SolfegeScreenState extends State<SolfegeScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final MicrophoneService _microphone = MicrophoneService();
  final PitchAnalyzer _analyzer = PitchAnalyzer();
  final Random _rng = Random();

  List<SolfegeExerciseNote> _exerciseNotes = [];
  int _currentIndex = -1;
  int _prepBeat = -1; // -1: hazır değil, 0-3: hazırlık vuruşları
  bool _isPlaying = false;
  bool _isListening = false;
  bool _showAccompaniment = true;

  StreamSubscription<double?>? _pitchSubscription;

  @override
  void initState() {
    super.initState();
    _generateNewExercise();
  }

  void _generateNewExercise() {
    // Akademik C Majör Dizisi (C4 - C5)
    final List<String> scaleNames = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
    final List<NoteModel> cMajorScale = [];
    for (var name in scaleNames) {
      try {
        cMajorScale.add(allNotes.firstWhere((n) => n.name == name));
      } catch (e) {}
    }

    List<SolfegeExerciseNote> newNotes = [];
    for (int i = 0; i < 8; i++) {
      final note = cMajorScale[_rng.nextInt(cMajorScale.length)];
      
      // Ritmik çeşitlilik: %70 dörtlük, %15 ikilik, %15 sekizlik
      final r = _rng.nextDouble();
      final duration = r < 0.7 ? NoteDuration.quarter : (r < 0.85 ? NoteDuration.half : NoteDuration.eighth);

      // Harmonizasyon (Sol El)
      List<NoteModel> chords = [];
      final name = note.name.replaceAll(RegExp(r'[0-9]'), '');
      if (['C', 'E', 'G'].contains(name)) {
        chords = allNotes.where((n) => ['C3', 'E3', 'G3'].contains(n.name)).toList();
      } else if (['D', 'F', 'A'].contains(name)) {
        chords = allNotes.where((n) => ['D3', 'F3', 'A3'].contains(n.name)).toList();
      } else { // B veya G
        chords = allNotes.where((n) => ['G2', 'B2', 'D3'].contains(n.name)).toList();
      }

      newNotes.add(SolfegeExerciseNote(
        note: note,
        duration: duration,
        accompanimentChords: chords,
      ));
    }

    setState(() {
      _exerciseNotes = newNotes;
      _currentIndex = -1;
      _prepBeat = -1;
      _isPlaying = false;
    });
  }

  Future<void> _startExercise() async {
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
      _currentIndex = -1;
    });

    // 1. HAZIRLIK VURUŞLARI (4 Vuruş)
    for (int i = 0; i < 4; i++) {
      if (!mounted || !_isPlaying) break;
      setState(() => _prepBeat = i);
      _audioPlayer.playMetronomeClick(isAccent: i == 0);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    setState(() => _prepBeat = -1);

    // 2. SOLFEJ AKIŞI
    for (int i = 0; i < _exerciseNotes.length; i++) {
      if (!mounted || !_isPlaying) break;
      
      setState(() => _currentIndex = i);
      final current = _exerciseNotes[i];
      
      _audioPlayer.playNote(current.note);
      if (_showAccompaniment) {
        _audioPlayer.playNotesHarmonic(current.accompanimentChords);
      }

      int ms = 1000;
      if (current.duration == NoteDuration.half) ms = 2000;
      if (current.duration == NoteDuration.eighth) ms = 500;
      
      await Future.delayed(Duration(milliseconds: ms));
    }

    setState(() {
      _isPlaying = false;
      _currentIndex = -1;
    });
  }

  @override
  void dispose() {
    _pitchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Solfej Çalışması', style: TextStyle(fontFamily: 'Playfair', color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showAccompaniment ? Icons.layers : Icons.layers_clear, color: const Color(0xFFA78BFA)),
            onPressed: () => setState(() => _showAccompaniment = !_showAccompaniment),
            tooltip: 'Eşlik (Akor) Aç/Kapat',
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Nota Portesi (Basit Görünüm)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: CustomPaint(
              painter: PortePainter(
                notes: _exerciseNotes,
                currentIndex: _currentIndex,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _currentIndex == -1 
                ? (_prepBeat == -1 ? 'Hazırsan başla!' : 'Hazırlan: ${_prepBeat + 1}') 
                : 'Dinle ve Takip Et...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _prepBeat != -1 ? const Color(0xFF6EE7B7) : Colors.white70, 
                fontSize: 18, 
                fontWeight: _prepBeat != -1 ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(
                  label: 'Yeni Parça',
                  icon: Icons.refresh,
                  onTap: _isPlaying ? null : _generateNewExercise,
                ),
                GestureDetector(
                  onTap: _isPlaying ? () => setState(() => _isPlaying = false) : _startExercise,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFA78BFA),
                    ),
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.black),
                  ),
                ),
                _ActionBtn(
                  label: 'Kök Ses',
                  icon: Icons.music_note,
                  onTap: _isPlaying ? null : () => _audioPlayer.playNote(allNotes.firstWhere((n) => n.name == 'C4')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class PortePainter extends CustomPainter {
  final List<SolfegeExerciseNote> notes;
  final int currentIndex;

  PortePainter({required this.notes, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;

    // Porte Çizgileri (5 adet)
    // Standart porte için lineSpacing sabittir.
    const double lineSpacing = 12.0;
    // Sol anahtarı merkez çizgisi G4 (2. çizgi aşağıdan)
    // Portenin dikey merkezini 3. çizgi (B4) yapalım.
    double centerY = size.height / 2;
    double startY = centerY - (lineSpacing * 2);

    for (int i = 0; i < 5; i++) {
      double y = startY + (i * lineSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    if (notes.isEmpty) return;

    double noteXSpacing = size.width / (notes.length + 1);

    for (int i = 0; i < notes.length; i++) {
      final isCurrent = i == currentIndex;
      final noteColor = isCurrent ? const Color(0xFFA78BFA) : Colors.white70;
      final notePaint = Paint()
        ..color = noteColor
        ..style = PaintingStyle.fill;

      double x = noteXSpacing * (i + 1);
      
      // Y-Ekseni Hesaplaması (Müzik Teorisi):
      // B4 (Si) tam orta çizgi (index 2)
      // A4 (La) 2. aralık
      // G4 (Sol) 2. çizgi
      // F4 (Fa) 1. aralık
      // E4 (Mi) 1. çizgi
      // D4 (Re) 1. çizgi altı
      // C4 (Do) Ek çizgi (porte altı)
      double yOffset = _getNoteYOffset(notes[i].note.name, centerY, lineSpacing);
      
      // C4 için ek çizgi (Leger line)
      if (notes[i].note.name == 'C4') {
        canvas.drawLine(
          Offset(x - 12, yOffset),
          Offset(x + 12, yOffset),
          paint..color = noteColor.withOpacity(0.5)..strokeWidth = 1,
        );
      }

      // Nota Kafası
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, yOffset), width: 13, height: 10),
        notePaint,
      );

      // Nota Sapı (B4 ve üstü aşağı, altı yukarı)
      bool stemUp = _isStemUp(notes[i].note.name);
      double stemLength = 35.0;
      double stemX = stemUp ? x + 6.0 : x - 6.0;
      double stemTopY = stemUp ? yOffset - stemLength : yOffset + stemLength;
      
      canvas.drawLine(
        Offset(stemX, yOffset),
        Offset(stemX, stemTopY),
        notePaint..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );

      // Sekizlik Çengeli (Flag)
      if (notes[i].duration == NoteDuration.eighth) {
        double flagX = stemX;
        double flagY = stemTopY;
        canvas.drawLine(
          Offset(flagX, flagY),
          Offset(flagX + (stemUp ? 8 : 8), flagY + (stemUp ? 10 : -10)),
          notePaint..style = PaintingStyle.stroke..strokeWidth = 1.5,
        );
      }

      // Solfej İsmi
      final textPainter = TextPainter(
        text: TextSpan(
          text: notes[i].note.solfege,
          style: TextStyle(color: isCurrent ? const Color(0xFF6EE7B7) : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), startY + (lineSpacing * 5.5)));
    }
  }

  double _getNoteYOffset(String name, double centerY, double lineSpacing) {
    // B4 merkez (0) kabul edilirse adım farkları:
    final Map<String, int> stepsFromB4 = {
      'C5': -1, 'B4': 0, 'A4': 1, 'G4': 2, 'F4': 3, 'E4': 4, 'D4': 5, 'C4': 6
    };
    int steps = stepsFromB4[name] ?? 0;
    // Her adım yarım lineSpacing (bir çizgi veya bir aralık)
    return centerY + (steps * (lineSpacing / 2));
  }

  bool _isStemUp(String name) {
    // B4 (Si) ve üstü notaların sapı aşağı bakar, altındakiler yukarı
    final List<String> downStems = ['B4', 'C5'];
    return !downStems.contains(name);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionBtn({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: onTap == null ? Colors.white24 : const Color(0xFFA78BFA)),
          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: onTap == null ? Colors.white24 : Colors.white70, fontSize: 12)),
      ],
    );
  }
}
