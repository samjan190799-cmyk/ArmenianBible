import os
import sys
import io
import subprocess
import shutil
import imageio_ffmpeg

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
downloads_dir = r"C:\Users\Samvel\Downloads"
files = [os.path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if 'Моленко' in f or 'скорбных' in f]

if not files:
    print("Error: Russian audio file not found in Downloads!")
    sys.exit(1)

input_file = files[0]
print(f"Processing Russian Audio: {os.path.basename(input_file)}")

ios_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\Sources\Audio"
android_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\android_app\app\src\main\assets\audio"

os.makedirs(ios_audio_dir, exist_ok=True)
os.makedirs(android_audio_dir, exist_ok=True)

ios_out = os.path.join(ios_audio_dir, "narek_oleg_molenko.mp3")
android_out = os.path.join(android_audio_dir, "narek_oleg_molenko.mp3")

# Also write to narek_russian_prayers.mp3
ios_out_ru = os.path.join(ios_audio_dir, "narek_russian_prayers.mp3")
android_out_ru = os.path.join(android_audio_dir, "narek_russian_prayers.mp3")

cmd = [
    ffmpeg_exe, "-y",
    "-i", input_file,
    "-ac", "1",
    "-ar", "44100",
    "-b:a", "64k",
    ios_out
]

print("Compressing and converting Russian audio to 64k mono...")
res = subprocess.run(cmd, capture_output=True, text=True)

if res.returncode == 0:
    size_mb = os.path.getsize(ios_out) / 1024 / 1024
    print(f"Created iOS Russian Audio: {size_mb:.2f} MB")
    shutil.copyfile(ios_out, android_out)
    shutil.copyfile(ios_out, ios_out_ru)
    shutil.copyfile(ios_out, android_out_ru)
    print("Copied to Android assets and aliases successfully!")
else:
    print(f"FFmpeg error: {res.stderr}")
    sys.exit(1)

# Detect pause markers in Russian audio
print("Detecting chapter pauses in Russian audio...")
cmd_detect = [
    ffmpeg_exe,
    "-i", ios_out,
    "-af", "silencedetect=noise=-28dB:d=0.9",
    "-f", "null",
    "-"
]
proc = subprocess.run(cmd_detect, capture_output=True, text=True)
silences = []
for line in proc.stderr.split('\n'):
    if 'silence_end' in line:
        parts = line.split('silence_end: ')
        if len(parts) > 1:
            end_time = float(parts[1].split(' |')[0])
            silences.append(end_time)

print(f"Detected {len(silences)} pauses in Russian recitation.")
for idx, s in enumerate(silences[:20]):
    mins = int(s) // 60
    secs = int(s) % 60
    print(f"Chapter {idx+1}: {mins:02d}:{secs:02d} ({s:.1f}s)")
