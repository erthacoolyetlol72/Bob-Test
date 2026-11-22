#!/bin/bash
# Installs the freshly built APK in the CI emulator, launches it, and reports what the log says.
APK=$(ls exportJon/*/android/bin/app/build/outputs/apk/debug/*.apk | head -1)
echo "Installing $APK"
adb install -r "$APK" || { echo "::error::adb install failed"; exit 0; }
adb logcat -c
adb shell monkey -p com.ninjamuffin99.funkin -c android.intent.category.LAUNCHER 1
sleep 40
adb logcat -d > emu.log
PIDNOW=$(adb shell pidof com.ninjamuffin99.funkin | tr -d '\r')
echo "pid after 40s: [$PIDNOW]"
wc -l emu.log

if [ -z "$PIDNOW" ]; then
  STATE="NOT RUNNING (crashed or exited)"
else
  STATE="STILL RUNNING pid $PIDNOW"
fi

CRASH=$(grep -E "Fatal signal|Cause:|ABI:|#0[0-9] pc|FATAL EXCEPTION|UnsatisfiedLink|java\.lang\.[A-Za-z]*Exception" emu.log | cut -c1-260 | head -14 | tr '\n' '|')
HX=$(grep -i -E "HXCPP|Called from|Null Object|Error:|Segmentation|exception|trace" emu.log | grep -v -i -E "ActivityManager|Choreographer|PackageManager|System.err.*dalvik" | cut -c1-260 | head -30 | tr '\n' '|')
SDL=$(grep -E " SDL |Haxe|haxe|lime|Lime|openfl" emu.log | cut -c1-200 | tail -12 | tr '\n' '|')
echo "::error::EMULATOR $STATE CRASH $CRASH"
echo "::error::HAXE $HX"
echo "::error::SDL $SDL"
exit 0
