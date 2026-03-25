import 'package:just_audio/just_audio.dart';
import '../models/note_model.dart';

class AudioPlayerService {
  // Aynı anda maksimum 4 ses (akorlar ve yedili akorlar için) çalabilmek adına bir oynatıcı havuzu oluşturuyoruz.
  final List<AudioPlayer> _players = List.generate(4, (_) => AudioPlayer());

  // --- 1. Tek Ses Çalma ---
  Future<void> playNote(NoteModel note) async {
    await _stopAll();
    await _players[0].setAsset(note.assetPath);
    await _players[0].play();
  }

  // --- 2. Armonik Çalma (Aynı Anda) ---
  Future<void> playNotesHarmonic(List<NoteModel> notes) async {
    await _stopAll();

    // Elimizdeki oynatıcı sayısını aşmamak için kontrol
    final count = notes.length <= _players.length ? notes.length : _players.length;

    // Gecikmeyi (latency) önlemek için önce tüm sesleri oynatıcılara yüklüyoruz
    List<Future<void>> loadTasks = [];
    for (int i = 0; i < count; i++) {
      loadTasks.add(_players[i].setAsset(notes[i].assetPath));
    }
    await Future.wait(loadTasks); // Yüklemelerin bitmesini bekle

    // Yükleme bitince hepsini aynı milisaniyede ateşle
    for (int i = 0; i < count; i++) {
      _players[i].play();
    }
  }

  // --- 3. Melodik Çalma (Ardışık) ---
  Future<void> playNotesMelodic(List<NoteModel> notes, {Duration delay = const Duration(milliseconds: 700)}) async {
    await _stopAll();

    // Notaları sırayla tek bir oynatıcı üzerinden, araya bekleme süresi koyarak çal
    for (int i = 0; i < notes.length; i++) {
      await _players[0].setAsset(notes[i].assetPath);
      await _players[0].play();

      // Son nota değilse, bir sonraki notaya geçmeden önce bekle
      if (i < notes.length - 1) {
        await Future.delayed(delay);
      }
    }
  }

  // Tüm oynatıcıları sustur
  Future<void> _stopAll() async {
    List<Future<void>> stopTasks = [];
    for (var player in _players) {
      stopTasks.add(player.stop());
    }
    await Future.wait(stopTasks);
  }

  Future<void> stop() async {
    await _stopAll();
  }

  void dispose() {
    for (var player in _players) {
      player.dispose();
    }
  }
}