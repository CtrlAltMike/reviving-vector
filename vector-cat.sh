#!/bin/bash
# Vector Be a Cat — Vector searches for an object, stalks it, pushes it off the table, and meows.

SERIAL="${VECTOR_SERIAL:?Set VECTOR_SERIAL to your Vector ESN}"
WIREPOD="${WIREPOD_URL:-http://localhost:8080}"

unset CLAUDECODE

# Helper: URL-encode text
urlencode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

# Helper: play animation via Lua and wait for it
play_anim() {
    local anim="$1"
    local wait_ms="${2:-2000}"
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nplayAnimation('${anim}')\nsleep(${wait_ms})\"}" >/dev/null 2>&1
}

# Helper: make Vector speak and wait
say() {
    local text="$1"
    local wait_secs="${2:-3}"
    local encoded
    encoded=$(urlencode "$text")
    curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}&priority=high" -d "" >/dev/null 2>&1
    curl -s "${WIREPOD}/api-sdk/say_text?serial=${SERIAL}&text=${encoded}" -d "" >/dev/null 2>&1
    sleep "$wait_secs"
}

# Helper: gentle nudge forward via Lua (slow approach, low arm)
gentle_push() {
    curl -s "${WIREPOD}/api-lua/run_script" \
        -H "Content-Type: application/json" \
        -d "{\"esn\":\"${SERIAL}\",\"script\":\"assumeBehaviorControl(10)\nmoveLift(-50)\nsleep(500)\nmoveWheels(40, 40, 0, 0)\nsleep(2000)\nmoveWheels(0, 0, 0, 0)\nsleep(300)\"}" >/dev/null 2>&1
}

# Initialize SDK connection
curl -s "${WIREPOD}/api-sdk/conn_test?serial=${SERIAL}" -d "" >/dev/null 2>&1

echo "[1/5] Searching..."

# Beat 1: Look around — scanning the table
play_anim "anim_explorer_lookaround_01" 3000

echo "[2/5] Target acquired..."

# Beat 2: Spot the object
play_anim "anim_pounce_reacttoobj_01_shorter" 2000

echo "[3/5] Stalking..."

# Beat 3: Cat-like focus, then approach
play_anim "anim_pounce_lookloop_01" 2000
play_anim "anim_cubedocking_drive_loop_01" 2000

echo "[4/5] Pushing..."

# Beat 4: Gentle nudge — lower arm and slowly drive forward
gentle_push
play_anim "anim_reacttoblock_lifteffortroll_01" 2000

# Beat 5: Satisfaction
echo "[5/5] Meow."
play_anim "anim_petdetection_reaction_cat_01" 2000
say "Meow." 2

curl -s "${WIREPOD}/api-sdk/release_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1

echo ""
echo "Done!"
