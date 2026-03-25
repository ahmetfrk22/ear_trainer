import 'package:flutter/material.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/audio/microphone_service.dart';
import '../../core/audio/pitch_analyzer.dart';
import '../../core/models/note_model.dart';
import '../../core/widgets/piano_keyboard.dart';

enum NoteExerciseMode { guess, vocal }

class SingleNoteScreen extends StatefulWidget {
  const SingleNoteScreen({super.key});

  @override
  State<SingleNoteScreen> createState() => _SingleNoteScreenState();
}

class _SingleNoteScreenState extends State<SingleNoteScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final MicrophoneService _microphone = MicrophoneService();
  final PitchAnalyzer _analyzer = PitchAnalyzer();

  NoteExerciseMode _mode = NoteExerciseMode.guess;
  NoteModel? _targetNote;
  double? _detectedFreq;
  String? _highlightedKey;

  bool _isListening = false;
  bool _answered = false;

  String _feedbackText = 'Başlamak için yeni soru iste';
  Color _feedbackColor = const Color(0xFF7C6F9E);

  int _correctCount = 0;
  int _score = 0;
  static const int _requiredCorrectCount = 8;

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz ilk soruyu hazırla
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    final octave4Notes = allNotes.where((n) => n.name.endsWith('4')).toList();
    octave4Notes.shuffle();

    setState(() {
      _targetNote = octave4Notes.first;
      _highlightedKey = null;
      _detectedFreq = null;
      _answered = false;
      _correctCount = 0;

      if (_mode == NoteExerciseMode.guess) {
        _feedbackText = 'Sesi duy ve piyanoda bulmaya çalış';
      } else {
        _feedbackText = 'Referansı dinle, sonra mikrofonu aç';
      }
      _feedbackColor = const Color(0xFF7C6F9E);
    });
  }

  Future<void> _playTargetNote() async {
    if (_targetNote == null) return;
    await _audioPlayer.playNote(_targetNote!);
  }

  // --- Mod 1: Duyduğunu Çal (Guess) ---
  void _onKeyTap(NoteModel tappedNote) {
    if (_targetNote == null || _answered) return;

    final correct = tappedNote.name == _targetNote!.name;

    setState(() {
      _highlightedKey = tappedNote.name;

      if (correct) {
        _score++;
        _answered = true;
        _feedbackText = '🎉 Harika! Doğru ses: ${tappedNote.name}';
        _feedbackColor = const Color(0xFF6EE7B7);
      } else {
        _feedbackText = '✗ Yanlış ses, tekrar dene';
        _feedbackColor = const Color(0xFFFDA4AF);
      }
    });
  }

  // --- Mod 2: Sesi Eşleştir (Vocal) ---
  Future<void> _startListening() async {
    if (_targetNote == null) return;

    setState(() {
      _isListening = true;
      _correctCount = 0;
      _feedbackText = 'Dinleniyor... Sesi ver!';
      _feedbackColor = const Color(0xFF7C6F9E);
    });

    await _microphone.startListening();

    _microphone.pitchStream.listen((double? freq) async {
      if (freq == null || freq < 60 || freq > 2000) return;

      final corrected = _analyzer.correctOctave(freq, _targetNote!.frequency);
      final detectedName = _analyzer.getNoteNameFromFrequency(corrected);

      // İşaretli cent farkı (pozitifse tiz, negatifse pes)
      final rawCents = _analyzer.centDifference(corrected, _targetNote!.frequency);
      final correct = _analyzer.isCorrect(freq, _targetNote!);

      if (correct) {
        _correctCount++;
      } else {
        _correctCount = 0;
      }

      setState(() {
        _detectedFreq = corrected;
        _highlightedKey = detectedName;

        if (correct) {
          _feedbackText = '✓ Kusursuz! Tutmaya devam et...';
          _feedbackColor = const Color(0xFF6EE7B7);
        } else {
          if (rawCents > 0) {
            _feedbackText = 'Biraz fazla tiz, pesleştir ⬇️ ($detectedName)';
            _feedbackColor = const Color(0xFFFBBF24); // Sarımsı uyarı rengi
          } else {
            _feedbackText = 'Biraz fazla pes, tizleştir ⬆️ ($detectedName)';
            _feedbackColor = const Color(0xFFFBBF24);
          }
        }
      });

      if (_correctCount >= _requiredCorrectCount) {
        _correctCount = 0;
        await _stopListening();
        setState(() {
          _score++;
          _answered = true;
          _feedbackText = '🎉 Eşleşme Başarılı! Hedef: ${_targetNote!.name}';
          _feedbackColor = const Color(0xFF6EE7B7);
        });
      }
    });
  }

  Future<void> _stopListening() async {
    await _microphone.stopListening();
    setState(() => _isListening = false);
  }

  void _switchMode(NoteExerciseMode newMode) {
    if (_mode == newMode) return;
    if (_isListening) _stopListening();

    setState(() {
      _mode = newMode;
    });
    _generateNewQuestion();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _microphone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13111C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A2E),
        elevation: 0,
        title: const Text(
          'Tek Ses Tanıma',
          style: TextStyle(
            fontFamily: 'Playfair',
            color: Color(0xFFEDE9FE),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFEDE9FE)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2440),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Skor: $_score',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Üst Kısım: Mod Seçici
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModeButton(
                      label: 'Duyduğunu Çal',
                      icon: Icons.piano_rounded,
                      selected: _mode == NoteExerciseMode.guess,
                      onTap: () => _switchMode(NoteExerciseMode.guess),
                    ),
                    _ModeButton(
                      label: 'Sesi Eşleştir',
                      icon: Icons.mic_rounded,
                      selected: _mode == NoteExerciseMode.vocal,
                      onTap: () => _switchMode(NoteExerciseMode.vocal),
                    ),
                  ],
                ),
              ),
            ),

            // Orta Kısım: Soru ve Geribildirim
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ana Soru Göstergesi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _answered ? _feedbackColor.withOpacity(0.5) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _mode == NoteExerciseMode.guess ? 'Gizli Nota' : 'Hedef Nota',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7C6F9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_mode == NoteExerciseMode.guess && !_answered)
                                ? '?'
                                : '${_targetNote?.name}',
                            style: TextStyle(
                              fontFamily: 'Playfair',
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: (_mode == NoteExerciseMode.guess && !_answered)
                                  ? const Color(0xFF4A4560)
                                  : const Color(0xFFEDE9FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Geri Bildirim Metni
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _feedbackColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _feedbackText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _feedbackColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Frekans Detayı (Sadece Mikrofon modunda ve dinlerken)
                    if (_mode == NoteExerciseMode.vocal && _isListening && _detectedFreq != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Anlık: ${_detectedFreq!.toStringAsFixed(1)} Hz',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C6F9E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Aksiyon Butonları (Moda göre değişir)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_mode == NoteExerciseMode.guess) ...[
                    // Duyduğunu Çal Modu Butonları
                    _ActionButton(
                      label: 'Sesi Duy',
                      icon: Icons.volume_up_rounded,
                      color: const Color(0xFF2A2440),
                      textColor: const Color(0xFFA78BFA),
                      onTap: _playTargetNote,
                    ),
                    if (_answered) ...[
                      const SizedBox(width: 16),
                      _ActionButton(
                        label: 'Yeni Soru',
                        icon: Icons.arrow_forward_rounded,
                        color: const Color(0xFFA78BFA),
                        textColor: const Color(0xFF13111C),
                        onTap: _generateNewQuestion,
                      ),
                    ]
                  ] else ...[
                    // Sesi Eşleştir Modu Butonları
                    _ActionButton(
                      label: 'Referansı Duy',
                      icon: Icons.volume_up_rounded,
                      color: const Color(0xFF2A2440),
                      textColor: const Color(0xFFA78BFA),
                      onTap: _playTargetNote,
                    ),
                    const SizedBox(width: 16),
                    if (!_answered)
                      _ActionButton(
                        label: _isListening ? 'Kapat' : 'Mikrofonu Aç',
                        icon: _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isListening ? const Color(0xFFFDA4AF).withOpacity(0.2) : const Color(0xFF6EE7B7).withOpacity(0.2),
                        textColor: _isListening ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                        onTap: _isListening ? _stopListening : _startListening,
                      )
                    else
                      _ActionButton(
                        label: 'Yeni Soru',
                        icon: Icons.arrow_forward_rounded,
                        color: const Color(0xFFA78BFA),
                        textColor: const Color(0xFF13111C),
                        onTap: _generateNewQuestion,
                      ),
                  ],
                ],
              ),
            ),

            // Alt Kısım: Piyano Klavyesi
            PianoKeyboard(
              highlightedNote: _highlightedKey,
              onKeyTap: _mode == NoteExerciseMode.guess ? _onKeyTap : null,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Yardımcı Widget'lar ---

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFA78BFA) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF7C6F9E),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF7C6F9E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}