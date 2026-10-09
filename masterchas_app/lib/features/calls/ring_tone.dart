import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Гудки при звонке. Звук генерируется в коде (WAV в памяти),
/// поэтому не нужны отдельные аудиофайлы.
class RingTone {
  AudioPlayer? _player;

  /// outgoing — длинные гудки (как у оператора), incoming — двойной звонок.
  Future<void> start({required bool incoming}) async {
    await stop();
    try {
      final player = AudioPlayer();
      _player = player;
      // Не забираем аудиосессию у звонка (иначе на iOS может отключиться микрофон).
      await player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.voiceCommunicationSignalling,
          contentType: AndroidContentType.sonification,
        ),
      ));
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(BytesSource(_buildWav(incoming: incoming), mimeType: 'audio/wav'));
    } catch (_) {
      // Если звук недоступен (например, в браузере без взаимодействия) — звоним без гудков.
    }
  }

  Future<void> stop() async {
    final p = _player;
    _player = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }

  static Uint8List _buildWav({required bool incoming}) {
    const rate = 8000;
    // Узор: список (звук?, длительность в мс).
    final pattern = incoming
        ? const [(true, 400), (false, 200), (true, 400), (false, 2000)]
        : const [(true, 1000), (false, 3000)];
    final freqs = incoming ? const [600.0, 800.0] : const [425.0];

    final samples = <int>[];
    for (final (on, ms) in pattern) {
      final n = rate * ms ~/ 1000;
      for (var i = 0; i < n; i++) {
        if (!on) {
          samples.add(0);
          continue;
        }
        final t = i / rate;
        var v = 0.0;
        for (final f in freqs) {
          v += math.sin(2 * math.pi * f * t);
        }
        v /= freqs.length;
        // Плавное начало/конец, чтобы не щёлкало.
        final edge = math.min(1.0, math.min(i, n - i) / (rate * 0.01));
        samples.add((v * edge * 9000).round());
      }
    }

    final dataLen = samples.length * 2;
    final b = BytesBuilder();
    void str(String s) => b.add(s.codeUnits);
    void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
    void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
    str('RIFF');
    u32(36 + dataLen);
    str('WAVE');
    str('fmt ');
    u32(16);
    u16(1); // PCM
    u16(1); // mono
    u32(rate);
    u32(rate * 2);
    u16(2);
    u16(16);
    str('data');
    u32(dataLen);
    final pcm = ByteData(dataLen);
    for (var i = 0; i < samples.length; i++) {
      pcm.setInt16(i * 2, samples[i], Endian.little);
    }
    b.add(pcm.buffer.asUint8List());
    return b.toBytes();
  }
}
