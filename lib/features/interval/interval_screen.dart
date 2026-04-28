import 'dart:math';
import 'package:flutter/material.dart';
import 'package:muzik_kulagi/core/audio/audio_player_service.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';
import 'package:muzik_kulagi/core/widgets/piano_keyboard.dart';
import 'package:muzik_kulagi/core/utils/color_utils.dart';
import 'package:muzik_kulagi/core/widgets/piano_dock.dart';

class IntervalScreen extends StatefulWidget {
  const IntervalScreen({super.key});

  @override
  State<IntervalScreen> createState() => _IntervalScreenState();
}

class _IntervalScreenState extends State<IntervalScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  List<NoteModel> _targetNotes = [];
  String? _correctIntervalName;
  bool _answered = false;
  String? _selectedInterval;
  String _feedbackText = 'Aralığı duy ve tahmin et';
  Color _feedbackColor = const Color(0xFF7C6F9E);

  final Map<String, int> _intervals = {
    'm2': 1, 'M2': 2, 'm3': 3, 'M3': 4, 'Tam 4': 5, 'Tam 5': 7, 'Oktav': 12,
  };
  final Random _rng = Random();

  @override
  void initState() { super.initState(); _generateNewQuestion(); }

  void _generateNewQuestion() {
    final intervalKeys = _intervals.keys.toList();
    _correctIntervalName = intervalKeys[_rng.nextInt(intervalKeys.length)];
    final semitoneDistance = _intervals[_correctIntervalName]!;

    // Oktav 4 içinde (C4..B4) dolaşarak, seçilen interval için taşma (out-of-range) ihtimalini sıfıra indiriyoruz.
    final octave4RootIndices = allNotes
        .asMap()
        .entries
        .where(
          (e) => e.value.name.endsWith('4') && e.key + semitoneDistance < allNotes.length,
        )
        .map((e) => e.key)
        .toList();
    final rootIndex = octave4RootIndices[_rng.nextInt(octave4RootIndices.length)];
    setState(() {
      _targetNotes = [allNotes[rootIndex], allNotes[rootIndex + semitoneDistance]];
      _answered = false; _selectedInterval = null; _feedbackText = 'Aralığı seç'; _feedbackColor = const Color(0xFF7C6F9E);
    });

    // Interval butonlarına basıldığında seslerin hazır olması için ön-yükleme.
    // ignore: unawaited_futures
    _audioPlayer.preloadNotes(_targetNotes);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Color>? highlightedNotes = _answered
        ? {
            _targetNotes[0].name: _feedbackColor,
            _targetNotes[1].name: _feedbackColor,
          }
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Aralık Tanıma',
          style: TextStyle(fontFamily: 'Playfair', color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.graphic_eq_rounded, size: 80, color: _feedbackColor.withOpacitySafe(0.5)),
                  const SizedBox(height: 20),
                  Text(_feedbackText, style: TextStyle(color: _feedbackColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_answered) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Kök: ${_targetNotes[0].name} — ${_targetNotes[0].solfege}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hedef: ${_targetNotes[1].name} — ${_targetNotes[1].solfege}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _intervals.keys
                          .map((name) => SizedBox(
                                width: (MediaQuery.of(context).size.width / 2) - 30,
                                child: ElevatedButton(
                                  onPressed: _answered
                                      ? null
                                      : () {
                                          setState(() {
                                            _answered = true;
                                            _selectedInterval = name;
                                            if (name == _correctIntervalName) {
                                              _feedbackText = '🎉 Doğru!';
                                              _feedbackColor = const Color(0xFF6EE7B7);
                                            } else {
                                              _feedbackText = '✗ Doğrusu: $_correctIntervalName';
                                              _feedbackColor = const Color(0xFFFDA4AF);
                                            }
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _answered && name == _correctIntervalName
                                          ? const Color(0xFF6EE7B7)
                                          : (_answered && name == _selectedInterval
                                              ? const Color(0xFFFDA4AF)
                                              : const Color(0xFF1E1A2E)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: Text(name),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Btn(
                          label: 'Armonik',
                          icon: Icons.all_inclusive,
                          onTap: () => _audioPlayer.playNotesHarmonic(_targetNotes)),
                      const SizedBox(width: 15),
                      _Btn(
                          label: 'Melodik',
                          icon: Icons.read_more,
                          onTap: () => _audioPlayer.playNotesMelodic(_targetNotes)),
                      if (_answered) ...[
                        const SizedBox(width: 15),
                        _Btn(
                            label: 'Sonraki',
                            icon: Icons.arrow_forward,
                            isPrimary: true,
                            onTap: _generateNewQuestion)
                      ]
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          PianoDock(
            child: PianoKeyboard(
              highlightedNotes: highlightedNotes,
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool isPrimary;
  const _Btn({required this.label, required this.icon, required this.onTap, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label), style: ElevatedButton.styleFrom(backgroundColor: isPrimary ? const Color(0xFFA78BFA) : const Color(0xFF2E2A45), foregroundColor: isPrimary ? Colors.black : const Color(0xFFA78BFA)));
  }
}