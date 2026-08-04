#!/usr/bin/env python3
"""
음향(오디오) 분석 결과를 논문/회의용 그림으로 저장하는 스크립트.
analyze_audio.py 의 함수를 재사용한다.

생성 그림 (docs/figures/):
  1) audio_envelope_spectrum.png : 포락선 스펙트럼(실시간 복원 주파수축) + BPFO/BPFI 이론선
  2) freq_coverage_audio_vs_video.png : 오디오 vs 240fps 영상 주파수 커버리지 + Nyquist 경계
  3) bearing_fault_freq_table.png : 6204 이론 결함주파수 표

사용법:
  python3 scripts/plot_audio_figures.py test_videos/1217_6204_1200_OR_F_3.mp4 \
      --rpm 1200 --record-fps 240 --balls 8 --ball-d 7.94 --pitch-d 33.5

의존성: numpy, matplotlib, imageio-ffmpeg. (scipy 불필요)
"""
import argparse, os, sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze_audio import (extract_audio, get_video_fps,
                           envelope_spectrum, bearing_freqs)

# 한글 폰트
for cand in ("NanumGothic", "NanumBarunGothic", "NanumSquare"):
    if any(f.name == cand for f in font_manager.fontManager.ttflist):
        plt.rcParams["font.family"] = cand
        break
plt.rcParams["axes.unicode_minus"] = False

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "docs", "figures")
os.makedirs(OUT, exist_ok=True)


def load_audio(mp4):
    import tempfile, wave
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, "a.wav")
        extract_audio(mp4, wav)
        w = wave.open(wav, "rb"); fs = w.getframerate(); nf = w.getnframes()
        x = np.frombuffer(w.readframes(nf), dtype=np.int16).astype(float); w.close()
    x -= x.mean()
    return x, fs


def fig1_envelope(x, fs, stretch, bf, label):
    """포락선 스펙트럼(실시간 복원 축) + 이론 결함주파수선."""
    fe, E = envelope_spectrum(x, fs)
    fr = fe * stretch                     # 실시간 복원 주파수축
    E = E / E[(fe >= 3) & (fe <= 40)].max()  # 정규화
    m = (fr >= 0) & (fr <= 320)

    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.plot(fr[m], E[m], color="#1f77b4", lw=1.0)
    ax.fill_between(fr[m], E[m], color="#1f77b4", alpha=0.15)

    # 검출 기본파 + 고조파
    band = (fe >= 3) & (fe <= 40)
    f0 = fe[np.where(band)[0][np.argmax(E[band])]]
    for k in range(1, 6):
        fk = f0 * k * stretch
        if fk <= 320:
            ax.axvline(fk, color="#2ca02c", ls=":", lw=0.9, alpha=0.7)
    ax.plot([], [], color="#2ca02c", ls=":", label=f"검출 BPFO 고조파 (k×{f0*stretch:.1f}Hz)")

    # 이론선
    ax.axvline(bf["BPFO"], color="#d62728", ls="--", lw=1.4,
               label=f"이론 BPFO = {bf['BPFO']:.1f} Hz")
    ax.axvline(bf["BPFI"], color="#ff7f0e", ls="--", lw=1.2,
               label=f"이론 BPFI = {bf['BPFI']:.1f} Hz")

    ax.set_xlabel("복원 주파수 [Hz]  (포락선 축 × stretch %.2f)" % stretch)
    ax.set_ylabel("정규화 포락 스펙트럼 진폭")
    ax.set_title(f"스마트폰 슬로모션 오디오 포락선 스펙트럼 — {label}\n"
                 f"검출 {f0*stretch:.1f} Hz ≈ 이론 BPFO {bf['BPFO']:.1f} Hz (외륜 결함 서명)")
    ax.set_xlim(0, 320); ax.set_ylim(0, 1.15)
    ax.legend(fontsize=8, loc="upper right")
    ax.grid(alpha=0.25)
    fig.tight_layout()
    p = os.path.join(OUT, "audio_envelope_spectrum.png")
    fig.savefig(p, dpi=150); plt.close(fig)
    return p, f0


def fig2_coverage(bf):
    """오디오 vs 240fps 영상 주파수 커버리지 + Nyquist 경계."""
    nyq_video = 240 / 2.0     # 120 Hz
    fig, ax = plt.subplots(figsize=(9, 3.6))

    # 커버리지 막대
    ax.barh(1, 320, left=0, height=0.5, color="#2ca02c", alpha=0.35,
            label="오디오 (44.1kHz) 유효대역")
    ax.barh(0, nyq_video, left=0, height=0.5, color="#1f77b4", alpha=0.45,
            label="240fps 영상 접근가능 (0–Nyquist)")

    # 결함주파수 마커 (기본 + 고조파)
    marks = [("FTF", bf["FTF"], "#7f7f7f"), ("BSF", bf["BSF"], "#9467bd"),
             ("BPFO", bf["BPFO"], "#d62728"), ("BPFI", bf["BPFI"], "#ff7f0e"),
             ("2×BPFO", 2*bf["BPFO"], "#d62728"), ("2×BPFI", 2*bf["BPFI"], "#ff7f0e"),
             ("3×BPFO", 3*bf["BPFO"], "#d62728")]
    for name, f, c in marks:
        if f > 320:
            continue
        ax.axvline(f, color=c, ls="--", lw=1.0, alpha=0.8)
        inside = f <= nyq_video
        ax.text(f, 1.75, name, rotation=90, va="bottom", ha="center",
                fontsize=8, color=c)
        ax.plot(f, 0.72, marker="v" if not inside else "o", color=c, ms=6)

    # Nyquist 경계
    ax.axvline(nyq_video, color="#1f77b4", lw=1.6)
    ax.text(nyq_video+3, -0.55, "영상 Nyquist 120 Hz\n(이 위쪽은 영상 불가)",
            fontsize=8, color="#1f77b4", va="center")

    ax.set_yticks([0, 1]); ax.set_yticklabels(["240fps 영상", "오디오"])
    ax.set_xlabel("실시간 주파수 [Hz]")
    ax.set_title("결함주파수 커버리지: 오디오는 BPFO·고조파까지, 240fps 영상은 120Hz까지만\n"
                 "(▼ = 영상으로 잡을 수 없는 결함주파수)")
    ax.set_xlim(0, 320); ax.set_ylim(-0.8, 2.3)
    ax.legend(fontsize=8, loc="upper right")
    ax.grid(axis="x", alpha=0.25)
    fig.tight_layout()
    p = os.path.join(OUT, "freq_coverage_audio_vs_video.png")
    fig.savefig(p, dpi=150); plt.close(fig)
    return p


def fig3_table(bf, rpm, balls, ball_d, pitch_d):
    """6204 이론 결함주파수 표 그림."""
    nyq_video = 120.0
    rows = [
        ("회전주파수 fr", bf["fr"], "1×"),
        ("FTF (보지기)", bf["FTF"], "%.3f× fr" % (bf["FTF"]/bf["fr"])),
        ("BSF (전동체)", bf["BSF"], "%.3f× fr" % (bf["BSF"]/bf["fr"])),
        ("BPFO (외륜)", bf["BPFO"], "%.3f× fr" % (bf["BPFO"]/bf["fr"])),
        ("BPFI (내륜)", bf["BPFI"], "%.3f× fr" % (bf["BPFI"]/bf["fr"])),
    ]
    cell, colors = [], []
    for name, f, mult in rows:
        cov = "O" if f <= nyq_video else "X (영상 불가)"
        cell.append([name, f"{f:.1f}", mult, cov])
        colors.append(["white", "white", "white",
                       "#d6f5d6" if f <= nyq_video else "#f9d6d6"])

    fig, ax = plt.subplots(figsize=(8.2, 3.4))
    ax.axis("off")
    tbl = ax.table(cellText=cell,
                   colLabels=["결함주파수", "값 [Hz]", "배수", "240fps 영상 커버"],
                   cellColours=colors, cellLoc="center", loc="center")
    tbl.auto_set_font_size(False); tbl.set_fontsize(10); tbl.scale(1, 1.6)
    for j in range(4):
        tbl[0, j].set_facecolor("#40466e")
        tbl[0, j].set_text_props(color="white", fontweight="bold")
    ax.set_title(f"6204 베어링 이론 결함주파수  "
                 f"(n={balls}, d={ball_d}mm, D={pitch_d}mm, {rpm:.0f} rpm)\n"
                 f"기본파는 120Hz 이내지만, 진단에 필요한 고조파(2×↑)는 영상 불가 — 오디오는 전대역 커버",
                 fontsize=10.5, pad=14)
    fig.tight_layout()
    p = os.path.join(OUT, "bearing_fault_freq_table.png")
    fig.savefig(p, dpi=150, bbox_inches="tight"); plt.close(fig)
    return p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("--rpm", type=float, default=1200)
    ap.add_argument("--record-fps", type=float, default=240)
    ap.add_argument("--balls", type=int, default=8)
    ap.add_argument("--ball-d", type=float, default=7.94)
    ap.add_argument("--pitch-d", type=float, default=33.5)
    a = ap.parse_args()

    label = os.path.basename(a.video)
    x, fs = load_audio(a.video)
    export_fps = get_video_fps(a.video) or a.record_fps
    stretch = a.record_fps / export_fps
    bf = bearing_freqs(a.rpm, a.balls, a.ball_d, a.pitch_d)

    p1, f0 = fig1_envelope(x, fs, stretch, bf, label)
    p2 = fig2_coverage(bf)
    p3 = fig3_table(bf, a.rpm, a.balls, a.ball_d, a.pitch_d)

    print(f"export_fps={export_fps:.2f}  stretch={stretch:.3f}")
    print(f"검출 기본파 {f0:.2f}Hz → 복원 {f0*stretch:.1f}Hz (이론 BPFO {bf['BPFO']:.1f}Hz)")
    for p in (p1, p2, p3):
        print("saved:", os.path.relpath(p))


if __name__ == "__main__":
    main()
