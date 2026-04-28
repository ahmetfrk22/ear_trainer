import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muzik_kulagi/core/audio/audio_player_service.dart';
import 'package:muzik_kulagi/core/audio/microphone_service.dart';
import 'package:muzik_kulagi/core/audio/pitch_analyzer.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';
import 'package:muzik_kulagi/core/widgets/piano_keyboard.dart';
import 'package:muzik_kulagi/core/utils/color_utils.dart';
import 'package:muzik_kulagi/core/widgets/piano_dock.dart';

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
  bool _isPlaying = false;
  StreamSubscription<double?>? _pitchSubscription;

  String _feedbackText = 'Hazırsan başla';
  Color _feedbackColor = const Color(0xFF7C6F9E);
  int _correctCount = 0;

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
      if (rootIndex + intervals.first < allNotes.length) {
        newNotes.add(allNotes[rootIndex + intervals.first]);
      }
    } else if (_level == MatchLevel.triple) {
      if (rootIndex + 7 < allNotes.length) {
        newNotes.add(allNotes[rootIndex + 4]);
        newNotes.add(allNotes[rootIndex + 7]);
      }
    }

    setState(() {
      _targetNotes = newNotes;
      _currentNoteIndex = 0;
      _answered = false;
      _correctCount = 0;
      _feedbackText = _level == MatchLevel.single ? 'Sesi eşleştir' : 'Armonik duy, melodik söyle';
      _feedbackColor = const Color(0xFF7C6F9E);
    });

    _audioPlayer.preloadNotes(_targetNotes);
  }

  Future<void> _playPrimary() async {
    if (_targetNotes.isEmpty || _isPlaying) return;
    setState(() => _isPlaying = true);

    if (_level == MatchLevel.single) {
      // OPTİMİZASYON: Tekli seste de önceden yüklenmiş 0 gecikmeli kanalı kullan!
      await _audioPlayer.playNotesHarmonic([_targetNotes.first]);
    } else {
      await _audioPlayer.playNotesHarmonic(_targetNotes);
    }

    setState(() => _isPlaying = false);
  }

  Future<void> _playReference() async {
    if (_targetNotes.isEmpty || _isPlaying) return;
    setState(() => _isPlaying = true);

    await _audioPlayer.playNotesMelodic(_targetNotes);

    setState(() => _isPlaying = false);
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _correctCount = 0;
      _feedbackText = 'Seni dinliyorum...';
      _feedbackColor = const Color(0xFF7C6F9E);
    });

    await _pitchSubscription?.cancel();
    _pitchSubscription = null;

    await _microphone.startListening();
    _pitchSubscription = _microphone.pitchStream.listen((freq) async {
      if (!mounted || !_isListening) return;

      if (freq == null || freq < 60 || freq > 1200) return;

      final target = _targetNotes[_currentNoteIndex];
      final corrected = _analyzer.correctOctave(freq, target.frequency);
      final isCorrect = _analyzer.isCorrect(corrected, target);

      setState(() {
        if (isCorrect) {
          _feedbackColor = const Color(0xFF6EE7B7);
          _feedbackText = '${target.name} yakalandı!';
        } else {
          _feedbackColor = const Color(0xFFFBBF24);
          _feedbackText = 'Duyulan: ${freq.toStringAsFixed(1)} Hz';
        }
      });

      if (isCorrect) {
        _correctCount++;
        if (_correctCount >= 3) {
          _correctCount = 0;
          if (_currentNoteIndex < _targetNotes.length - 1) {
            setState(() {
              _currentNoteIndex++;
              _feedbackText = 'Harika! Şimdi ${_currentNoteIndex + 1}. nota...';
              _feedbackColor = const Color(0xFF7C6F9E);
            });
          } else {
            await _stopListening();
            setState(() {
              _answered = true;
              _feedbackText = '🎉 Başarılı!';
              _feedbackColor = const Color(0xFF6EE7B7);
            });
          }
        }
      } else {
        _correctCount = 0;
      }
    });
  }

  Future<void> _stopListening() async {
    if (mounted) setState(() => _isListening = false);

    await _pitchSubscription?.cancel();
    _pitchSubscription = null;

    await _microphone.stopListening();
  }

  @override
  void dispose() {
    // DİKKAT: _audioPlayer.dispose() BURADAN SİLİNDİ!
    // Sayfayı kapatsan bile ses motoru arka planda canlı kalacak.
    _pitchSubscription?.cancel();
    _microphone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Ses Verme', style: TextStyle(fontFamily: 'Playfair', color: Colors.white, fontSize: 20)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
                        selectedForegroundColor: Colors.white,
                        backgroundColor: const Color(0xFF1E1A2E),
                        foregroundColor: const Color(0xFF7C6F9E),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_targetNotes.length, (i) {
                        bool isCompleted = i < _currentNoteIndex || _answered;
                        bool isCurrent = i == _currentNoteIndex && _isListening && !_answered;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 65,
                          height: 85,
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF6EE7B7).withOpacitySafe(0.1) : const Color(0xFF1E1A2E),
                            border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFFA78BFA)
                                    : (isCompleted ? const Color(0xFF6EE7B7) : const Color(0xFF2A2440)),
                                width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(isCompleted ? _targetNotes[i].name : '?',
                                  style: TextStyle(
                                      fontFamily: 'Playfair',
                                      fontSize: 20,
                                      color: isCompleted ? const Color(0xFF6EE7B7) : Colors.white))),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_feedbackText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _feedbackColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _Btn(
                          label: _level == MatchLevel.single ? 'Duy' : 'Armonik',
                          icon: Icons.volume_up,
                          onTap: _isPlaying ? () {} : _playPrimary,
                          opacity: _isPlaying ? 0.5 : 1.0,
                        ),
                        if (_level != MatchLevel.single)
                          _Btn(
                            label: 'Melodik',
                            icon: Icons.read_more,
                            onTap: _isPlaying ? () {} : _playReference,
                            opacity: _isPlaying ? 0.5 : 1.0,
                          ),
                        _Btn(
                          label: _isListening ? 'Kapat' : 'Mikrofon',
                          icon: _isListening ? Icons.mic_off : Icons.mic,
                          isAction: true,
                          onTap: _isListening ? _stopListening : _startListening,
                        ),
                        if (_answered)
                          _Btn(label: 'Sonraki', icon: Icons.arrow_forward, isAction: true, onTap: _generateNewQuestion),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          PianoDock(
            child: const PianoKeyboard(),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAction;
  final double opacity;

  const _Btn({required this.label, required this.icon, required this.onTap, this.isAction = false, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
              backgroundColor: isAction ? const Color(0xFFA78BFA) : const Color(0xFF2A2440),
              foregroundColor: isAction ? Colors.black : const Color(0xFFA78BFA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          )
      ),
    );
  }
}