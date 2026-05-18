# Today's Terrain — Template Library

The terrain report is a 5-axis snapshot of the day, computed from current transits, the user's natal placements, and the active Vedic dasha. Each axis answers one question. Each line is a snippet the compute engine fills with the user's specific chart variables.

The 5 axes are fixed:

1. **Current Weather** — what the day's signature is doing.
2. **Most Likely Default** — the script that runs without intervention.
3. **Highest Agency Move** — the single act that gives the most leverage.
4. **Best Use of Energy** — what to channel the signature into.
5. **Avoid** — what backfires today, expensively or permanently.

Templates use `{var}` placeholders. The compute engine substitutes real values from the user's chart and transit feed before render.

---

## Section A — Transit Drivers

The 12 drivers below cover the standard daily inputs. The engine selects the top 2–3 drivers by activation score and assembles the report from their template lines.

---

### Driver 1: Sun-Moon Aspect

**Vedic overlay:** Surya-Chandra yoga — applies if the natal Surya-Chandra angle is also activated by current gochara. Amavasya and Purnima are extreme cases.

| Axis | Template |
|---|---|
| Current Weather | Sun and Moon at {aspect_angle}. Will and mood pull different directions. |
| Most Likely Default | Override the feeling. Push the schedule. Call the discomfort laziness. |
| Highest Agency Move | Name the split out loud. Pick one of the two, not both. |
| Best Use of Energy | Decisions that need both head and gut to agree. |
| Avoid | Forcing alignment by 5pm. Sleeping on it works better. |

---

### Driver 2: Mercury Major Aspect

**Vedic overlay:** Budha drishti — applies if natal Budha is in {house} or rules a kendra. Mental signature dominates the day.

| Axis | Template |
|---|---|
| Current Weather | Mercury {aspect_type} {aspect_partner}. Thinking moves at an unusual speed. |
| Most Likely Default | Over-explain. Restate what was already understood. Cc more people. |
| Highest Agency Move | One sentence. Then stop. Let the silence do half the work. |
| Best Use of Energy | Naming the real question. Writing the version no one will edit. |
| Avoid | Defending a position twice. Talking to convince a closed room. |

---

### Driver 3: Venus Major Aspect

**Vedic overlay:** Shukra drishti — applies if natal Shukra is in {house} or aspects the 7th bhava. Relational signature is loud today.

| Axis | Template |
|---|---|
| Current Weather | Venus {aspect_type} {aspect_partner}. Connection runs warm or sticky. |
| Most Likely Default | Smooth it over. Stay nice past the point of honesty. |
| Highest Agency Move | Say the warm thing and the true thing in the same sentence. |
| Best Use of Energy | Repair conversations. Aesthetic decisions. Things that need taste. |
| Avoid | Agreeing to terms you'll resent. Buying it because it's pretty. |

---

### Driver 4: Mars Major Aspect

**Vedic overlay:** Mangal drishti — applies if natal Mangal is in {house} or rules the lagna. Drive runs hot, edges sharper.

| Axis | Template |
|---|---|
| Current Weather | Mars {aspect_type} {aspect_partner}. Drive runs hot. Friction available. |
| Most Likely Default | Move first, ask later. Win the small fight, lose the day. |
| Highest Agency Move | Pick the right target. Burn the energy on the worthy enemy. |
| Best Use of Energy | Hard physical work. The conversation you've been avoiding. Cold starts. |
| Avoid | Replying angry. Driving angry. Sending the screenshot. |

---

### Driver 5: Saturn Major Aspect

**Vedic overlay:** Shani drishti — applies if natal Shani is in {house} or active sade sati window. Pressure compounds across days.

| Axis | Template |
|---|---|
| Current Weather | Saturn {aspect_type} {aspect_partner}. Weight settles on whatever's unfinished. |
| Most Likely Default | Treat the pressure as a verdict. Shrink the ambition to match. |
| Highest Agency Move | One real task, done all the way. Not five half-done. |
| Best Use of Energy | The boring spine of the project. Maintenance. The audit. |
| Avoid | Quitting on a Saturn day. Big promises. New commitments. |

---

### Driver 6: Jupiter Major Aspect

**Vedic overlay:** Guru drishti — applies if natal Guru is in a kendra or trikona. Expansion signature, with overreach risk.

| Axis | Template |
|---|---|
| Current Weather | Jupiter {aspect_type} {aspect_partner}. The room feels bigger than it is. |
| Most Likely Default | Say yes to the next three things. Stretch the timeline by feel. |
| Highest Agency Move | Pick one thing to grow. Refuse the other two clearly. |
| Best Use of Energy | Teaching. Pitching. Asking for the larger version of the deal. |
| Avoid | Committing to scope you can't staff. Borrowing against next quarter. |

---

### Driver 7: Mercury Retrograde Active

**Vedic overlay:** Budha vakri — applies extra if natal Budha is in a dusthana (6, 8, 12). Communication loops harder.

| Axis | Template |
|---|---|
| Current Weather | Communication runs slow and looped. Old conversations resurface. Signal drops. |
| Most Likely Default | Send the text twice. Reread email. Assume silence means something. |
| Highest Agency Move | Wait. One question, not three. Write the draft, sleep. |
| Best Use of Energy | Editing. Reviewing. Returning to unfinished work. Apology calls. |
| Avoid | New contracts. New devices. Public announcements. Final answers. |

---

### Driver 8: Venus Retrograde Active

**Vedic overlay:** Shukra vakri — applies extra if natal Shukra is in 7th or 5th bhava. Old relational threads return.

| Axis | Template |
|---|---|
| Current Weather | Venus retrograde. Old affections, old aesthetics, old money questions resurface. |
| Most Likely Default | Reach out to someone you closed the door on. Buy the nostalgia. |
| Highest Agency Move | Reread before you reopen. Most of these doors closed for reasons. |
| Best Use of Energy | Re-evaluating values. Pruning what you no longer love. |
| Avoid | Defining a new relationship. Major aesthetic overhauls. Big purchases. |

---

### Driver 9: Mars Retrograde Active

**Vedic overlay:** Mangal vakri — applies extra if natal Mangal is in 1, 4, 7, 8, or 12. Drive turns inward, sharp.

| Axis | Template |
|---|---|
| Current Weather | Mars retrograde. Forward motion stalls. The fight wants to be internal. |
| Most Likely Default | Push harder against the same wall. Confuse stuck for lazy. |
| Highest Agency Move | Stop pushing the door. Walk around. Or sit down. |
| Best Use of Energy | Redoing what was rushed. Strength work. The internal cleanup. |
| Avoid | Picking new fights. Launching new attacks. Surgery if elective. |

---

### Driver 10: Moon Void-of-Course / Tithi Kshaya

**Vedic overlay:** Tithi kshaya or rikta tithi (4, 9, 14) — null actions. Western void-of-course Moon parallel.

| Axis | Template |
|---|---|
| Current Weather | Moon void until {void_end_time}. Nothing initiated here takes root. |
| Most Likely Default | Start something important anyway. Force a decision through. |
| Highest Agency Move | Move admin. Move maintenance. Leave the new thing for later. |
| Best Use of Energy | Inbox. Errands. Cleaning. Conversations without an agenda. |
| Avoid | Signing. Launching. Proposing. First meetings. First dates. |

---

### Driver 11: Eclipse Window (within 7 days)

**Vedic overlay:** Grahana — applies extra if natal Surya or Chandra is within 3° of the eclipse axis. Karmic load increases.

| Axis | Template |
|---|---|
| Current Weather | Eclipse within {eclipse_distance_days} days. The ground under decisions shifts. |
| Most Likely Default | Act on the new information immediately. Treat the surge as truth. |
| Highest Agency Move | Note what surfaced. Wait three days before acting on it. |
| Best Use of Energy | Honest observation. Journaling. Witnessing what's actually changing. |
| Avoid | Burning the bridge today. Eclipse insight reads different by Friday. |

---

### Driver 12: Vedic Antardasha Lord Activated by Transit

**Vedic overlay:** Pratyantar — applies extra if the antardasha lord is also the lagnesh or 10th lord. Full activation.

| Axis | Template |
|---|---|
| Current Weather | {antardasha_lord} antardasha lit by transit. Your current chapter speaks. |
| Most Likely Default | Run the {antardasha_lord} script you always run. The old groove. |
| Highest Agency Move | Notice the groove. Take the {antardasha_lord} action you've been avoiding. |
| Best Use of Energy | The work {antardasha_lord} actually came to teach. Not the symptom. |
| Avoid | Treating today as random. This is the dasha asking. |

---

## Section B — Vedic Dasha Overlays

The mahadasha is the user's current life chapter. Every transit lands through that filter. Use these as the framing paragraph at the top of the terrain report.

---

**User in Surya mahadasha.** Every transit is filtered through Surya's themes — identity, visibility, authority, the father line. Today's signature compounds with the question of who you're being seen as. Hits to {house} read as identity events, not weather.

---

**User in Chandra mahadasha.** Every transit is filtered through Chandra's themes — mood, mother, public, the inner home. Today's signature compounds with whatever the emotional body is already carrying. Hits to {house} read as mood events, not facts.

---

**User in Mangal mahadasha.** Every transit is filtered through Mangal's themes — drive, conflict, brothers, blood and edge. Today's signature compounds with whatever fight is already underway. Hits to {house} read as combat, even when no one threw a punch.

---

**User in Budha mahadasha.** Every transit is filtered through Budha's themes — words, deals, hands, the nervous system. Today's signature compounds with whatever message is already in the air. Hits to {house} read as communication events first.

---

**User in Guru mahadasha.** Every transit is filtered through Guru's themes — meaning, teachers, expansion, the long arc. Today's signature compounds with where you're already growing. Hits to {house} read as lessons, not accidents.

---

**User in Shukra mahadasha.** Every transit is filtered through Shukra's themes — love, value, taste, what you draw toward you. Today's signature compounds with whatever desire is already running. Hits to {house} read as relational, even when alone.

---

**User in Shani mahadasha.** Every transit is filtered through Shani's themes — limits, time, responsibility, the long bill. Today's signature compounds with the work already owed. Hits to {house} read as deadlines and structural facts.

---

**User in Rahu mahadasha.** Every transit is filtered through Rahu's themes — hunger, foreign, obsession, the unmapped. Today's signature compounds with whatever you can't stop thinking about. Hits to {house} read as fixation, not preference.

---

**User in Ketu mahadasha.** Every transit is filtered through Ketu's themes — release, the past life, what falls away. Today's signature compounds with what's already loosening. Hits to {house} read as endings, even small ones.

---

## Section C — Pattern Activation Hints

Each pattern from the Pattern Library has a transit signature that makes it likely to fire today. The compute engine checks these before assembling the report.

- **Recognition Threat:** Active when Mars aspects natal Sun/MC/Asc within 3° OR Mangal antardasha runs OR a transit hits 10H.
- **Solitude Recharge:** Active when Moon transits 12H/4H OR Chandra antardasha runs OR Moon-Neptune/Saturn aspect within 4°.
- **Control Under Uncertainty:** Active when Saturn aspects natal Moon/Mercury/Asc within 5° OR Shani sade sati OR Mercury stations.
- **Fast Execution / Slow Recovery:** Active when Mars-Jupiter aspect within 3° OR Mangal-Guru antardasha pair OR transit Mars in 1H/10H.
- **Emotional Delayed Processing:** Active when Moon-Saturn or Moon-Pluto aspect within 4° OR Chandra in 8H/12H by transit OR eclipse within 7 days.

---

## Section D — Tone Rules

Every line in this library follows the same rules. The engine rejects substitutions that break them.

**No prediction.** The report describes conditions and the user's agency inside those conditions. Never the outcome. "Mars hot today" is fine. "You'll fight your boss" is not. Astrology is the weather, not the verdict.

**No mysticism.** No "the universe wants," no "the cosmos is asking," no "divine timing." The planets are clocks, not authors. Lines read like a barometer, not a horoscope column.

**Avoid is permission.** The Avoid axis is a hall pass to skip something costly today. It is never a curse, never a warning of punishment. "Avoid signing contracts" means the day is bad for that specific action — not that signing one is forbidden by fate.

**Best Use is leverage.** This axis names the user's edge today, not the planet's gift. The phrasing puts the user as the agent. "Channel into hard physical work" — not "Mars gives you energy."

**Verbs follow axis.** Current Weather is observational ("runs hot," "settles on," "loops"). Most Likely Default is descriptive ("send the text twice"). Highest Agency Move is imperative ("wait," "name," "pick one"). Best Use is imperative or noun phrase. Avoid is noun phrase, never a full sentence.

**Twelve words maximum per line.** Hard cap. The engine truncates and re-renders if a substitution exceeds it. Density is the point. Every word load-bearing.

**No emojis. No exclamation marks** except inside quoted mantras the user can read aloud.

The report is a tool, not a forecast. The user is the one with hands.
