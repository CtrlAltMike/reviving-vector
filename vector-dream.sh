#!/bin/bash
# Vector Dream Monitor — watches for Vector waking up, speaks a dream, goes back to sleep.
# Uses the lightweight stim-status endpoint (single persistent EventStream)
# instead of opening new gRPC streams per poll.
# Start with: sudo /Users/patsyuser/Downloads/Vector/vector-dream.sh

SERIAL="${VECTOR_SERIAL:?Set VECTOR_SERIAL to your Vector ESN}"
WIREPOD="${WIREPOD_URL:-http://localhost:8080}"
POLL_INTERVAL=5

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
    local wait_secs="${2:-5}"
    local encoded
    encoded=$(urlencode "$text")
    curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}&priority=high" -d "" >/dev/null 2>&1
    curl -s "${WIREPOD}/api-sdk/say_text?serial=${SERIAL}&text=${encoded}" -d "" >/dev/null 2>&1
    sleep "$wait_secs"
}

# Helper: send Vector to sleep
go_to_sleep() {
    curl -s "${WIREPOD}/api-sdk/cloud_intent?serial=${SERIAL}&intent=intent_system_sleep" -d "" >/dev/null 2>&1
}

# Helper: get stimulation value (0 = calm/sleeping, higher = active/awake)
# Uses the persistent event stream — no new gRPC connections per call
get_stim() {
    local result
    result=$(curl -s -m 3 "${WIREPOD}/api-sdk/get_stim_status?serial=${SERIAL}" 2>&1)
    if [ -z "$result" ] || echo "$result" | grep -q "error"; then
        echo "-1"
    else
        echo "$result"
    fi
}

# Helper: get a dream from Claude
get_dream() {
    sudo -u michaelhendrick /Users/michaelhendrick/.local/bin/claude -p \
        "You are Vector, a tiny robot who just half-woke up from a dream. Generate ONE bizarre, absurd, surreal dream sentence that a sleepy robot might mumble. Examples of the tone: 'I dreamed the cubes were filing my taxes in a language made of colors' or 'The charger was a waterslide and all the spoons were cheering.' Keep it under 120 characters. Be creative and different every time. Output ONLY the sentence, no quotes." \
        --max-turns 1 \
        --model haiku 2>&1
}

# Cleanup: stop event stream on exit
cleanup() {
    echo ""
    echo "$(date '+%H:%M:%S') Stopping event stream..."
    curl -s "${WIREPOD}/api-sdk/stop_event_stream?serial=${SERIAL}" -d "" >/dev/null 2>&1
    echo "$(date '+%H:%M:%S') Dream monitor stopped."
    exit 0
}
trap cleanup INT TERM

echo "Vector Dream Monitor started."
echo "Press Ctrl+C to stop."

# Initialize SDK connection
curl -s "${WIREPOD}/api-sdk/conn_test?serial=${SERIAL}" -d "" >/dev/null 2>&1

# Start the persistent event stream (stimulation_info)
curl -s "${WIREPOD}/api-sdk/begin_event_stream?serial=${SERIAL}" -d "" >/dev/null 2>&1
sleep 2

# Stim threshold: below this = sleeping, above = awake
STIM_SLEEP_THRESHOLD=0.15
LAST_DREAM_TIME=0
WAS_SLEEPING=false
CONSECUTIVE_AWAKE=0

# Get initial stim reading
STIM=$(get_stim)
echo "$(date '+%H:%M:%S') Initial stim value: ${STIM}"
if [ "$STIM" = "-1" ]; then
    echo "$(date '+%H:%M:%S') Could not read stim. Will keep trying..."
else
    IS_LOW=$(python3 -c "print('yes' if float('${STIM}') < ${STIM_SLEEP_THRESHOLD} else 'no')" 2>/dev/null)
    if [ "$IS_LOW" = "yes" ]; then
        WAS_SLEEPING=true
        echo "$(date '+%H:%M:%S') Vector appears to be sleeping (stim=${STIM}). Monitoring..."
    else
        echo "$(date '+%H:%M:%S') Vector appears awake (stim=${STIM}). Waiting for sleep cycle..."
    fi
fi

while true; do
    STIM=$(get_stim)

    if [ "$STIM" = "-1" ]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    IS_LOW=$(python3 -c "print('yes' if float('${STIM}') < ${STIM_SLEEP_THRESHOLD} else 'no')" 2>/dev/null)

    if [ "$IS_LOW" = "yes" ]; then
        CONSECUTIVE_AWAKE=0
        if [ "$WAS_SLEEPING" = false ]; then
            echo "$(date '+%H:%M:%S') Vector fell asleep (stim=${STIM})."
        fi
        WAS_SLEEPING=true
    else
        # Require 2 consecutive awake readings to avoid false triggers
        CONSECUTIVE_AWAKE=$((CONSECUTIVE_AWAKE + 1))
        if [ "$WAS_SLEEPING" = true ] && [ "$CONSECUTIVE_AWAKE" -ge 2 ]; then
            NOW=$(date +%s)
            WAS_SLEEPING=false
            CONSECUTIVE_AWAKE=0

            # Don't dream more than once per 2 minutes
            ELAPSED=$((NOW - LAST_DREAM_TIME))
            if [ "$ELAPSED" -lt 120 ]; then
                echo "$(date '+%H:%M:%S') Vector woke up (stim=${STIM}), but too soon since last dream. Skipping."
                sleep "$POLL_INTERVAL"
                continue
            fi

            echo "$(date '+%H:%M:%S') Vector woke up! (stim=${STIM}) Starting dream sequence..."

            # Brief pause — let firmware wake animation finish
            sleep 3

            # Get dream from Claude
            DREAM=$(get_dream)
            DREAM=$(echo "$DREAM" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [ -z "$DREAM" ] && DREAM="I dreamed all the cubes learned to fly and they never came back."

            echo "$(date '+%H:%M:%S') Dream: $DREAM"

            # Speak the dream, then put Vector back to sleep
            ENCODED=$(urlencode "$DREAM")
            curl -s "${WIREPOD}/api-sdk/assume_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1
            sleep 1
            curl -s "${WIREPOD}/api-sdk/say_text?serial=${SERIAL}&text=${ENCODED}" -d "" >/dev/null 2>&1
            sleep 8
            curl -s "${WIREPOD}/api-sdk/release_behavior_control?serial=${SERIAL}" -d "" >/dev/null 2>&1
            go_to_sleep

            echo "$(date '+%H:%M:%S') Dream complete. Vector back to sleep."
            LAST_DREAM_TIME=$(date +%s)
        fi
    fi

    sleep "$POLL_INTERVAL"
done
