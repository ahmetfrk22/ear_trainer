class NoteModel {
  final String name;      // "C4"
  final String solfege;   // "Do"
  final double frequency; // 261.63
  final String assetPath; // "assets/audio/notes/C4.mp3"

  const NoteModel({
    required this.name,
    required this.solfege,
    required this.frequency,
    required this.assetPath,
  });
}

const List<NoteModel> allNotes = [
  NoteModel(name: 'C3',  solfege: 'Do',  frequency: 130.81, assetPath: 'assets/audio/notes/C3.mp3'),
  NoteModel(name: 'Db3', solfege: 'Re♭', frequency: 138.59, assetPath: 'assets/audio/notes/Db3.mp3'),
  NoteModel(name: 'D3',  solfege: 'Re',  frequency: 146.83, assetPath: 'assets/audio/notes/D3.mp3'),
  NoteModel(name: 'Eb3', solfege: 'Mi♭', frequency: 155.56, assetPath: 'assets/audio/notes/Eb3.mp3'),
  NoteModel(name: 'E3',  solfege: 'Mi',  frequency: 164.81, assetPath: 'assets/audio/notes/E3.mp3'),
  NoteModel(name: 'F3',  solfege: 'Fa',  frequency: 174.61, assetPath: 'assets/audio/notes/F3.mp3'),
  NoteModel(name: 'Gb3', solfege: 'Fa♯', frequency: 185.00, assetPath: 'assets/audio/notes/Gb3.mp3'),
  NoteModel(name: 'G3',  solfege: 'Sol', frequency: 196.00, assetPath: 'assets/audio/notes/G3.mp3'),
  NoteModel(name: 'Ab3', solfege: 'La♭', frequency: 207.65, assetPath: 'assets/audio/notes/Ab3.mp3'),
  NoteModel(name: 'A3',  solfege: 'La',  frequency: 220.00, assetPath: 'assets/audio/notes/A3.mp3'),
  NoteModel(name: 'Bb3', solfege: 'Si♭', frequency: 233.08, assetPath: 'assets/audio/notes/Bb3.mp3'),
  NoteModel(name: 'B3',  solfege: 'Si',  frequency: 246.94, assetPath: 'assets/audio/notes/B3.mp3'),

  NoteModel(name: 'C4',  solfege: 'Do',  frequency: 261.63, assetPath: 'assets/audio/notes/C4.mp3'),
  NoteModel(name: 'Db4', solfege: 'Re♭', frequency: 277.18, assetPath: 'assets/audio/notes/Db4.mp3'),
  NoteModel(name: 'D4',  solfege: 'Re',  frequency: 293.66, assetPath: 'assets/audio/notes/D4.mp3'),
  NoteModel(name: 'Eb4', solfege: 'Mi♭', frequency: 311.13, assetPath: 'assets/audio/notes/Eb4.mp3'),
  NoteModel(name: 'E4',  solfege: 'Mi',  frequency: 329.63, assetPath: 'assets/audio/notes/E4.mp3'),
  NoteModel(name: 'F4',  solfege: 'Fa',  frequency: 349.23, assetPath: 'assets/audio/notes/F4.mp3'),
  NoteModel(name: 'Gb4', solfege: 'Fa♯', frequency: 369.99, assetPath: 'assets/audio/notes/Gb4.mp3'),
  NoteModel(name: 'G4',  solfege: 'Sol', frequency: 392.00, assetPath: 'assets/audio/notes/G4.mp3'),
  NoteModel(name: 'Ab4', solfege: 'La♭', frequency: 415.30, assetPath: 'assets/audio/notes/Ab4.mp3'),
  NoteModel(name: 'A4',  solfege: 'La',  frequency: 440.00, assetPath: 'assets/audio/notes/A4.mp3'),
  NoteModel(name: 'Bb4', solfege: 'Si♭', frequency: 466.16, assetPath: 'assets/audio/notes/Bb4.mp3'),
  NoteModel(name: 'B4',  solfege: 'Si',  frequency: 493.88, assetPath: 'assets/audio/notes/B4.mp3'),

  NoteModel(name: 'C5',  solfege: 'Do',  frequency: 523.25, assetPath: 'assets/audio/notes/C5.mp3'),
  NoteModel(name: 'Db5', solfege: 'Re♭', frequency: 554.37, assetPath: 'assets/audio/notes/Db5.mp3'),
  NoteModel(name: 'D5',  solfege: 'Re',  frequency: 587.33, assetPath: 'assets/audio/notes/D5.mp3'),
  NoteModel(name: 'Eb5', solfege: 'Mi♭', frequency: 622.25, assetPath: 'assets/audio/notes/Eb5.mp3'),
  NoteModel(name: 'E5',  solfege: 'Mi',  frequency: 659.25, assetPath: 'assets/audio/notes/E5.mp3'),
  NoteModel(name: 'F5',  solfege: 'Fa',  frequency: 698.46, assetPath: 'assets/audio/notes/F5.mp3'),
  NoteModel(name: 'Gb5', solfege: 'Fa♯', frequency: 739.99, assetPath: 'assets/audio/notes/Gb5.mp3'),
  NoteModel(name: 'G5',  solfege: 'Sol', frequency: 783.99, assetPath: 'assets/audio/notes/G5.mp3'),
  NoteModel(name: 'Ab5', solfege: 'La♭', frequency: 830.61, assetPath: 'assets/audio/notes/Ab5.mp3'),
  NoteModel(name: 'A5',  solfege: 'La',  frequency: 880.00, assetPath: 'assets/audio/notes/A5.mp3'),
  NoteModel(name: 'Bb5', solfege: 'Si♭', frequency: 932.33, assetPath: 'assets/audio/notes/Bb5.mp3'),
  NoteModel(name: 'B5',  solfege: 'Si',  frequency: 987.77, assetPath: 'assets/audio/notes/B5.mp3'),

  NoteModel(name: 'C6',  solfege: 'Do',  frequency: 1046.50, assetPath: 'assets/audio/notes/C6.mp3'),
];