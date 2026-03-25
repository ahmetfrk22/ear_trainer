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

  // Notalarımız C6'ya kadar olduğu için maksimum başlangıç oktavı 5 olabilir.
  // Böylece Oktav 5 seçildiğinde son tuş C6'yı gösterebilir.
  static const int _minOctave = 2;
  static const int _maxOctave = 5;

  // Basılan tuşu anlık olarak takip etmek için
  String? _pressedKey;

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
    // Artık 8 beyaz tuşumuz var: C, D, E, F, G, A, B ve bir sonraki oktavın C'si.
    final whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];
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
              // Ekranı 8 beyaz tuşa göre bölüyoruz
              final whiteKeyWidth = constraints.maxWidth / 8;
              final blackKeyWidth = whiteKeyWidth * 0.65;

              return Stack(
                children: [
                  // Beyaz tuşlar
                  Row(
                    children: List.generate(8, (i) {
                      // Son tuş (index 7) bir üst oktavın C'sidir
                      final isNextOctaveC = i == 7;
                      final currentOctave = isNextOctaveC ? _octave + 1 : _octave;
                      final noteName = '${whiteNotes[i]}$currentOctave';

                      final noteExists = allNotes.any((n) => n.name == noteName);
                      if (!noteExists) {
                        return SizedBox(width: whiteKeyWidth);
                      }

                      final note = allNotes.firstWhere((n) => n.name == noteName);
                      final isHighlighted = widget.highlightedNote == noteName;
                      final isPressed = _pressedKey == noteName;

                      return GestureDetector(
                        onTapDown: (_) => setState(() => _pressedKey = noteName),
                        onTapUp: (_) async {
                          setState(() => _pressedKey = null);
                          await _audioPlayer.playNote(note);
                          if (widget.onKeyTap != null) widget.onKeyTap!(note);
                        },
                        onTapCancel: () => setState(() => _pressedKey = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: whiteKeyWidth,
                          height: 140,
                          // Basıldığında veya doğru cevap olduğunda renk değişimi
                          decoration: BoxDecoration(
                            color: isPressed
                                ? const Color(0xFFD4C9FF) // Basılma efekti (açık mor)
                                : isHighlighted
                                ? const Color(0xFFA78BFA) // Hedef nota (mor)
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
                              padding: EdgeInsets.only(bottom: isPressed ? 4 : 8), // Basıldığında yazı hafif aşağı kayar
                              child: Text(
                                whiteNotes[i],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (isHighlighted || isPressed)
                                      ? (isPressed ? const Color(0xFF13111C) : Colors.white)
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
                    final isPressed = _pressedKey == noteName;

                    // Siyah tuşların pozisyon hesabı (Beyaz tuşların arasına yerleşir)
                    final leftOffset = ((i + 1) * whiteKeyWidth) - (blackKeyWidth / 2);

                    return Positioned(
                      left: leftOffset,
                      top: 0,
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _pressedKey = noteName),
                        onTapUp: (_) async {
                          setState(() => _pressedKey = null);
                          await _audioPlayer.playNote(note);
                          if (widget.onKeyTap != null) widget.onKeyTap!(note);
                        },
                        onTapCancel: () => setState(() => _pressedKey = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: blackKeyWidth,
                          height: isPressed ? 86 : 90, // Basıldığında hafif kısalır (çökme hissi)
                          decoration: BoxDecoration(
                            color: isPressed
                                ? const Color(0xFF7C6F9E) // Basılma efekti
                                : isHighlighted
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