import os
from PIL import Image

base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"
download_dir = r"C:\Users\Samvel\Downloads"

# List of all source screenshots (First is lockscreen widget, followed by app screens)
src_files = [
    (os.path.join(base_dir, "screenshots", "01_lockscreen_widget.png"), "01_lockscreen_widget_ipad13.png"),
    (os.path.join(download_dir, "IMG_2030.PNG"), "02_reading_ipad13.png"),
    (os.path.join(download_dir, "IMG_2031.PNG"), "03_narekatsi_ipad13.png"),
    (os.path.join(download_dir, "IMG_2032.PNG"), "04_ai_guide_ipad13.png"),
    (os.path.join(download_dir, "IMG_2033.PNG"), "05_quiz_ipad13.png"),
    (os.path.join(download_dir, "IMG_2034.PNG"), "06_postcards_ipad13.png"),
    (os.path.join(download_dir, "IMG_2265.PNG"), "07_settings_ipad13.png"),
    (os.path.join(download_dir, "IMG_2266.PNG"), "08_favorites_ipad13.png"),
    (os.path.join(download_dir, "IMG_2267.PNG"), "09_library_ipad13.png"),
    (os.path.join(download_dir, "IMG_2268.PNG"), "10_audio_player_ipad13.png"),
]

# Target iPad 13" resolution: 2048 x 2732 (Portrait)
target_w, target_h = 2048, 2732
target_ratio = target_w / target_h

out_dirs = [
    os.path.join(base_dir, "screenshots", "ipad_13"),
    os.path.join(base_dir, "fastlane", "screenshots", "ipad_13"),
    os.path.join(base_dir, "fastlane", "screenshots", "en-US", "ipad_13"),
    os.path.join(base_dir, "fastlane", "screenshots", "hy", "ipad_13"),
    os.path.join(base_dir, "fastlane", "screenshots", "ru", "ipad_13"),
]

for d in out_dirs:
    os.makedirs(d, exist_ok=True)

converted_count = 0

for src_path, out_name in src_files:
    if not os.path.exists(src_path):
        print(f"Skipping missing: {src_path}")
        continue
        
    img = Image.open(src_path)
    
    # Ensure RGB
    if img.mode != 'RGB':
        img = img.convert('RGB')
        
    src_w, src_h = img.size
    src_ratio = src_w / src_h
    
    if src_ratio > target_ratio:
        new_h = target_h
        new_w = int(src_w * (target_h / src_h))
    else:
        new_w = target_w
        new_h = int(src_h * (target_w / src_w))
        
    resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    cropped = resized.crop((left, top, left + target_w, top + target_h))
    
    # Save to all target folders
    for d in out_dirs:
        out_full = os.path.join(d, out_name)
        cropped.save(out_full, "PNG", quality=100)
        
    converted_count += 1
    print(f"Converted {out_name} -> {cropped.size}, RGB")

print(f"Successfully converted {converted_count} screenshots for iPad 13-inch!")
