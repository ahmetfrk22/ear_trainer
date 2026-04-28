import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'pitch_detector.dart';

class MicrophoneService {
  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _pitchDetector = PitchDetector();
  StreamController<double?>? _pitchController;
  Stream<double?>? _pitchStream;
  StreamSubscription<Uint8List>? _recorderSubscription;

  Stream<double?> get pitchStream => _pitchStream ?? Stream<double?>.empty();

  Future<void> startListening() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    if (_recorderSubscription != null) {
      await stopListening();
    }

    _pitchController = StreamController<double?>.broadcast();
    _pitchStream = _pitchController!.stream;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
    );

    _recorderSubscription = stream.listen((Uint8List data) {
      final controller = _pitchController;
      if (controller == null || controller.isClosed) return;

      final buffer = _convertToDoubleList(data);
      if (buffer.length >= 2048) {
        final pitch = _pitchDetector.detect(buffer.sublist(0, 2048));
        if (pitch != null && !controller.isClosed) {
          controller.add(pitch);
        }
      }
    });
  }

  Future<void> stopListening() async {
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;

    await _recorder.stop();
    await _pitchController?.close();
    _pitchController = null;
    _pitchStream = null;
  }

  List<double> _convertToDoubleList(Uint8List bytes) {
    final result = <double>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final sample = (bytes[i + 1] << 8) | bytes[i];
      final signed = sample > 32767 ? sample - 65536 : sample;
      result.add(signed / 32768.0);
    }
    return result;
  }

  void dispose() {
    // cancel() Future döndüğü için await edemiyoruz; ama subscription referansını boşaltıyoruz.
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _recorder.dispose();
    _pitchController?.close();
    _pitchController = null;
    _pitchStream = null;
  }
}
