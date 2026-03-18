import 'dart:math';
import '../models/note_model.dart';

class PitchAnalyzer {
  NoteModel? findClosestNote(double frequency) {
    if (frequency <= 0) return null;

    NoteModel? closest;
    double minCents = double.infinity;

    for (final note in allNotes) {
      final cents = _centDifference(frequency, note.frequency).abs();
      if (cents < minCents) {
        minCents = cents;
        closest = note;
      }
    }

    return closest;
  }

  String getNoteNameFromFrequency(double frequency) {
    if (frequency <= 0) return '—';

    final midi = (12 * log(frequency / 440.0) / log(2.0) + 69).round();
    const noteNames = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
    final noteName = noteNames[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$noteName$octave';
  }

  double correctOctave(double frequency, double targetFrequency) {
    double corrected = frequency;

    if ((corrected * 2 - targetFrequency).abs() < (corrected - targetFrequency).abs()) {
      corrected *= 2;
    }
    if ((corrected / 2 - targetFrequency).abs() < (corrected - targetFrequency).abs()) {
      corrected /= 2;
    }

    return corrected;
  }

  double centDifference(double detectedFreq, double targetFreq) {
    return _centDifference(detectedFreq, targetFreq);
  }

  double _centDifference(double f1, double f2) {
    return 1200.0 * log(f1 / f2) / log(2.0);
  }

  bool isCorrect(double detectedFreq, NoteModel targetNote,
      {double toleranceCents = 50.0}) {
    final corrected = correctOctave(detectedFreq, targetNote.frequency);
    final cents = centDifference(corrected, targetNote.frequency).abs();
    return cents <= toleranceCents;
  }
}