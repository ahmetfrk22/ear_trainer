import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../audio/audio_player_service.dart';

class PianoKeyboard extends StatefulWidget {
  final String? highlightedNote;
  final Function(NoteModel)? onKeyTap;
  final int initialOctave;

  const PianoKeyboard({
    super.key,
    this.highlightedNote,
    this.onKeyTap,
    this.initialOctave = 4,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  late int _octave;

  static const int _minOctave = 2;
  static const int _maxOctave = 6;

  @override
  void initState() {
    super.initState();
    _octave = widget.initialOctave;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _decreaseOctave() {
    if (_octave > _minOctave) setState(() => _octave--);
  }

  void _increaseOctave() {
    if (_octave < _maxOctave) setState(() => _octave++);
  }

  @override
  Widget build(BuildContext context) {
    final whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final blackNotes = {0: 'Db', 1: 'Eb', 3: 'Gb', 4: 'Ab', 5: 'Bb'};

    return Column(
      children: [
        // Oktav seçici
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OctaveButton(
              icon: Icons.remove_rounded,
              onTap: _octave > _minOctave ? _decreaseOctave : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Oktav $_octave',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7C6F9E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            _OctaveButton(
              icon: Icons.add_rounded,
              onTap: _octave < _maxOctave ? _increaseOctave : null,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Piyano tuşları
        SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final whiteKeyWidth = constraints.maxWidth / 7;
              final blackKeyWidth = whiteKeyWidth * 0.6;

              return Stack(
                children: [
                  // Beyaz tuşlar
                  Row(
                    children: List.generate(7, (i) {
                      final noteName = '${whiteNotes[i]}$_octave';
                      final noteExists = allNotes.any((n) => n.name == noteName);
                      if (!noteExists) {
                        return SizedBox(width: whiteKeyWidth);
                      }
                      final note = allNotes.firstWhere((n) => n.name == noteName);
                      final isHighlighted = widget.highlightedNote == noteName;

                      return GestureDetector(
                        onTap: () async {
                          await _audioPlayer.playNote(note);
                          if (widget.onKeyTap != null) widget.onKeyTap!(note);
                        },
                        child: Container(
                          width: whiteKeyWidth,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFA78BFA)
                                : Colors.white,
                            border: Border.all(
                              color: const Color(0xFF2A2440),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                whiteNotes[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isHighlighted
                                      ? Colors.white
                                      : const Color(0xFF4A4560),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Siyah tuşlar
                  ...blackNotes.entries.map((entry) {
                    final i = entry.key;
                    final notePrefix = entry.value;
                    final noteName = '$notePrefix$_octave';
                    final noteExists = allNotes.any((n) => n.name == noteName);
                    if (!noteExists) return const SizedBox();
                    final note = allNotes.firstWhere((n) => n.name == noteName);
                    final isHighlighted = widget.highlightedNote == noteName;
                    final leftOffset = (i * whiteKeyWidth) +
                        (whiteKeyWidth - blackKeyWidth / 2) -
                        (whiteKeyWidth * 0.08);

                    return Positioned(
                      left: leftOffset,
                      top: 0,
                      child: GestureDetector(
                        onTap: () async {
                          await _audioPlayer.playNote(note);
                          if (widget.onKeyTap != null) widget.onKeyTap!(note);
                        },
                        child: Container(
                          width: blackKeyWidth,
                          height: 90,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF1A1628),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OctaveButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OctaveButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2A45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFC4B5FD),
          ),
        ),
      ),
    );
  }
}