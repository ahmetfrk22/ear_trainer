import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muzik_kulagi/core/models/note_model.dart';

class AudioPlayerService {
  // SINGLETON DESENİ: Uygulama boyunca sadece 1 tane ses motoru olacak.
  // Bu, emülatörün/telefonun "çok fazla oynatıcı açıldı" diyerek sesi kesmesini %100 engeller.
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  late final List<AudioPlayer> _channels;
  late final AudioPlayer _pianoPlayer;

  AudioPlayerService._internal() {
    // Uygulama ömrü boyunca SADECE 1 KEZ üretilir!
    _channels = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
    _pianoPlayer = AudioPlayer();
  }

  Future<void> preloadNotes(List<NoteModel> notes) async {
    for (int i = 0; i < notes.length; i++) {
      if (i < _channels.length) {
        try {
          await _channels[i]
              .stop(); // Yüklemeden önce kanalı temizle ki boğulmasın
          await _channels[i].setAsset(notes[i].assetPath);
        } catch (e) {
          debugPrint('Ön-yükleme hatası: ${notes[i].name}');
        }
      }
    }
  }

  Future<void> playNote(NoteModel note) async {
    try {
      await _pianoPlayer
          .stop(); // Piyano tuşuna peş peşe basıldığında önceki sesi anında kes
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

  void dispose() {
    // SINGLETON OLDUĞU İÇİN DİSPOSE EDİLMEMELİ!
    // Eskiden sayfadan çıkınca kanallar ölüyordu, sessizliğe sebep olan asıl tuzak buydu.
  }
}
