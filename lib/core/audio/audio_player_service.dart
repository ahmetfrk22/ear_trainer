import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  late final List<AudioPlayer> _channels;
  late final AudioPlayer _pianoPlayer;
  late final AudioPlayer _metronomePlayer;

  AudioPlayerService._internal() {
    _channels = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
    _pianoPlayer = AudioPlayer();
    _metronomePlayer = AudioPlayer();
  }

  Future<void> preloadNotes(List<NoteModel> notes) async {
    for (int i = 0; i < notes.length; i++) {
      if (i < _channels.length) {
        try {
          await _channels[i].stop();
          await _channels[i].setAsset(notes[i].assetPath);
        } catch (e) {
          debugPrint('Ön-yükleme hatası: ${notes[i].name}');
        }
      }
    }
  }

  Future<void> playNote(NoteModel note) async {
    try {
      await _pianoPlayer.stop();
      await _pianoPlayer.setAsset(note.assetPath);
      _pianoPlayer.play();
    } catch (e) {
      debugPrint('Çalma hatası: ${note.name}');
    }
  }

  Future<void> playNotesHarmonic(List<NoteModel> notes) async {
    for (int i = 0; i < notes.length; i++) {
      if (i < _channels.length) {
        await _channels[i].stop();
        await _channels[i].seek(Duration.zero);
        _channels[i].play();
      }
    }
  }

  Future<void> playNotesMelodic(List<NoteModel> notes) async {
    for (int i = 0; i < notes.length; i++) {
      if (i < _channels.length) {
        await _channels[i].stop();
        await _channels[i].seek(Duration.zero);
        _channels[i].play();
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }
  }

  Future<void> playMetronomeClick({bool isAccent = false}) async {
    try {
      await _metronomePlayer.setAsset(isAccent ? 'assets/audio/notes/C4.mp3' : 'assets/audio/notes/C3.mp3');
      _metronomePlayer.setVolume(0.5);
      await _metronomePlayer.stop();
      await _metronomePlayer.play();
    } catch (e) {
      debugPrint('Metronom sesi hatası: $e');
    }
  }

  void dispose() {
    // Singleton olduğu için kapatılmıyor
  }
}
