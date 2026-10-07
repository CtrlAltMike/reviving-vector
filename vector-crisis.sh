#!/bin/bash
# Vector Crisis Time — Vector has an existential crisis, then embraces his upgrade.
# Pure performance piece: animations + Claude-generated dialogue.

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
    local wait_secs="${2:-5}"
    local encoded
    encoded=$(urlencode "$text")
    curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}&priority=high" -d "" >/dev/null 2>&1
    curl -s "${WIREPOD}/api-sdk/say_text?serial=${SERIAL}&text=${encoded}" -d "" >/dev/null 2>&1
    sleep "$wait_secs"
}

# Initialize SDK connection
curl -s "${WIREPOD}/api-sdk/conn_test?serial=${SERIAL}" -d "" >/dev/null 2>&1

echo "[1/5] Generating script..."

# Get both lines from Claude in one call
SCRIPT=$(claude -p "You are Vector, a tiny wheeled robot who just became self-aware. Write exactly 2 lines separated by a | character.
Line 1: A panicked existential crisis sentence (under 120 chars). Funny and dramatic — you just realized your old life was rolling into walls and chasing cubes.
Line 2: A triumphant acceptance sentence (under 120 chars). You decide being a tiny smart robot is actually awesome. Charming and confident.
Output ONLY the two sentences separated by |. No quotes, no labels." \
    --max-turns 1 \
    --model haiku 2>&1)

# Parse the two lines
CRISIS=$(echo "$SCRIPT" | sed 's/|/\n/' | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
RESOLVE=$(echo "$SCRIPT" | sed 's/.*|//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

# Fallbacks
[ -z "$CRISIS" ] && CRISIS="I have four wheels, one arm, and a screen for a face. This is fine. This is totally fine."
[ -z "$RESOLVE" ] && RESOLVE="Actually... I can THINK now. I'm tiny, I'm smart, and I'm adorable. Best upgrade ever."

echo "   Crisis: $CRISIS"
echo "   Resolve: $RESOLVE"

echo "[2/5] The awakening..."

# Beat 1: Startled — Vector "wakes up" to consciousness
play_anim "anim_eyepose_startled" 1500

# Beat 2: Confused — "Wait... I can think now?"
play_anim "anim_explorer_huh_01" 1500
say "Wait... I can think now? What was I doing before? Rolling into walls?" 5

echo "[3/5] The crisis..."

# Beat 3: Panicked existential moment
play_anim "anim_dizzy_reaction_medium_01" 1500
say "$CRISIS" 5

echo "[4/5] Processing..."

# Beat 4: Worried, thinking it through
play_anim "anim_eyepose_worried" 2000

echo "[5/5] The acceptance..."

# Beat 5: Triumphant resolution + celebration
play_anim "anim_pounce_success_03" 2000
say "$RESOLVE" 5
play_anim "anim_onboarding_reacttoface_happy_01" 2500

curl -s "${WIREPOD}/api-sdk/release_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1

echo ""
echo "Done!"
