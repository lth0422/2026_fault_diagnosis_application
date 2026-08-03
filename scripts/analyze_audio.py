#!/usr/bin/env python3
"""
슬로모션 영상의 오디오에서 베어링 결함주파수를 검증하는 스크립트.
- 오디오 추출(ffmpeg) → 공진대역 밴드패스 → 포락선(envelope) → FFT
- stretch(슬로모션 배수) 복원 후 이론 결함주파수(BPFO/BPFI/BSF)와 비교

사용법:
  python3 scripts/analyze_audio.py test_videos/1217_6204_1200_OR_F_3.mp4 \
      --rpm 1200 --record-fps 240 --balls 8 --ball-d 7.94 --pitch-d 33.5

ffmpeg는 imageio-ffmpeg(static) 사용. 의존성: numpy, imageio-ffmpeg.
"""
import argparse, subprocess, tempfile, wave, os
import numpy as np


def extract_audio(mp4, wav):
    import imageio_ffmpeg
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    subprocess.run([ff, "-y", "-i", mp4, "-vn", "-ac", "1", "-ar", "44100",
                    "-f", "wav", wav], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def get_video_fps(mp4):
    import imageio_ffmpeg
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    out = subprocess.run([ff, "-i", mp4], stderr=subprocess.PIPE).stderr.decode("utf-8", "ignore")
    import re
    m = re.search(r"(\d+\.?\d*)\s*fps", out)
    return float(m.group(1)) if m else None


def envelope_spectrum(x, fs, band=(2000, 8000)):
    N = len(x)
    f = np.fft.rfftfreq(N, 1 / fs)
    Xc = np.fft.rfft(x)
    Xb = np.zeros_like(Xc)
    m = (f >= band[0]) & (f <= band[1])
    Xb[m] = Xc[m]
    xb = np.fft.irfft(Xb, N)
    F = np.fft.fft(xb); F[N // 2 + 1:] = 0; F[1:N // 2] *= 2
    env = np.abs(np.fft.ifft(F)); env -= env.mean()
    E = np.abs(np.fft.rfft(env * np.hanning(N)))
    fe = np.fft.rfftfreq(N, 1 / fs)
    return fe, E


def bearing_freqs(rpm, n, d, D, theta=0.0):
    fr = rpm / 60.0
    c = (d / D) * np.cos(theta)
    return dict(fr=fr, FTF=0.5 * (1 - c) * fr, BSF=D / (2 * d) * (1 - c ** 2) * fr,
                BPFO=n / 2 * (1 - c) * fr, BPFI=n / 2 * (1 + c) * fr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--rpm", type=float, default=1200)
    ap.add_argument("--record-fps", type=float, default=240, help="촬영 fps(슬로모션 원본)")
    ap.add_argument("--balls", type=int, default=8)
    ap.add_argument("--ball-d", type=float, default=7.94)
    ap.add_argument("--pitch-d", type=float, default=33.5)
    a = ap.parse_args()

    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, "a.wav")
        extract_audio(a.video, wav)
        w = wave.open(wav, "rb"); fs = w.getframerate(); n = w.getnframes()
        x = np.frombuffer(w.readframes(n), dtype=np.int16).astype(float); w.close()
    x -= x.mean()

    export_fps = get_video_fps(a.video) or a.record_fps
    stretch = a.record_fps / export_fps
    bf = bearing_freqs(a.rpm, a.balls, a.ball_d, a.pitch_d)

    fe, E = envelope_spectrum(x, fs)
    band = (fe >= 3) & (fe <= 40)
    f0 = fe[np.where(band)[0][np.argmax(E[band])]]

    print(f"video fps={export_fps:.2f}  stretch=record/export={stretch:.3f}")
    print(f"envelope 기본파 f0={f0:.2f} Hz  →  실시간복원 {f0*stretch:.1f} Hz")
    print(f"이론(실시간): BPFO={bf['BPFO']:.1f} BPFI={bf['BPFI']:.1f} "
          f"BSF={bf['BSF']:.1f} FTF={bf['FTF']:.1f} fr={bf['fr']:.1f} Hz")
    print("고조파:")
    for k in range(1, 6):
        i = np.argmin(np.abs(fe - f0 * k))
        print(f"  {k}x {f0*k:6.2f}Hz amp={E[i]/E[band].max():.3f} (실시간 {f0*k*stretch:6.1f}Hz)")


if __name__ == "__main__":
    main()
