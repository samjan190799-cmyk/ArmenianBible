import os
from PIL import Image

src_path = r"C:\Users\Samvel\.gemini\antigravity-ide\brain\354b730e-aa9d-4ed9-ba70-9143b8afe786\.user_uploaded\media_1787131476004.png"
base_dir = r"c:\Users\Samvel\.gemini\antigravity-ide\scratch\ArmenianBibleLockScreen.ios"

# App Store & Play Store required sizes (width, height)
# All screenshots must be RGB (24-bit, no alpha) for App Store Connect compliance
sizes = {
    "6.9": (1320, 2868), # iPhone 16 Pro Max
    "6.7": (1290, 2796), # iPhone 15 Pro Max / 14 Pro Max
    "6.5": (1242, 2688), # iPhone 11 Pro Max / XS Max
    "6.1": (1179, 2556), # iPhone 16 Pro / 15 Pro / 14 Pro
    "5.5": (1242, 2208), # iPhone 8 Plus
    "android": (1080, 2400) # Google Play Phone
}

# Open source image
img = Image.open(src_path)

# Convert to RGB (removing alpha channel to prevent App Store rejection ITMS-90717)
if img.mode != 'RGB':
    background = Image.new("RGB", img.size, (0, 0, 0))
    if img.mode == 'RGBA':
        background.paste(img, mask=img.split()[3])
    else:
        background.paste(img)
    img_rgb = background
else:
    img_rgb = img

def resize_and_fit(image, target_w, target_h):
    src_w, src_h = image.size
    src_ratio = src_w / src_h
    target_ratio = target_w / target_h
    
    if abs(src_ratio - target_ratio) < 0.05:
        return image.resize((target_w, target_h), Image.Resampling.LANCZOS)
    else:
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

out_dirs = [
    os.path.join(base_dir, "fastlane", "screenshots", "en-US"),
    os.path.join(base_dir, "fastlane", "screenshots", "hy"),
    os.path.join(base_dir, "fastlane", "screenshots", "ru"),
    os.path.join(base_dir, "fastlane", "screenshots"),
    os.path.join(base_dir, "screenshots"),
    os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", "en-US", "images", "phoneScreenshots"),
    os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", "hy-AM", "images", "phoneScreenshots"),
    os.path.join(base_dir, "android_app", "fastlane", "metadata", "android", "ru-RU", "images", "phoneScreenshots"),
]

for d in out_dirs:
    os.makedirs(d, exist_ok=True)

main_67 = resize_and_fit(img_rgb, 1290, 2796)

for d in out_dirs:
    main_67.save(os.path.join(d, "01_lockscreen_widget.png"), "PNG", quality=100)

main_67.save(os.path.join(base_dir, "screenshots", "01_lockscreen_widget.png"), "PNG", quality=100)

for label, (w, h) in sizes.items():
    resized_img = resize_and_fit(img_rgb, w, h)
    for loc in ["en-US", "hy", "ru"]:
        loc_dir = os.path.join(base_dir, "fastlane", "screenshots", loc)
        resized_img.save(os.path.join(loc_dir, f"01_lockscreen_widget_{label}.png"), "PNG", quality=100)
    resized_img.save(os.path.join(base_dir, "fastlane", "screenshots", f"01_lockscreen_widget_{label}.png"), "PNG", quality=100)

print("✅ All screenshots successfully created and formatted!")
