#!/bin/bash
# Installs the freshly built APK in the CI emulator and plays every song (see sourceJon/SmokeTest.hx).
# After a crash the app is started again and carries on with the next song, so one run reports all crashes.
PK=com.ninjamuffin99.funkin
APK=$(ls exportJon/*/android/bin/app/build/outputs/apk/debug/*.apk | head -1)
echo "Installing $APK"
adb install -r "$APK" || { echo "::error::adb install failed"; exit 0; }
adb shell setprop debug.bob.smoketest 1
echo "test property: $(adb shell getprop debug.bob.smoketest)"
adb shell wm size

REPORT=""
FINISHED=0
for run in $(seq 1 14); do
  adb shell am force-stop $PK
  adb logcat -c
  adb shell monkey -p $PK -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
  STATE=timeout
  for t in $(seq 1 90); do
    sleep 3
    # taps skip dialogue boxes
    adb shell input tap 540 960 > /dev/null 2>&1
    adb shell input tap 960 540 > /dev/null 2>&1
    adb logcat -d > "run$run.log"
    if grep -q "SMOKE DONE" "run$run.log"; then STATE=done; break; fi
    if [ -z "$(adb shell pidof $PK | tr -d '\r')" ]; then STATE=died; break; fi
  done
  LAST=$(grep -E "SMOKE (START|OK|DONE)" "run$run.log" | sed 's/.*trace *: *//' | tr '\n' ' ')
  echo "run $run: $STATE :: $LAST"
  REPORT="$REPORT run$run[$STATE]: $LAST ||"
  if [ "$STATE" != "done" ]; then
    DETAIL=$(grep -E "Null Object|Fatal signal|Cause:|Error|Exception|Called from" "run$run.log" | grep -v -E "EGL|OpenGLRenderer|ActivityManager|System.err|BstGCall" | cut -c1-230 | tail -n 14 | tr '\n' '|')
    echo "::error::RUN $run $STATE LAST=$LAST DETAIL=$DETAIL"
  fi
  if [ "$STATE" = "done" ]; then FINISHED=1; break; fi
done
echo "::error::SMOKE REPORT finished=$FINISHED $REPORT"
exit 0
