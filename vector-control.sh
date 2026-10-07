#!/bin/bash
# Vector Control — quick commands for Vector
# Usage: ./vector-control.sh <command> [args]

SERIAL="${VECTOR_SERIAL:?Set VECTOR_SERIAL to your Vector ESN}"
WIREPOD="${WIREPOD_URL:-http://localhost:8080}"

sdk() {
    curl -s --max-time 15 "${WIREPOD}/api-sdk/${1}?serial=${SERIAL}${2}" -d "" 2>/dev/null
}

case "${1}" in
    up|volume-up)
        sdk "cloud_intent" "&intent=intent_imperative_volumeup"
        echo "Volume up"
        ;;
    down|volume-down)
        sdk "cloud_intent" "&intent=intent_imperative_volumedown"
        echo "Volume down"
        ;;
    mute)
        sdk "assume_behavior_control" "&priority=high"
        sleep 0.5
        sdk "volume" "&volume=0"
        sdk "release_behavior_control"
        echo "Volume muted"
        ;;
    unmute)
        sdk "assume_behavior_control" "&priority=high"
        sleep 0.5
        sdk "volume" "&volume=3"
        sdk "release_behavior_control"
        echo "Volume restored"
        ;;
    home|go-home)
        # Stop wander script if running
        if [ -f /tmp/vector-wander.pid ]; then
            kill "$(cat /tmp/vector-wander.pid)" 2>/dev/null
            echo "Stopped wander script"
            sleep 2
        fi
        sdk "cloud_intent" "&intent=intent_system_charger"
        echo "Vector heading home to charge"
        ;;
    say)
        shift
        TEXT="$*"
        if [ -z "$TEXT" ]; then
            echo "Usage: ./vector-control.sh say <message>"
            exit 1
        fi
        sdk "assume_behavior_control" "&priority=high"
        ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$TEXT")
        sdk "say_text" "&text=${ENCODED}"
        sleep 5
        sdk "release_behavior_control"
        echo "Said: $TEXT"
        ;;
    battery)
        JSON=$(sdk "get_battery")
        echo "$JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
levels = {1: 'LOW', 2: 'Nominal', 3: 'Full'}
level = d.get('battery_level', 0)
print(f\"Battery: {levels.get(level, 'Unknown')} ({d.get('battery_volts', 0):.2f}V)\")
print(f\"On charger: {d.get('is_on_charger_platform', False)}\")
"
        ;;
    faces)
        JSON=$(sdk "get_faces")
        echo "$JSON" | python3 -c "
import sys, json
faces = json.load(sys.stdin)
if not faces:
    print('Vector doesn\'t know anyone yet.')
else:
    print(f'Vector knows {len(faces)} face(s):')
    for f in faces:
        mins = f.get('seconds_since_last_seen', 0) // 60
        print(f\"  - {f['name']} (last seen {mins} min ago)\")
"
        ;;
    learn)
        NAME="${2}"
        if [ -z "$NAME" ]; then
            echo "Usage: ./vector-control.sh learn <name>"
            echo "Vector will look at the person and learn their face."
            exit 1
        fi
        sdk "assume_behavior_control" "&priority=high"
        sdk "cloud_intent" "&intent=intent_meet_victor"
        sleep 2
        sdk "release_behavior_control"
        echo "Vector is learning ${NAME}'s face — look at him!"
        # The actual enrollment happens via the intent
        sdk "add_face" "&name=${NAME}"
        ;;
    look)
        unset CLAUDECODE
        FRAME="/tmp/vector_frame.jpg"
        rm -f "$FRAME"
        # Capture
        python3 -c "
import urllib.request, sys
url = '${WIREPOD}/cam-stream?serial=${SERIAL}'
try:
    resp = urllib.request.urlopen(urllib.request.Request(url), timeout=15)
    buf = b''
    started = False
    while True:
        chunk = resp.read(4096)
        if not chunk: break
        buf += chunk
        if b'\xff\xd8' in buf and not started:
            buf = buf[buf.index(b'\xff\xd8'):]
            started = True
        if started and b'\xff\xd9' in buf:
            end = buf.index(b'\xff\xd9') + 2
            with open('$FRAME', 'wb') as f:
                f.write(buf[:end])
            break
except: sys.exit(1)
" 2>/dev/null
        if [ ! -f "$FRAME" ]; then
            echo "Couldn't capture frame"
            exit 1
        fi
        RESPONSE=$(claude -p "This image was taken by a small robot's camera. Write a brief, charming first-person remark about what the robot sees. Read the image file at ${FRAME}. Keep it under 300 characters. Output ONLY the spoken remark." \
            --allowedTools "Read" --max-turns 3 --model sonnet 2>&1)
        echo "$RESPONSE"
        sdk "assume_behavior_control" "&priority=high"
        ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$RESPONSE")
        sdk "say_text" "&text=${ENCODED}"
        sleep 5
        sdk "release_behavior_control"
        ;;
    help|"")
        echo "Vector Control Commands:"
        echo "  up / volume-up     Turn volume up"
        echo "  down / volume-down Turn volume down"
        echo "  mute               Mute Vector"
        echo "  unmute             Restore volume"
        echo "  home / go-home     Send Vector to charger"
        echo "  say <text>         Make Vector say something"
        echo "  battery            Check battery status"
        echo "  faces              List known faces"
        echo "  learn <name>       Teach Vector a new face"
        echo "  look               Capture + describe + speak (one-shot)"
        echo "  help               Show this help"
        ;;
    *)
        echo "Unknown command: ${1}"
        echo "Run './vector-control.sh help' for commands"
        exit 1
        ;;
esac
