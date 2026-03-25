import 'package:flutter/material.dart';
import 'package:muzik_kulagi/core/audio/audio_player_service.dart';
import 'package:muzik_kulagi/core/audio/microphone_service.dart';
import 'package:muzik_kulagi/core/audio/pitch_analyzer.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';
import 'package:muzik_kulagi/core/widgets/piano_keyboard.dart';

enum MatchLevel { single, double, triple }

class PitchMatchingScreen extends StatefulWidget {
  const PitchMatchingScreen({super.key});

  @override
  State<PitchMatchingScreen> createState() => _PitchMatchingScreenState();
}

class _PitchMatchingScreenState extends State<PitchMatchingScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final MicrophoneService _microphone = MicrophoneService();
  final PitchAnalyzer _analyzer = PitchAnalyzer();

  MatchLevel _level = MatchLevel.single;
  List<NoteModel> _targetNotes = [];
  int _currentNoteIndex = 0;
  bool _isListening = false;
  bool _answered = false;
  String _feedbackText = 'Hazırsan başla';
  Color _feedbackColor = const Color(0xFF7C6F9E);
  int _correctCount = 0;
  static const int _requiredCorrectCount = 6;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    final octave4Notes = allNotes.where((n) => n.name.endsWith('4')).toList();
    octave4Notes.shuffle();
    final root = octave4Notes.first;
    List<NoteModel> newNotes = [root];
    final rootIndex = allNotes.indexOf(root);

    if (_level == MatchLevel.double) {
      final intervals = [3, 4, 5, 7];
      intervals.shuffle();
      newNotes.add(allNotes[rootIndex + intervals.first]);
    } else if (_level == MatchLevel.triple) {
      newNotes.add(allNotes[rootIndex + 4]);
      newNotes.add(allNotes[rootIndex + 7]);
    }

    setState(() {
      _targetNotes = newNotes;
      _currentNoteIndex = 0;
      _answered = false;
      _correctCount = 0;
      _feedbackText = _level == MatchLevel.single ? 'Sesi eşleştir' : 'Armonik duy, melodik söyle';
      _feedbackColor = const Color(0xFF7C6F9E);
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
        title: const Text('Ses Verme', style: TextStyle(fontFamily: 'Playfair')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<MatchLevel>(
              segments: const [
                ButtonSegment(value: MatchLevel.single, label: Text('Tek')),
                ButtonSegment(value: MatchLevel.double, label: Text('Çift')),
                ButtonSegment(value: MatchLevel.triple, label: Text('Üç')),
              ],
              selected: {_level},
              onSelectionChanged: (val) {
                setState(() => _level = val.first);
                _generateNewQuestion();
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFFA78BFA),
                backgroundColor: const Color(0xFF1E1A2E),
                foregroundColor: const Color(0xFF7C6F9E),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_targetNotes.length, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 65, height: 85,
                decoration: BoxDecoration(
                  color: i < _currentNoteIndex ? const Color(0xFF6EE7B7).withOpacity(0.1) : const Color(0xFF1E1A2E),
                  border: Border.all(color: i == _currentNoteIndex && _isListening ? const Color(0xFFA78BFA) : (i < _currentNoteIndex ? const Color(0xFF6EE7B7) : const Color(0xFF2A2440)), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(_answered || i < _currentNoteIndex ? _targetNotes[i].name : '?', style: const TextStyle(fontFamily: 'Playfair', fontSize: 20, color: Colors.white))),
              )),
            ),
          ),
          Text(_feedbackText, style: TextStyle(color: _feedbackColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: [
                _Btn(label: _level == MatchLevel.single ? 'Duy' : 'Armonik', icon: Icons.volume_up, onTap: () => _audioPlayer.playNotesHarmonic(_targetNotes)),
                if (_level != MatchLevel.single) _Btn(label: 'Melodik', icon: Icons.read_more, onTap: () => _audioPlayer.playNotesMelodic(_targetNotes)),
                _Btn(label: _isListening ? 'Kapat' : 'Mikrofon', icon: _isListening ? Icons.mic_off : Icons.mic, isAction: true, onTap: _isListening ? () => setState(() => _isListening = false) : _startListening),
                if (_answered) _Btn(label: 'Sonraki', icon: Icons.arrow_forward, isAction: true, onTap: _generateNewQuestion),
              ],
            ),
          ),
          const PianoKeyboard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    setState(() { _isListening = true; _correctCount = 0; });
    await _microphone.startListening();
    _microphone.pitchStream.listen((freq) async {
      if (!mounted || !_isListening || freq == null || freq < 60) return;
      final target = _targetNotes[_currentNoteIndex];
      final corrected = _analyzer.correctOctave(freq, target.frequency);
      if (_analyzer.isCorrect(corrected, target)) {
        _correctCount++;
        if (_correctCount >= _requiredCorrectCount) {
          _correctCount = 0;
          if (_currentNoteIndex < _targetNotes.length - 1) {
            setState(() { _currentNoteIndex++; });
          } else {
            await _microphone.stopListening();
            setState(() { _isListening = false; _answered = true; _feedbackText = '🎉 Başarılı!'; _feedbackColor = const Color(0xFF6EE7B7); });
          }
        }
      } else { _correctCount = 0; }
    });
  }
}

class _Btn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool isAction;
  const _Btn({required this.label, required this.icon, required this.onTap, this.isAction = false});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: isAction ? const Color(0xFFA78BFA) : const Color(0xFF2A2440), foregroundColor: isAction ? Colors.black : const Color(0xFFA78BFA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}