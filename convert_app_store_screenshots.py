import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image

brain_media_dir = r"C:\Users\Samvel\.gemini\antigravity-ide\brain\f16ae294-d918-44ac-bd8e-351e87603c29\.user_uploaded"
base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

screenshots_map = [
    ("media_1787950669457.png", "01_lockscreen_widget"),
    ("media_1787950674272.png", "02_home_daily_verse"),
    ("media_1787950677367.png", "03_favorites_highlights"),
    ("media_1787950686798.png", "04_spiritual_ai_assistant"),
    ("media_1787950690641.png", "05_bible_reader"),
    ("media_1787950737485.png", "06_narekatsi_audio_ru"),
    ("media_1787950737518.png", "07_narekatsi_audio_hy"),
    ("media_1787950737547.png", "08_narekatsi_text"),
    ("media_1787950737555.png", "09_bible_library_books"),
]

# Sizes for App Store Connect (width, height)
sizes = {
    "iphone_6.9": (1320, 2868), # iPhone 16 Pro Max
    "iphone_6.7": (1290, 2796), # iPhone 15/14 Pro Max
    "iphone_6.5": (1242, 2688), # iPhone 11 Pro Max / XS Max
    "iphone_6.1": (1179, 2556), # iPhone 16 Pro / 15 Pro
    "iphone_5.5": (1242, 2208), # iPhone 8 Plus
    "ipad_13": (2048, 2732),    # iPad Pro 13" / 12.9"
}

def clean_rgb(image):
    if image.mode != 'RGB':
        background = Image.new("RGB", image.size, (15, 17, 26)) # Dark theme background
        if image.mode == 'RGBA':
            background.paste(image, mask=image.split()[3])
        else:
            background.paste(image)
        return background
    return image

def resize_and_fit(image, target_w, target_h):
    src_w, src_h = image.size
    src_ratio = src_w / src_h
    target_ratio = target_w / target_h
    
    if abs(src_ratio - target_ratio) < 0.01:
        return image.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    if src_ratio > target_ratio:
        new_h = target_h
        new_w = int(src_w * (target_h / src_h))
    else:
        new_w = target_w
        new_h = int(src_h * (target_w / src_w))
        
    resized = image.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))

# Destination folders
base_screenshots_dir = os.path.join(base_dir, "screenshots")
fastlane_dir = os.path.join(base_dir, "fastlane", "screenshots")

locales = ["en-US", "hy", "ru"]

# Create all folders
for sz in sizes.keys():
    os.makedirs(os.path.join(base_screenshots_dir, sz), exist_ok=True)
    os.makedirs(os.path.join(fastlane_dir, sz), exist_ok=True)
    for loc in locales:
        os.makedirs(os.path.join(fastlane_dir, loc, sz), exist_ok=True)

processed_count = 0

for file_name, out_base in screenshots_map:
    src_path = os.path.join(brain_media_dir, file_name)
    if not os.path.exists(src_path):
        print(f"❌ Not found: {src_path}")
        continue
    
    with Image.open(src_path) as raw_img:
        rgb_img = clean_rgb(raw_img)
        
        # Save standard 6.7" to root screenshots & fastlane
        img_67 = resize_and_fit(rgb_img, 1290, 2796)
        img_67.save(os.path.join(base_screenshots_dir, f"{out_base}.png"), "PNG", quality=100)
        img_67.save(os.path.join(fastlane_dir, f"{out_base}.png"), "PNG", quality=100)
        for loc in locales:
            os.makedirs(os.path.join(fastlane_dir, loc), exist_ok=True)
            img_67.save(os.path.join(fastlane_dir, loc, f"{out_base}.png"), "PNG", quality=100)
        
        # Save each specific size
        for sz_name, (tw, th) in sizes.items():
            fitted = resize_and_fit(rgb_img, tw, th)
            # base/screenshots/<sz>/
            fitted.save(os.path.join(base_screenshots_dir, sz_name, f"{out_base}.png"), "PNG", quality=100)
            # fastlane/screenshots/<sz>/
            fitted.save(os.path.join(fastlane_dir, sz_name, f"{out_base}.png"), "PNG", quality=100)
            # fastlane/screenshots/<loc>/<sz>/
            for loc in locales:
                fitted.save(os.path.join(fastlane_dir, loc, sz_name, f"{out_base}.png"), "PNG", quality=100)
                
        processed_count += 1
        print(f"✅ Converted {out_base} for all iPhone and iPad resolutions")

print(f"\n🎉 Successfully converted all {processed_count} screenshots for App Store Connect!")
