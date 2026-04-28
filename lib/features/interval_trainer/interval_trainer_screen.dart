import 'dart:math';
import 'package:flutter/material.dart';
import 'package:muzik_kulagi/core/audio/audio_player_service.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';
import 'package:muzik_kulagi/core/widgets/piano_keyboard.dart';
import 'package:muzik_kulagi/core/widgets/piano_dock.dart';
import 'package:muzik_kulagi/core/utils/color_utils.dart';

class IntervalTrainerScreen extends StatefulWidget {
  const IntervalTrainerScreen({super.key});

  @override
  State<IntervalTrainerScreen> createState() => _IntervalTrainerScreenState();
}

class _IntervalTrainerScreenState extends State<IntervalTrainerScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final Random _rng = Random();

  late NoteModel _rootNote;
  late String _targetIntervalName;
  late int _targetSemitones;
  NoteModel? _correctNote;
  
  bool _answered = false;
  NoteModel? _userSelectedNote;
  bool? _isCorrect;

  final Map<String, int> _intervals = {
    'm2': 1, 'M2': 2, 'm3': 3, 'M3': 4, 'Tam 4': 5, 
    'Art. 4 / Eks. 5': 6, 'Tam 5': 7, 'm6': 8, 'M6': 9, 
    'm7': 10, 'M7': 11, 'Oktav': 12,
  };

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final intervalKeys = _intervals.keys.toList();
    _targetIntervalName = intervalKeys[_rng.nextInt(intervalKeys.length)];
    _targetSemitones = _intervals[_targetIntervalName]!;

    // C3 ile C5 arasında bir kök nota seçelim ki üzerine eklediğimizde çok dışarı taşmasın
    final possibleRoots = allNotes.where((n) {
      final idx = allNotes.indexOf(n);
      return idx + _targetSemitones < allNotes.length && n.name.contains(RegExp(r'[34]'));
    }).toList();

    _rootNote = possibleRoots[_rng.nextInt(possibleRoots.length)];
    final rootIdx = allNotes.indexOf(_rootNote);
    _correctNote = allNotes[rootIdx + _targetSemitones];

    setState(() {
      _answered = false;
      _userSelectedNote = null;
      _isCorrect = null;
    });

    _audioPlayer.preloadNotes([_rootNote, _correctNote!]);
  }

  void _handleKeyTap(NoteModel tappedNote) {
    if (_answered) return;

    // Sadece nota adına (octave bağımsız) bakarak kontrol edelim
    // Örn: Bb4 -> Bb
    final tappedBaseName = tappedNote.name.replaceAll(RegExp(r'[0-9]'), '');
    final correctBaseName = _correctNote!.name.replaceAll(RegExp(r'[0-9]'), '');

    setState(() {
      _answered = true;
      _userSelectedNote = tappedNote;
      _isCorrect = tappedBaseName == correctBaseName;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Görsel geri bildirimde de octave bağımsız renklendirme yapalım
    Map<String, Color> highlightedNotes = {};
    
    // Kök notanın o oktavdaki karşılığını bul (Genellikle piyanonun ilk tuşu olacak)
    final rootBaseName = _rootNote.name.replaceAll(RegExp(r'[0-9]'), '');
    
    // Mevcut piyano görünümündeki (initialOctave) notaları boyayalım
    // Not: PianoKeyboard içinde gösterilen notalar 'notePrefix + currentOctave' formatında.

    highlightedNotes[_rootNote.name] = const Color(0xFFA78BFA);

    if (_answered) {
      if (_isCorrect!) {
        highlightedNotes[_userSelectedNote!.name] = const Color(0xFF6EE7B7);
      } else {
        highlightedNotes[_userSelectedNote!.name] = const Color(0xFFFDA4AF);
        // Doğru notanın piyanodaki herhangi bir oktavdaki halini göster (ama biz sabit oktavdayız)
        // correctBaseName'e sahip olan ve ekrandaki oktavda olan notayı bulmamız lazım.
        final correctBaseName = _correctNote!.name.replaceAll(RegExp(r'[0-9]'), '');
        final pianoOctave = int.tryParse(_rootNote.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4;
        
        final screenCorrectNote = '${correctBaseName}${pianoOctave}';
        final screenNextOctaveCorrectNote = '${correctBaseName}${pianoOctave + 1}';
        
        highlightedNotes[screenCorrectNote] = const Color(0xFF6EE7B7);
        highlightedNotes[screenNextOctaveCorrectNote] = const Color(0xFF6EE7B7);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Aralık Bulma', style: TextStyle(fontFamily: 'Playfair', color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Görev Kartı
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2E2A45), width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Kök Nota',
                            style: TextStyle(color: Color(0xFF7C6F9E), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_rootNote.name.replaceAll(RegExp(r'[0-9]'), '')} (${_rootNote.solfege})',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: 'Playfair', fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Color(0xFF2E2A45), thickness: 1),
                          ),
                          const Text(
                            'Bulman Gereken Aralık',
                            style: TextStyle(color: Color(0xFF7C6F9E), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _targetIntervalName,
                            style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Feedback Alanı
                    if (_answered)
                      Column(
                        children: [
                          Text(
                            _isCorrect! ? 'Harika! Doğru Tuş.' : 'Oops! Doğrusu ${_correctNote?.name}',
                            style: TextStyle(
                              color: _isCorrect! ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _generateQuestion,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Sonraki Soru'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA78BFA),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Piyanoda doğru tuşa bas!',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          ),
          PianoDock(
            child: PianoKeyboard(
              highlightedNotes: highlightedNotes,
              onKeyTap: _handleKeyTap,
              initialOctave: int.tryParse(_rootNote.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 4,
              showOctaveSelector: false,
            ),
          ),
        ],
      ),
    );
  }
}
