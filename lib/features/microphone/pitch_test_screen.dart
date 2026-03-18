import 'package:flutter/material.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/audio/microphone_service.dart';
import '../../core/audio/pitch_analyzer.dart';
import '../../core/models/note_model.dart';

class PitchTestScreen extends StatefulWidget {
  const PitchTestScreen({super.key});

  @override
  State<PitchTestScreen> createState() => _PitchTestScreenState();
}

class _PitchTestScreenState extends State<PitchTestScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final MicrophoneService _microphone = MicrophoneService();
  final PitchAnalyzer _analyzer = PitchAnalyzer();

  NoteModel? _targetNote;
  double? _detectedFreq;
  NoteModel? _detectedNote;
  double? _centDiff;
  bool _isListening = false;
  String _resultText = 'Bir nota seç ve çal butonuna bas';
  int _correctCount = 0;
  static const int _requiredCorrectCount = 8;

  void _pickRandomNote() {
    final octave4Notes = allNotes.where((n) => n.name.endsWith('4')).toList();
    octave4Notes.shuffle();
    setState(() {
      _targetNote = octave4Notes.first;
      _resultText = 'Hazır! Çal butonuna bas';
      _detectedFreq = null;
      _detectedNote = null;
      _centDiff = null;
      _correctCount = 0;
    });
  }

  Future<void> _playTargetNote() async {
    if (_targetNote == null) return;
    await _audioPlayer.playNote(_targetNote!);
  }

  Future<void> _startListening() async {
    if (_targetNote == null) {
      setState(() => _resultText = 'Önce nota seç!');
      return;
    }
    setState(() {
      _isListening = true;
      _resultText = 'Dinleniyor... Notayı söyle!';
      _correctCount = 0;
    });
    await _microphone.startListening();
    _microphone.pitchStream.listen((double? freq) async {
      if (freq == null || freq < 60 || freq > 2000) return;

      final correctedFreq = _analyzer.correctOctave(freq, _targetNote!.frequency);
      final note = _analyzer.findClosestNote(correctedFreq);
      final detectedName = _analyzer.getNoteNameFromFrequency(correctedFreq);
      final cents = _analyzer.centDifference(correctedFreq, _targetNote!.frequency);
      final correct = _analyzer.isCorrect(freq, _targetNote!);

      if (correct) {
        _correctCount++;
      } else {
        _correctCount = 0;
      }

      setState(() {
        _detectedFreq = correctedFreq;
        _detectedNote = note;
        _centDiff = cents;
        _resultText = correct
            ? '✓ Doğru! $detectedName (${cents.toStringAsFixed(0)} cent)'
            : '✗ Yanlış! $detectedName söyledin, hedef ${_targetNote!.name}';
      });

      if (_correctCount >= _requiredCorrectCount) {
        _correctCount = 0;
        await _stopListening();
        setState(() => _resultText = '🎉 Tebrikler! ${_targetNote!.name} doğru!');
      }
    });
  }

  Future<void> _stopListening() async {
    await _microphone.stopListening();
    setState(() {
      _isListening = false;
      _resultText = _resultText.contains('✓') ||
          _resultText.contains('✗') ||
          _resultText.contains('🎉')
          ? _resultText
          : 'Durduruldu';
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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Pitch Test',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Hedef Nota',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _targetNote != null
                        ? '${_targetNote!.name} — ${_targetNote!.solfege}'
                        : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _targetNote != null
                        ? '${_targetNote!.frequency.toStringAsFixed(2)} Hz'
                        : '',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_detectedFreq != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tespit Edilen',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _detectedNote != null
                          ? '${_detectedNote!.name} — ${_detectedNote!.solfege}'
                          : _analyzer.getNoteNameFromFrequency(_detectedFreq!),
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_detectedFreq!.toStringAsFixed(1)} Hz  |  '
                          '${_centDiff != null ? _centDiff!.toStringAsFixed(0) : "?"} cent',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              _resultText,
              style: TextStyle(
                color: _resultText.contains('✓') || _resultText.contains('🎉')
                    ? Colors.greenAccent
                    : _resultText.contains('✗')
                    ? Colors.redAccent
                    : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickRandomNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF533483),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Nota Seç',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _targetNote != null ? _playTargetNote : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Çal',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : Colors.greenAccent.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isListening ? 'Durdur' : 'Dinle',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}