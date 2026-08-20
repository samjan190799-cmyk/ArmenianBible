import os
import sys
import io
import imageio_ffmpeg
import subprocess
import json

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
audio_file = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\Sources\Audio\narek_sos_sargsyan.mp3"

# Run silencedetect to find pauses between chapters
cmd = [
    ffmpeg_exe,
    "-i", audio_file,
    "-af", "silencedetect=noise=-30dB:d=1.5",
    "-f", "null",
    "-"
]

proc = subprocess.run(cmd, capture_output=True, text=True)
silences = []
for line in proc.stderr.split('\n'):
    if 'silencedetect' in line and 'silence_end' in line:
        # e.g. [silencedetect @ 000001] silence_end: 124.5 | silence_duration: 2.1
        parts = line.split('silence_end: ')
        if len(parts) > 1:
            end_time = float(parts[1].split(' |')[0])
            silences.append(end_time)

print(f"Found {len(silences)} pause transitions in the audio:")
for idx, s in enumerate(silences[:30]):
    mins = int(s) // 60
    secs = int(s) % 60
    print(f"Chapter {idx+1}: {mins:02d}:{secs:02d} ({s:.1f}s)")
