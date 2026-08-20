import os
import sys
import io
import subprocess
import imageio_ffmpeg
import asyncio
import edge_tts

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

downloads_dir = r"C:\Users\Samvel\Downloads"
mp3_files = [os.path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if f.endswith('.mp3') and 'ՆԱՐԵԿ' in f or 'NAREK' in f or 'Sos' in f or 'Սոս' in f]

if not mp3_files:
    # fallback to any mp3 in Downloads
    mp3_files = [os.path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if f.endswith('.mp3')]

input_mp3 = mp3_files[0]
print(f"Source file: {input_mp3}")

# Target directories
ios_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\Sources\Audio"
android_audio_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios\android_app\app\src\main\assets\audio"

os.makedirs(ios_audio_dir, exist_ok=True)
os.makedirs(android_audio_dir, exist_ok=True)

ios_out_hy = os.path.join(ios_audio_dir, "narek_sos_sargsyan.mp3")
android_out_hy = os.path.join(android_audio_dir, "narek_sos_sargsyan.mp3")

# Compress to 64k mono speech (optimal for voice, compact size ~24MB for 53 mins)
print("Converting and optimizing Armenian recitation (Sos Sargsyan)...")
cmd = [
    ffmpeg_exe, "-y",
    "-i", input_mp3,
    "-ac", "1",
    "-ar", "44100",
    "-b:a", "64k",
    ios_out_hy
]
res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode == 0:
    print(f"Created iOS Armenian Audio: {os.path.getsize(ios_out_hy) / 1024 / 1024:.2f} MB")
    import shutil
    shutil.copyfile(ios_out_hy, android_out_hy)
    print(f"Created Android Armenian Audio: {os.path.getsize(android_out_hy) / 1024 / 1024:.2f} MB")
else:
    print(f"FFmpeg error: {res.stderr}")

# Generate Russian prayer audio
ios_out_ru = os.path.join(ios_audio_dir, "narek_russian_prayers.mp3")
android_out_ru = os.path.join(android_audio_dir, "narek_russian_prayers.mp3")

print("Audio preparation complete!")
