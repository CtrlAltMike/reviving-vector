# Vector Reference — Intents, Animations, and Display

## Built-in Intents

These are Vector's built-in intent names used by Wire-Pod. Custom intents in `customIntents.json` use these as the `intent` field to tell Vector how to respond.

### Greeting
| Intent | Description |
|---|---|
| `intent_greeting_hello` | Hello/hi greeting |
| `intent_greeting_goodmorning` | Good morning |
| `intent_greeting_goodnight` | Good night |
| `intent_greeting_goodbye` | Goodbye |

### Seasonal
| Intent | Description |
|---|---|
| `intent_seasonal_happynewyear` | Happy New Year |
| `intent_seasonal_happyholidays` | Happy Holidays |

### Movement
| Intent | Description |
|---|---|
| `intent_imperative_forward` | Drive forward |
| `intent_imperative_turnaround` | Turn around |
| `intent_imperative_turnleft` | Turn left |
| `intent_imperative_turnright` | Turn right |
| `intent_imperative_backup` | Back up |
| `intent_imperative_come` | Come here |

### Interaction
| Intent | Description |
|---|---|
| `intent_imperative_praise` | Good robot / praise |
| `intent_imperative_abuse` | Bad robot / scold |
| `intent_imperative_love` | I love you |
| `intent_imperative_apologize` | I'm sorry |
| `intent_imperative_affirmative` | Yes |
| `intent_imperative_negative` | No |
| `intent_imperative_lookatme` | Look at me |

### Audio
| Intent | Description |
|---|---|
| `intent_imperative_volumeup` | Volume up |
| `intent_imperative_volumedown` | Volume down |
| `intent_imperative_volumelevel_extend` | Set specific volume level |
| `intent_imperative_shutup` | Be quiet (forceful) |
| `intent_imperative_quiet` | Be quiet (gentle) |

### Eye Color
| Intent | Description |
|---|---|
| `intent_imperative_eyecolor` | Change eye color |
| `intent_imperative_eyecolor_specific_extend` | Change to specific eye color |

### Games and Play
| Intent | Description |
|---|---|
| `intent_play_blackjack` | Play blackjack |
| `intent_play_fistbump` | Fist bump |
| `intent_play_rollcube` | Roll the cube |
| `intent_play_popawheelie` | Pop a wheelie |
| `intent_play_pickupcube` | Pick up cube |
| `intent_play_keepaway` | Play keep away |
| `intent_play_anytrick` | Do a trick |
| `intent_play_specific_extend` | Play specific game |
| `intent_blackjack_hit` | Blackjack: hit |
| `intent_blackjack_stand` | Blackjack: stand |
| `intent_imperative_dance` | Dance |

### Cube
| Intent | Description |
|---|---|
| `intent_imperative_fetchcube` | Fetch the cube |
| `intent_imperative_findcube` | Find the cube |

### System
| Intent | Description |
|---|---|
| `intent_system_charger` | Go to charger |
| `intent_system_sleep` | Go to sleep |
| `intent_explore_start` | Start exploring |
| `intent_system_noaudio` | No audio detected |
| `intent_system_unmatched` | Unmatched intent (fallback) |

### Clock and Timer
| Intent | Description |
|---|---|
| `intent_clock_time` | What time is it? |
| `intent_clock_checktimer` | Check timer |
| `intent_clock_settimer_extend` | Set a timer |
| `intent_global_stop_extend` | Stop / cancel |

### Photo
| Intent | Description |
|---|---|
| `intent_photo_take_extend` | Take a photo |

### Knowledge / Questions
| Intent | Description |
|---|---|
| `intent_knowledge_promptquestion` | I have a question |
| `intent_knowledge_response_extend` | Knowledge graph response |
| `intent_knowledge_response_extend_bypass` | Bypass knowledge response |
| `intent_knowledgegraph_prompt` | Knowledge graph prompt |

### Names
| Intent | Description |
|---|---|
| `intent_names_ask` | My name is... |
| `intent_names_username_extend` | Username with parameter |
| `intent_meet_victor` | Meet Victor / face enrollment |
| `intent_character_age` | How old are you? |

### Weather
| Intent | Description |
|---|---|
| `intent_weather_extend` | What's the weather? |

### Messages
| Intent | Description |
|---|---|
| `intent_message_playmessage_extend` | Play a message |
| `intent_message_recordmessage_extend` | Record a message |

### Amazon/Alexa
| Intent | Description |
|---|---|
| `intent_amazon_signin` | Sign in to Amazon |
| `intent_amazon_signout` | Sign out of Amazon |

**Note:** Intents with `_extend` suffix accept parameters extracted from speech.

---

## Vector's Screen and Custom Images

### Screen Specs
- Resolution: **184 x 96 pixels**
- Color: 16-bit RGB (565 format)
- Vector's "eyes" are rendered animations on this screen

### Displaying Custom Images

Vector can display any PNG, JPEG, or GIF image on his 184x96 screen. The practical way to do this is via Wire-Pod's **Lua scripting API**, which handles image decoding and pixel format conversion automatically.

#### How It Works

1. You POST a Lua script to Wire-Pod's `/api-lua/run_script` endpoint
2. The script calls `showImage(filePath, durationMs)` with a path to an image file on the Wire-Pod server (Patsy)
3. Wire-Pod decodes the image, converts it to Vector's 16-bit RGB format, and sends it to the robot via gRPC
4. Behavior control is required — the script must call `assumeBehaviorControl()` first
5. `releaseBehaviorControl()` is called automatically when the script finishes

#### Step-by-Step: Display an Image

**Important:** The image file path must be on **Patsy** (the Wire-Pod server), not on Vector. Wire-Pod reads the file locally and sends the pixel data to Vector over gRPC.

**Step 1 — Prepare the image**

The image should be **184 x 96 pixels** for a perfect fit. If it's a different size, it will be sent as-is (no automatic resizing), so results may be unpredictable. Resize beforehand:

```bash
# Using sips (built into macOS)
sips -z 96 184 myimage.png --out /tmp/vector_display.png

# Or using ImageMagick
convert myimage.png -resize 184x96! /tmp/vector_display.png
```

Supported formats: PNG, JPEG, GIF (first frame only).

**Step 2 — Send via curl**

```bash
curl -s http://localhost:8080/api-lua/run_script \
  -H "Content-Type: application/json" \
  -d '{
    "esn": "YOUR_VECTOR_ESN",
    "script": "assumeBehaviorControl(10)\nshowImage(\"/tmp/vector_display.png\", 5000)\nsleep(5000)"
  }'
```

- `esn` — Vector's serial number (`YOUR_VECTOR_ESN`)
- `assumeBehaviorControl(10)` — takes control at highest priority (10=override, 20=default, 30=lowest)
- `showImage(path, ms)` — displays the image for the given duration in milliseconds
- `sleep(5000)` — keeps the script alive long enough for the image to display (showImage is non-blocking)

**Step 3 — Verify**

Vector's eyes should be replaced by your image for 5 seconds, then return to normal.

#### Quick Reference

```bash
# Display an image for 5 seconds
curl -s http://localhost:8080/api-lua/run_script \
  -H "Content-Type: application/json" \
  -d '{"esn":"YOUR_VECTOR_ESN","script":"assumeBehaviorControl(10)\nshowImage(\"/tmp/vector_display.png\", 5000)\nsleep(5000)"}'

# Display for 10 seconds
curl -s http://localhost:8080/api-lua/run_script \
  -H "Content-Type: application/json" \
  -d '{"esn":"YOUR_VECTOR_ESN","script":"assumeBehaviorControl(10)\nshowImage(\"/tmp/vector_display.png\", 10000)\nsleep(10000)"}'

# Display image and have Vector say something
curl -s http://localhost:8080/api-lua/run_script \
  -H "Content-Type: application/json" \
  -d '{"esn":"YOUR_VECTOR_ESN","script":"assumeBehaviorControl(10)\nshowImage(\"/tmp/vector_display.png\", 5000)\nsayText(\"Check out my new look!\")\nsleep(5000)"}'
```

#### Lua Scripting Functions (Complete List)

These are all available within `/api-lua/run_script`:

| Function | Description |
|---|---|
| `assumeBehaviorControl(priority)` | Take control (10=override, 20=default, 30=lowest). Required before other commands. |
| `releaseBehaviorControl()` | Release control (called automatically when script ends) |
| `showImage(filePath, durationMs)` | Display an image on screen (non-blocking) |
| `sayText(text)` | Make Vector speak |
| `playAnimation(name)` | Play a built-in animation |
| `sleep(ms)` | Wait for milliseconds |
| `moveHead(speed)` | Tilt head (speed as percentage, positive=up) |
| `moveLift(speed)` | Move lift arm (speed as percentage, positive=up) |
| `moveWheels(L, R, L2, R2)` | Drive wheels (mm/s, second pair is acceleration target) |
| `postHTTPRequest(url, contentType, body, timeout)` | HTTP POST (timeout in seconds, 0=default) |
| `getHTTPRequest(url, timeout)` | HTTP GET (timeout in seconds, 0=default) |

#### Eye Color Endpoints

These don't require Lua scripting — they're direct HTTP endpoints:

| Endpoint | Description |
|---|---|
| `/api-sdk/eye_color` | Set preset eye color |
| `/api-sdk/custom_eye_color` | Set custom eye color (hue/saturation) |

#### Under the Hood: DisplayFaceImageRGB

The Lua `showImage()` function wraps the gRPC `DisplayFaceImageRGB` method. If you need to send raw pixel data directly (e.g., from a custom program):

- Pixel format: 16-bit, bit structure `000bbbbbrrrrrggg` (5-bit blue, 5-bit red, 3-bit green)
- Little-endian uint16 per pixel
- Image data: 184 × 96 × 2 = 35,328 bytes
- Source: `wire-pod/chipper/pkg/scripting/display.go`

---

## Animations

Vector has **1,100+ built-in animations** covering movement, reactions, emotions, games, and more.

### Playing Animations

#### Wire-Pod SDK App
The KGSim (Knowledge Graph Simulator) supports animation commands in LLM responses:
```
{{playAnimation||anim_greeting_hello_01}}
{{playAnimationWI||anim_eyepose_happy}}
```

#### gRPC Methods
| Method | Description |
|---|---|
| `ListAnimations` | Get all available animation names |
| `PlayAnimation` | Play a specific animation by name |
| `PlayAnimationTrigger` | Play an animation trigger |
| `ListAnimationTriggers` | Get all animation trigger names |

#### PlayAnimation Parameters
| Parameter | Description |
|---|---|
| `name` | Animation identifier string |
| `loops` | Number of times to loop |
| `ignoreBodyTrack` | Don't move body |
| `ignoreHeadTrack` | Don't move head |
| `ignoreLiftTrack` | Don't move lift arm |

### Sample Animation Categories

**Eyes/Emotions:**
- `anim_eyepose_happy`, `anim_eyepose_sad`, `anim_eyepose_angry`, `anim_eyepose_curious`

**Greetings:**
- `anim_greeting_hello_01`, `anim_greeting_goodbye_01`, `anim_greeting_goodmorning_01`

**Movement:**
- `anim_movement_forward_01`, `anim_movement_backward_01`, `anim_movement_turnaround_01`

**Reactions:**
- `anim_reacttoblock_react_01`, `anim_reacttocliff_pickup_01`

**Games:**
- `anim_fistbump_success_01`, `anim_keepaway_idle_01`, `anim_pounce_01`

**Dance:**
- `anim_dancebeat_headliftbody_left_med_01` (and many variations)

**Note:** The full list of 1,100+ animations can be queried at runtime via `ListAnimations`. The names shown above are examples — the actual list depends on Vector's firmware version.

---

## File Locations

| What | Path |
|---|---|
| Intent data | `wire-pod/chipper/intent-data/en-US.json` |
| Intent parameter mapping | `wire-pod/chipper/pkg/wirepod/ttr/intentparam.go` |
| KGSim animation commands | `wire-pod/chipper/pkg/wirepod/ttr/kgsim_cmds.go` |
| SDK display functions | `vector-go-sdk/pkg/sdk-wrapper/sdk-wrapper-images.go` |
| SDK animation functions | `vector-go-sdk/pkg/sdk-wrapper/sdk-wrapper-animations.go` |
| Protobuf definitions | `vector-go-sdk/proto/messages.proto` |
| Lua scripting display | `wire-pod/chipper/pkg/scripting/display.go` |
| Image display example | `vector-go-sdk/cmd/examples/images/main.go` |
| Animation example | `vector-go-sdk/cmd/examples/animations/main.go` |
