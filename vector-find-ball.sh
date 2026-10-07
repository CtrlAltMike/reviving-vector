#!/bin/bash
# Vector Find the Ball — Vector spins and searches for a tennis ball using Claude vision.

SERIAL="${VECTOR_SERIAL:?Set VECTOR_SERIAL to your Vector ESN}"
WIREPOD="${WIREPOD_URL:-http://localhost:8080}"
FRAME="/tmp/vector_frame.jpg"
MAX_TURNS=12
MAX_APPROACH=5

unset CLAUDECODE

# Helper: URL-encode text
urlencode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

# Helper: play animation via Lua
play_anim() {
    local anim="$1"
    local wait_ms="${2:-2000}"
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nplayAnimation('${anim}')\nsleep(${wait_ms})\"}" >/dev/null 2>&1
}

# Helper: make Vector speak
say() {
    local text="$1"
    local wait_secs="${2:-3}"
    local encoded
    encoded=$(urlencode "$text")
    curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}&priority=high" -d "" >/dev/null 2>&1
    curl -s "${WIREPOD}/api-sdk/say_text?serial=${SERIAL}&text=${encoded}" -d "" >/dev/null 2>&1
    sleep "$wait_secs"
}

# Helper: turn Vector via Lua
turn() {
    local left_speed="$1"
    local right_speed="$2"
    local duration_ms="${3:-600}"
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nmoveWheels(${left_speed}, ${right_speed}, 0, 0)\nsleep(${duration_ms})\nmoveWheels(0, 0, 0, 0)\nsleep(200)\"}" >/dev/null 2>&1
}

# Helper: drive forward (arm stays down so camera stays level)
drive_forward() {
    local duration_ms="${1:-800}"
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nmoveWheels(50, 50, 0, 0)\nsleep(${duration_ms})\nmoveWheels(0, 0, 0, 0)\nsleep(200)\"}" >/dev/null 2>&1
}

# Helper: capture a single frame
capture_frame() {
    rm -f "$FRAME"
    python3 -c "
import urllib.request, sys, socket
SERIAL = '${SERIAL}'
BASE = '${WIREPOD}'
def grab_frame(timeout):
    resp = urllib.request.urlopen(urllib.request.Request(
        f'{BASE}/cam-stream?serial={SERIAL}'), timeout=timeout)
    buf = b''
    started = False
    for i in range(2000):
        chunk = resp.read(4096)
        if not chunk: break
        buf += chunk
        if b'\xff\xd8' in buf and not started:
            buf = buf[buf.index(b'\xff\xd8'):]
            started = True
        if started and b'\xff\xd9' in buf:
            end = buf.index(b'\xff\xd9') + 2
            with open('${FRAME}', 'wb') as f:
                f.write(buf[:end])
            return True
    return False
for attempt in range(2):
    try:
        if grab_frame(15):
            sys.exit(0)
    except (socket.timeout, urllib.error.URLError):
        pass
    if attempt == 0:
        try:
            r = urllib.request.urlopen(urllib.request.Request(
                f'{BASE}/cam-stream?serial={SERIAL}'), timeout=5)
            r.read(4096)
            r.close()
        except: pass
        import time; time.sleep(2)
sys.exit(1)
" 2>/dev/null
    [ -f "$FRAME" ]
}

# Helper: ask Claude where the ball is (returns LEFT, RIGHT, CENTER, CLOSE, or NO)
check_ball() {
    claude -p "Read the image file at ${FRAME}. Is there a tennis ball visible? If yes, how big is it relative to the frame?
Reply with ONLY one word:
- NO (not visible)
- LEFT (visible, left side of frame)
- RIGHT (visible, right side of frame)
- CENTER (visible, center of frame, small or medium size)
- CLOSE (visible, center of frame, very large — takes up most of the frame)" \
        --allowedTools "Read" \
        --max-turns 2 \
        --model haiku 2>&1 | tr '[:lower:]' '[:upper:]' | grep -o -E 'CLOSE|LEFT|RIGHT|CENTER|NO' | head -1
}

# Initialize SDK connection
curl -s "${WIREPOD}/api-sdk/conn_test?serial=${SERIAL}" -d "" >/dev/null 2>&1

# Check if on charger and drive off
echo "Checking charger status..."
BATTERY_JSON=$(curl -s -m 10 "${WIREPOD}/api-sdk/get_battery?serial=${SERIAL}" -d "" 2>&1)
ON_CHARGER=$(echo "$BATTERY_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('is_on_charger_platform',False) or d.get('is_charging',False) else 'no')" 2>/dev/null)

if [ "$ON_CHARGER" = "yes" ]; then
    echo "On charger — driving off..."
    play_anim "anim_chargerdocking_comeoff_straight_01" 3000
fi

curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}&priority=high" -d "" >/dev/null 2>&1

echo "Searching for tennis ball..."
say "Where is that tennis ball?" 3

FOUND=false

# Phase 1: Scan — turn and look for the ball
for i in $(seq 1 $MAX_TURNS); do
    echo -n "  Scan $i: "

    if ! capture_frame; then
        echo "capture failed, retrying..."
        sleep 1
        continue
    fi

    DIRECTION=$(check_ball)
    echo "$DIRECTION"

    case "$DIRECTION" in
        CLOSE)
            FOUND=true
            break
            ;;
        CENTER)
            # Spotted it — switch to approach phase
            echo "  Ball spotted, approaching..."
            FOUND=true
            break
            ;;
        LEFT)
            turn -30 30 400
            ;;
        RIGHT)
            turn 30 -30 400
            ;;
        NO|"")
            # ~30 degrees per scan
            turn 50 -50 400
            ;;
    esac
done

# Phase 2: Approach — drive toward the ball with course corrections
if $FOUND && [ "$DIRECTION" != "CLOSE" ]; then
    for j in $(seq 1 $MAX_APPROACH); do
        echo -n "  Approach $j: "

        # Drive forward a bit (arm down, camera level)
        drive_forward 800

        # Check again
        if ! capture_frame; then
            echo "capture failed"
            continue
        fi

        DIRECTION=$(check_ball)
        echo "$DIRECTION"

        case "$DIRECTION" in
            CLOSE)
                # We're there
                break
                ;;
            LEFT)
                turn -20 20 300
                ;;
            RIGHT)
                turn 20 -20 300
                ;;
            CENTER)
                # Keep going
                ;;
            NO|"")
                # Lost it — stop
                echo "  Lost the ball!"
                FOUND=false
                break
                ;;
        esac
    done
fi

curl -s "${WIREPOD}/api-sdk/release_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1

if $FOUND; then
    echo "Touching the ball!"
    # Arm up, nudge forward into the ball
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nmoveLift(100)\nsleep(800)\nmoveWheels(40, 40, 0, 0)\nsleep(800)\nmoveWheels(0, 0, 0, 0)\nsleep(300)\"}" >/dev/null 2>&1
    play_anim "anim_pounce_success_03" 2000
    say "Got it!" 2
else
    echo "Couldn't find the ball."
    play_anim "anim_knowledgegraph_fail_01" 2000
    say "I can't find the tennis ball anywhere." 3
fi

curl -s "${WIREPOD}/api-sdk/release_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1

echo "Done!"
