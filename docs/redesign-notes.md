# Redesign notes

## Breathing guide (`feat/breathing-guide`)

The orb used to breathe on its own in seven places, at a 5 s rhythm tied to nothing. Now the orb has one job: it is the breathing guide. The feeling face is the only thing that says how the person feels.

### What changed
- **New breathing guide** (`BreathingView` on iPhone, `WatchBreathingView` on the Watch):
  - The orb grows on "Breathe in" (about 4 s) and shrinks on "Breathe out" (about 6 s), with slow ease in/out.
  - After about a minute it closes by itself; "Done" stops it at any time.
  - Words only: no counters, timers or scores, and no health claims.
  - iPhone: a sheet with medium and large detents. A firmer soft tap marks each breath in and a lighter one each breath out.
  - Watch: different taps for in (`directionUp`) and out (`directionDown`).
  - Reduce Motion: the orb doesn't grow; it fades between full and half strength, and the words and taps still change.
  - VoiceOver announces "Breathe in" / "Breathe out".
- **Where the guide opens (only here):**
  1. Today: a "Breathe" row.
  2. Before a step: an optional "Breathe first" button at the top of the "How do you feel about it?" screen.
  3. Watch: a "Breathe" button under "Slow down a little", only when the doctor's limit is passed. No limit means no warning and no button.
  4. After a non-urgent symptom: "Breathe" next to OK in the "Noted" alert. Urgent symptoms (chest pain, very short of breath) still go straight to the 112 screen, with no guide there.
- **Orb removed where it did nothing:**
  - Today: the state card is now the face of how the last step felt, on its colour, with the word ("After your last step · A little nervous"). With no step yet, there is no card and "Your step" comes first.
  - "A big step" shows the face of how they feel about the step, and the result shows the face of how they felt after. Both feelings stay written as words.
  - "Follow your Watch" shows a still Watch icon, and "You're doing well" (step without a Watch) a still walking figure.
  - Watch home: the small orb next to "Today's step" and the one on the empty screen are gone.
  - Watch step screen: no orb. It scrolls, so the text is never cut.
  - Onboarding keeps the orb as a still brand mark (it no longer breathes).
- **Unchanged:** Your story, history and trends, the PDF and the data layer.

### Test by hand (real iPhone + Watch)
- [ ] iPhone guide: a firmer tap on each "Breathe in", a lighter one on each "Breathe out", in time with the orb.
- [ ] Watch guide: the in and out taps feel different and arrive with the words.
- [ ] Watch: past the limit during a step, "Slow down a little" shows "Breathe"; the guide opens and the screen stays on until it ends (the workout session keeps the app in front). With no limit set, nothing appears.
- [ ] After "Dizzy" (or another non-urgent symptom), "Breathe" in the Noted alert opens the guide. Chest pain and very short of breath go to 112 with no guide.
- [ ] The guide closes by itself after about a minute, and "Done" stops it at any point.
- [ ] Reduce Motion on: the orb fades without growing; the words and taps still change.
- [ ] VoiceOver: "Breathe in" / "Breathe out" are announced, and "Done" is easy to reach.
