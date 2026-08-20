import os
import sys
import io
from mutagen.mp3 import MP3

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

downloads_dir = r"C:\Users\Samvel\Downloads"
mp3_files = [os.path.join(downloads_dir, f) for f in os.listdir(downloads_dir) if f.endswith('.mp3')]

for f in mp3_files:
    try:
        audio = MP3(f)
        duration_sec = audio.info.length
        bitrate = audio.info.bitrate
        sample_rate = audio.info.sample_rate
        print(f"File: {os.path.basename(f)}")
        print(f"Duration: {duration_sec:.2f} seconds ({duration_sec / 60:.2f} minutes)")
        print(f"Bitrate: {bitrate / 1000:.0f} kbps")
        print(f"Sample Rate: {sample_rate} Hz")
    except Exception as e:
        print(f"Error reading {f}: {e}")
