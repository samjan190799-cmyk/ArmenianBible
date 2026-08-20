import yt_dlp
import json
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

ydl_opts = {
    'quiet': True,
    'extract_flat': True
}

queries = [
    'Grigor Narekatsi Sos Sargsyan',
    'Գրիգոր Նարեկացի Սոս Սարգսյան Բան',
    'Григор Нарекаци Книга скорбных песнопений Моленко'
]

with yt_dlp.YoutubeDL(ydl_opts) as ydl:
    for q in queries:
        print(f"=== Query: {q} ===")
        res = ydl.extract_info(f"ytsearch10:{q}", download=False)
        for e in res.get('entries', []):
            print(f"ID: {e.get('id')} | Title: {e.get('title')} | Duration: {e.get('duration')}s")
