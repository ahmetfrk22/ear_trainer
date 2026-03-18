import 'package:flutter/material.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/audio/microphone_service.dart';
import '../../core/audio/pitch_analyzer.dart';
import '../../core/models/note_model.dart';
import '../../core/widgets/piano_keyboard.dart';

enum NoteExerciseMode { listen, guess }

class SingleNoteScreen extends StatefulWidget {
  const SingleNoteScreen({super.key});

  @override
  State<SingleNoteScreen> createState() => _SingleNoteScreenState();
}

class _SingleNoteScreenState extends State<SingleNoteScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final MicrophoneService _microphone = MicrophoneService();
  final PitchAnalyzer _analyzer = PitchAnalyzer();

  NoteExerciseMode _mode = NoteExerciseMode.listen;
  NoteModel? _targetNote;
  double? _detectedFreq;
  String? _highlightedKey;
  bool _isListening = false;
  bool _answered = false;
  bool _noteVisible = false;
  String _resultText = 'Nota seç ve başla';
  Color _resultColor = const Color(0xFF7C6F9E);
  int _correctCount = 0;
  int _score = 0;
  static const int _requiredCorrectCount = 8;

  void _pickRandomNote() {
    final octave4Notes = allNotes.where((n) => n.name.endsWith('4')).toList();
    octave4Notes.shuffle();
    setState(() {
      _targetNote = octave4Notes.first;
      _highlightedKey = null;
      _detectedFreq = null;
      _answered = false;
      _noteVisible = false;
      _correctCount = 0;
      _resultText = 'Hazır! Çal butonuna bas';
      _resultColor = const Color(0xFF7C6F9E);
    });
  }

  Future<void> _playNote() async {
    if (_targetNote == null) return;
    await _audioPlayer.playNote(_targetNote!);
  }

  void _toggleNoteVisibility() {
    setState(() => _noteVisible = !_noteVisible);
  }

  // --- Dinle & Söyle modu ---
  Future<void> _startListening() async {
    if (_targetNote == null) {
      setState(() => _resultText = 'Önce nota seç!');
      return;
    }
    setState(() {
      _isListening = true;
      _correctCount = 0;
      _resultText = 'Dinleniyor... Notayı söyle!';
      _resultColor = const Color(0xFF7C6F9E);
    });

    await _microphone.startListening();
    _microphone.pitchStream.listen((double? freq) async {
      if (freq == null || freq < 60 || freq > 2000) return;

      final corrected = _analyzer.correctOctave(freq, _targetNote!.frequency);
      final detectedName = _analyzer.getNoteNameFromFrequency(corrected);
      final cents = _analyzer.centDifference(corrected, _targetNote!.frequency);
      final correct = _analyzer.isCorrect(freq, _targetNote!);

      if (correct) {
        _correctCount++;
      } else {
        _correctCount = 0;
      }

      setState(() {
        _detectedFreq = corrected;
        _highlightedKey = detectedName;
        _resultText = correct
            ? '✓ Doğru! $detectedName (${cents.toStringAsFixed(0)} cent)'
            : '✗ Yanlış — $detectedName söyledin';
        _resultColor = correct
            ? const Color(0xFF6EE7B7)
            : const Color(0xFFFDA4AF);
      });

      if (_correctCount >= _requiredCorrectCount) {
        _correctCount = 0;
        await _stopListening();
        setState(() {
          _score++;
          _answered = true;
          _resultText = '🎉 Tebrikler! ${_targetNote!.name} doğru!';
          _resultColor = const Color(0xFF6EE7B7);
        });
      }
    });
  }

  Future<void> _stopListening() async {
    await _microphone.stopListening();
    setState(() => _isListening = false);
  }

  // --- Dinle & Tahmin Et modu ---
  void _onKeyTap(NoteModel tappedNote) {
    if (_targetNote == null || _answered) return;

    final correct = tappedNote.name == _targetNote!.name;
    setState(() {
      _answered = true;
      _highlightedKey = tappedNote.name;
      _noteVisible = true;
      if (correct) {
        _score++;
        _resultText = '🎉 Doğru! ${tappedNote.name}';
        _resultColor = const Color(0xFF6EE7B7);
      } else {
        _resultText = '✗ Yanlış! Doğrusu: ${_targetNote!.name}';
        _resultColor = const Color(0xFFFDA4AF);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _highlightedKey = _targetNote!.name);
        });
      }
    });
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
        title: const Text(
          'Tek Ses Tanıma',
          style: TextStyle(
            fontFamily: 'Playfair',
            color: Color(0xFFEDE9FE),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFEDE9FE)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Skor: $_score',
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mod seçimi
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ModeButton(
                    label: 'Dinle & Söyle',
                    icon: Icons.mic_rounded,
                    selected: _mode == NoteExerciseMode.listen,
                    onTap: () {
                      if (_isListening) _stopListening();
                      setState(() {
                        _mode = NoteExerciseMode.listen;
                        _answered = false;
                        _highlightedKey = null;
                        _noteVisible = true;
                        _resultText = 'Nota seç ve başla';
                        _resultColor = const Color(0xFF7C6F9E);
                      });
                    },
                  ),
                  _ModeButton(
                    label: 'Tahmin Et',
                    icon: Icons.piano_rounded,
                    selected: _mode == NoteExerciseMode.guess,
                    onTap: () {
                      if (_isListening) _stopListening();
                      setState(() {
                        _mode = NoteExerciseMode.guess;
                        _answered = false;
                        _highlightedKey = null;
                        _noteVisible = false;
                        _resultText = 'Nota seç ve başla';
                        _resultColor = const Color(0xFF7C6F9E);
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Hedef nota kutusu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Hedef Nota',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7C6F9E),
                        ),
                      ),
                      if (_mode == NoteExerciseMode.guess &&
                          _targetNote != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _toggleNoteVisibility,
                          child: Icon(
                            _noteVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                            color: const Color(0xFF7C6F9E),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tahmin modunda nota gizlenebilir
                  if (_mode == NoteExerciseMode.listen || _noteVisible)
                    Text(
                      _targetNote != null
                          ? '${_targetNote!.name}  —  ${_targetNote!.solfege}'
                          : '—',
                      style: const TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEDE9FE),
                      ),
                    )
                  else
                    const Text(
                      '? ? ?',
                      style: TextStyle(
                        fontFamily: 'Playfair',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A4560),
                      ),
                    ),
                  if (_targetNote != null &&
                      (_mode == NoteExerciseMode.listen || _noteVisible)) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_targetNote!.frequency.toStringAsFixed(2)} Hz',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C6F9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sonuç metni
            Text(
              _resultText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _resultColor,
              ),
              textAlign: TextAlign.center,
            ),

            if (_mode == NoteExerciseMode.listen && _detectedFreq != null) ...[
              const SizedBox(height: 6),
              Text(
                'Tespit: ${_analyzer.getNoteNameFromFrequency(_detectedFreq!)}  •  ${_detectedFreq!.toStringAsFixed(1)} Hz',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C6F9E),
                ),
              ),
            ],

            const Spacer(),

            // Piyano
            PianoKeyboard(
              highlightedNote: _highlightedKey,
              onKeyTap: _mode == NoteExerciseMode.guess ? _onKeyTap : null,
            ),

            const SizedBox(height: 20),

            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: 'Nota Seç',
                  icon: Icons.shuffle_rounded,
                  color: const Color(0xFF2E2A45),
                  textColor: const Color(0xFFC4B5FD),
                  onTap: _pickRandomNote,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: 'Çal',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF2E2A45),
                  textColor: const Color(0xFFC4B5FD),
                  onTap: _targetNote != null ? _playNote : null,
                ),
                if (_mode == NoteExerciseMode.listen) ...[
                  const SizedBox(width: 12),
                  _ActionButton(
                    label: _isListening ? 'Durdur' : 'Dinle',
                    icon: _isListening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: _isListening
                        ? const Color(0xFF3D1A2E)
                        : const Color(0xFF1A2E3D),
                    textColor: _isListening
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFF6EE7B7),
                    onTap: _isListening ? _stopListening : _startListening,
                  ),
                ],
                if (_mode == NoteExerciseMode.guess && _answered) ...[
                  const SizedBox(width: 12),
                  _ActionButton(
                    label: 'Sonraki',
                    icon: Icons.arrow_forward_rounded,
                    color: const Color(0xFF1A2E3D),
                    textColor: const Color(0xFF6EE7B7),
                    onTap: _pickRandomNote,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFA78BFA)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF7C6F9E),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}