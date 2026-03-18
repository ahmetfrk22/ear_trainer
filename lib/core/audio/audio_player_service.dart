import 'package:just_audio/just_audio.dart';
import '../models/note_model.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playNote(NoteModel note) async {
    await _player.setAsset(note.assetPath);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
