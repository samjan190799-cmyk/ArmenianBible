#!/usr/bin/env bash
# Автотест в эмуляторе: ставит APK, запускает приложение, листает четыре вкладки, снимает экраны и ищет сбои.
set -x
PKG=com.example.armenianbible
mkdir -p smoke

adb install -r apk/app-release.apk
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS || true
adb logcat -c

adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 14
adb exec-out screencap -p > smoke/01_home.png

SIZE=$(adb shell wm size | tail -1 | sed 's/.*: //' | tr -d '\r')
W=${SIZE%x*}
H=${SIZE#*x}
# нижняя панель: четыре вкладки поровну, центры на 12,5 / 37,5 / 62,5 / 87,5 % ширины
tab() {
  adb shell input tap $(( W * $1 / 1000 )) $(( H * 955 / 1000 ))
  sleep 5
}
tab 375; adb exec-out screencap -p > smoke/02_favorites.png
tab 625; adb exec-out screencap -p > smoke/03_ai.png
tab 875; adb exec-out screencap -p > smoke/04_bible.png
tab 125; adb exec-out screencap -p > smoke/05_home_again.png

adb logcat -d > smoke/logcat_full.txt
grep -E "FATAL EXCEPTION|AndroidRuntime" smoke/logcat_full.txt > smoke/crashes.txt || true
echo "строк сбоев: $(wc -l < smoke/crashes.txt)"
adb shell dumpsys package "$PKG" | grep -E "versionName|versionCode" > smoke/version.txt || true
