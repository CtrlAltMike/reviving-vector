# Vector F1P4 — Quick Reference

## Starting Wire-Pod (required for Vector to function)

```bash
cd /Users/patsyuser/Downloads/Vector/wire-pod
sudo ./chipper/start.sh
```

Keep this terminal open — Wire-Pod must be running for Vector to work.

**Web dashboard:** http://localhost:8080 or `http://<wire-pod-host>:8080`

## Stopping Wire-Pod

Press `Ctrl+C` in the terminal running Wire-Pod.

## Two Modes

Vector operates in two modes:

- **Normal mode** (default) — "Hey Vector" wake word works, voice commands, idle behaviors, face greetings, knowledge questions. This is Vector's everyday state.
- **Wander mode** (on demand) — Claude-powered exploration with vision. Vector drives around, observes, and speaks. Triggered by voice ("Hey Vector, go wander") or script. Auto-returns to Normal mode when timer expires.

## Vector Basics

| Command | How |
|---|---|
| Wake | "Hey Vector!" (wait for blue light, then speak) |
| Sleep | "Hey Vector" → "Go to sleep" |
| Pairing mode | Double-tap the back button |
| Recovery mode | Off charger → hold back button 10s to power off → wait 10s → place on charger while holding button → wait for "anki.com/v" |
| Clear user data | In recovery mode (anki.com/v screen), raise then lower lift arm |

**Note:** The back button is fragile on this unit. Avoid recovery mode if possible.

## Network Info

- Vector IP: `<vector-ip>`
- Wire-Pod server IP: `<wire-pod-host>`
- Wi-Fi: a compatible 2.4 GHz network
- Vector serial: `<vector-esn>`
- Vector ESN: `<vector-esn>`

## Voice Commands

### Built-in

- "Hey Vector" → "I have a question" → ask anything (uses Ollama/phi4-mini)
- "Hey Vector" → "What time is it?"
- "Hey Vector" → "Set a timer for [X] minutes"
- "Hey Vector" → "Come here"
- "Hey Vector" → "Go explore"
- "Hey Vector" → "Fist bump"
- "Hey Vector" → "Take a photo"
- "Hey Vector" → "Go to sleep"
- "Hey Vector" → "What's my name?"
- "Hey Vector" → "My name is [name]"
- "Hey Vector" → "Change your eye color to [color]"
- "Hey Vector" → "Volume up/down"

### Custom Intents (Claude-powered)

These are defined in `wire-pod/chipper/customIntents.json` and require a Wire-Pod restart to update.

**Important:** VOSK speech recognition uses a general recognizer (not grammar-constrained) when Ollama/IntentGraph is enabled. This means it can mishear words — for example, "go wander" may be heard as "go wonder" or "go under". The utterances below include common mishearings. If Vector doesn't understand a phrase, check the Wire-Pod terminal to see what VOSK transcribed, then try a different phrase or add the mishearing to `customIntents.json`.

**Tested and confirmed working:**

| Say | What happens |
|---|---|
| "Hey Vector" → **"Explore the house"** | Explores for 5 minutes with Claude vision, then goes home |
| "Hey Vector" → **"Scan my face"** | Starts face enrollment (see below) |

**Additional trigger phrases (may need VOSK tuning):**

| Say | What happens |
|---|---|
| "Hey Vector" → **"Take a walk"** | 5-minute Claude exploration |
| "Hey Vector" → **"Go on an adventure"** | 5-minute Claude exploration |
| "Hey Vector" → **"Go wander"** | 5-minute Claude exploration (VOSK may mishear) |
| "Hey Vector" → **"Take a long walk"** | 10-minute Claude exploration |
| "Hey Vector" → **"Explore for ten minutes"** | 10-minute Claude exploration |
| "Hey Vector" → **"What do you see?"** | One-shot: captures image, Claude describes it, Vector speaks |
| "Hey Vector" → **"Look around"** | Same — one-shot Claude vision |
| "Hey Vector" → **"Go home"** | Stops wandering, heads to charger, returns to Normal mode |
| "Hey Vector" → **"Go charge"** | Same — return to charger |
| "Hey Vector" → **"Come home"** | Same — return to charger |

**Tip:** When testing new phrases, watch the Wire-Pod terminal for the "Transcribed text:" line. If VOSK consistently mishears a phrase the same way, add that mishearing to the utterances in `customIntents.json` and restart Wire-Pod.

### Face enrollment by voice

1. Say: **"Hey Vector, scan my face"**
2. Vector asks: "What is your name?"
3. Say: **"Hey Vector, my name is [name]"**
4. Vector says "Nice to meet you [name]!" and scans your face
5. Once enrolled, Vector greets you with "Hello [name]!" when he sees you during wander mode

If you say "Hey Vector, my name is [name]" at any other time (without the face enrollment step), it works normally — just sets your name without face enrollment.

## Vector Control (command line)

All scripts are in `/Users/patsyuser/Downloads/Vector/`.

```bash
./vector-control.sh <command>
```

| Command | What it does |
|---|---|
| `up` / `volume-up` | Turn volume up |
| `down` / `volume-down` | Turn volume down |
| `mute` | Mute Vector |
| `unmute` | Restore volume |
| `home` / `go-home` | Send Vector to charger (stops wander if running) |
| `say <text>` | Make Vector say anything |
| `battery` | Check battery level and charger status |
| `faces` | List people Vector knows |
| `learn <name>` | Teach Vector a new face |
| `look` | One-shot: capture, describe, speak |
| `help` | Show all commands |

### Other scripts

```bash
./vector-vision.sh           # One-shot vision (same as "What do you see?")
./vector-wander.sh           # Wander indefinitely (Ctrl+C to stop)
./vector-wander.sh 5         # Wander for 5 minutes then go home
./vector-wander.sh 10        # Wander for 10 minutes then go home
```

## Wander Mode Details

When wandering, Vector:
- Drives around with random movements (forward, turn, look around)
- Captures camera frames and sends them to Claude (Pro subscription, no API costs)
- Speaks charming observations in varied moods (curious tourist, philosopher, nature documentarian, etc.)
- Checks battery before each cycle — returns to charger when low, resumes when charged
- Remembers recent observations to avoid repeating himself
- Auto-returns to Normal mode when the timer expires

### Smart interactions during wander

Each observation cycle, Vector uses Claude vision to detect who's in front of him and responds differently:

**When Vector sees Karen:**
1. Claude generates a warm, personal remark or question directed at her
2. Vector speaks it
3. Vector releases behavior control and auto-triggers his listening mode
4. Karen has ~30 seconds to respond naturally — no need to say "Hey Vector", he's already listening
5. Her response is processed through Ollama (knowledge graph), and Vector replies
6. Vector resumes wandering

**When Vector sees Bailey (brown dog):**
- Vector picks from a rotation of fun dog-owner phrases — "Who's a good boy?", "Want to go for a walk?", "Roll over!", "Those big brown eyes...", etc.
- One-way affection, as nature intended

**When Vector sees neither:**
- Normal observation — charming remarks about his surroundings

### Wander memory

Observations and interactions are stored in `vector-memory.log` (auto-trimmed to last 20).

```bash
cat vector-memory.log        # View Vector's memories
rm vector-memory.log         # Wipe memory for a fresh start
```

## Known Faces and Pets

Vector recognizes:
- **Karen** — enrolled face (via Vector's face recognition). Vector engages her in conversation.
- **Bailey** — large brown dog (recognized by Claude vision). Vector talks to him like a dog owner.

To teach Vector a new face:
- By voice: "Hey Vector, look at my face" (then follow the prompts)
- By command: `./vector-control.sh learn <name>`

To add pets or other recognizable things, edit the `BAILEY_PHRASES` array and `detect_who` function in `vector-wander.sh`.

## Knowledge Graph (AI Brain)

Currently configured to use **Ollama** running locally on Patsy:

- Provider: Custom
- Endpoint: http://localhost:11434/v1
- API Key: ollama
- Model: phi4-mini

Make sure Ollama is running for Vector to answer knowledge questions.

## Wire-Pod Dashboard Pages

- **Server Settings:** Weather API, Knowledge Graph (Ollama), language
- **Bot Settings:** Per-bot configuration
- **Bot Setup:** Bluetooth pairing and authentication
- **Custom Intents:** Create custom voice commands
- **SDK App:** Camera feed, motor control, Say Text — http://localhost:8080/sdkapp
- **Log:** View Wire-Pod activity

## Troubleshooting

### Vector can't connect to Wire-Pod
1. Make sure Wire-Pod is running (`sudo ./chipper/start.sh`)
2. Make sure Patsy and Vector are on the same 2.4 GHz network
3. Check that `escapepod.local` resolves: `dns-sd -G v4 escapepod.local`
4. Check macOS firewall isn't blocking connections

### "Hey Vector" not responding
- If the wander script is running, Vector is in Wander mode and can't hear wake words. Say "Hey Vector, go home" won't work during wander — use `./vector-control.sh home` from the command line instead, or wait for the timer to expire.
- Check that Wire-Pod is running and VOSK initialized successfully in the terminal output.

### Vector needs re-authentication
1. Put Vector in recovery mode (see above — button is unreliable, may take multiple attempts)
2. Raise/lower lift arm to clear user data
3. Open https://wpsetup.keriganc.com in Chrome
4. Pair → Wi-Fi → Activate
5. Watch terminal for "Session certificate successfully output"

### Wire-Pod not starting
```bash
# Check Go is available
/usr/local/go/bin/go version

# Check ports aren't in use
sudo lsof -i :443 -i :80 -i :8080
```

### SDK features (Say Text, Camera) not working
The SDK connects using the GUID token from `botSdkInfo.json`. If Vector's IP has changed, update it in the Wire-Pod dashboard under Bot Settings. Session certificates are NOT required for SDK functionality.

### Custom intents not working
Custom intents are loaded at Wire-Pod startup. After editing `customIntents.json`, restart Wire-Pod (`Ctrl+C` then `sudo ./chipper/start.sh`). Check terminal output for "Loaded custom intents".

## File Locations

| What | Path |
|---|---|
| Wire-Pod | /Users/patsyuser/Downloads/Vector/wire-pod/ |
| Config | wire-pod/chipper/apiConfig.json |
| Source env | wire-pod/chipper/source.sh |
| Bot info | wire-pod/chipper/jdocs/botSdkInfo.json |
| Jdocs | wire-pod/chipper/jdocs/jdocs.json |
| VOSK models | wire-pod/vosk/models/ |
| Custom intents | wire-pod/chipper/customIntents.json |
| EP certificates | wire-pod/chipper/epod/ |
| Vision script | /Users/patsyuser/Downloads/Vector/vector-vision.sh |
| Wander script | /Users/patsyuser/Downloads/Vector/vector-wander.sh |
| Control script | /Users/patsyuser/Downloads/Vector/vector-control.sh |
| Learn face script | /Users/patsyuser/Downloads/Vector/vector-learn-face.sh |
| Enroll face script | /Users/patsyuser/Downloads/Vector/vector-enroll-face.sh |
| Wander memory | /Users/patsyuser/Downloads/Vector/vector-memory.log |
