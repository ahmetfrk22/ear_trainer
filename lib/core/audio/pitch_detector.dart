class PitchDetector {
  final int sampleRate;
  final int bufferSize;

  PitchDetector({this.sampleRate = 44100, this.bufferSize = 2048});

  // YIN algoritması — ham ses verisinden frekans tespit eder
  double? detect(List<double> buffer) {
    final yinBuffer = List<double>.filled(bufferSize ~/ 2, 0.0);

    // Adım 1: Fark fonksiyonu
    for (int tau = 0; tau < yinBuffer.length; tau++) {
      for (int i = 0; i < yinBuffer.length; i++) {
        final delta = buffer[i] - buffer[i + tau];
        yinBuffer[tau] += delta * delta;
      }
    }

    // Adım 2: Kümülatif ortalama normalize fark fonksiyonu
    yinBuffer[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau < yinBuffer.length; tau++) {
      runningSum += yinBuffer[tau];
      yinBuffer[tau] *= tau / runningSum;
    }

    // Adım 3: Eşik altındaki ilk minimumu bul
    const double threshold = 0.15;
    int? tauEstimate;
    for (int tau = 2; tau < yinBuffer.length - 1; tau++) {
      if (yinBuffer[tau] < threshold) {
        while (tau + 1 < yinBuffer.length &&
            yinBuffer[tau + 1] < yinBuffer[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    if (tauEstimate == null) return null;

    // Adım 4: Parabolik interpolasyon (daha hassas sonuç)
    final int x0 = tauEstimate > 0 ? tauEstimate - 1 : tauEstimate;
    final int x2 = tauEstimate + 1 < yinBuffer.length
        ? tauEstimate + 1
        : tauEstimate;

    double betterTau;
    if (x0 == tauEstimate) {
      betterTau = yinBuffer[tauEstimate] <= yinBuffer[x2]
          ? tauEstimate.toDouble()
          : x2.toDouble();
    } else if (x2 == tauEstimate) {
      betterTau = yinBuffer[tauEstimate] <= yinBuffer[x0]
          ? tauEstimate.toDouble()
          : x0.toDouble();
    } else {
      final s0 = yinBuffer[x0];
      final s2 = yinBuffer[x2];
      betterTau =
          tauEstimate +
          (s2 - s0) / (2.0 * (2.0 * yinBuffer[tauEstimate] - s2 - s0));
    }

    return sampleRate / betterTau;
  }
}
