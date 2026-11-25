# Redesign notes: `feat/redesign-steady`

A presentation-only redesign of Steady on iPhone and Apple Watch. The identity stays the same (navy, mint `hwMint`, amber `hwAmber`, red `hwRed` only for help, black/white pills, grey cards, the feeling face and its four colours, the circuit-heart icon). The data layer is untouched: SwiftData models, `AppModel`, HealthKit, WatchConnectivity and the Foundation Models grounding are the same as on `main`.

Reviewed on an iPhone 17 Pro and an Apple Watch Series 12 (46 mm) simulator, in light and dark mode and at the largest accessibility text size.

## System rules (DesignSystem.swift)

- **One shape rule:** actions, choices and one-line fields are capsules; cards are 24 pt rounded rectangles; a multi-line text box is 16 pt. Before, cards were 28, help rows 20 and the note field 14.
- **One spacing scale:** a 4 pt grid (4, 8, 12, 16, 20, 24, 32), screen margins 20 everywhere. Before, Today used 16 and other screens 20.
- **One tint:** the system blue that showed up on the "Done" check and the tab bar is gone. The iPhone accent is near-black / white (the pills), the Watch accent is mint (it colours the Watch titles).
- **Press feedback:** pills, cards and choice rows scale to 0.97–0.98 on touch-down and spring back (200 ms, no bounce). Choice rows also tick a selection haptic and animate their check.
- **Largest text sizes:** capsules use a 28 pt radius, so a button that wraps to two lines becomes a soft card instead of a stretched lozenge. The feeling page scrolls instead of truncating its question, the slider's ends sit under it, and its two buttons stack. The before/after words stack too.
- **Dark mode red:** red text on a dark card uses a lighter red (`hwRedText`) to keep 4.5:1; red fills stay `hwRed`.
- **Shared pieces:** `CardButtonStyle` (whole-card tap target), `capsuleField()` (one-line fields), `StepProgress` (five short bars, read by VoiceOver as "Step 2 of 5").

## Per screen

### Onboarding
- Welcome: the orb now floats on its own and breathes (the first thing the app teaches is to slow down), instead of sitting in a grey box. Scrolls at large text; the button stays at the bottom.
- "1 of 5" text → five short bars, the same on the question pages and the feeling page.
- Apple Health page: the red Health icon broke "red only for help". It is gone; the three paragraphs became one sentence and two short points with mint icons ("Read only", "Blood pressure at home?").
- Finishing onboarding is a one-way door: the root switches to the tabs, so there is no back into onboarding (unchanged, checked).

### Today
- The greeting follows the time of day (it said "Good morning" at 9 pm).
- "Your step" is now a card: the step's name, its hint, and a "Start" pill. Before, it was one long pill with the whole title squeezed in.
- "Your story" and "Your doctor's limit" are one grouped card with two rows, like a short settings list.
- The date and the red "Not feeling well" sit side by side, and stack at accessibility sizes.
- The step opens as a **full-screen cover** (it is the one immersive moment, with its own Close). The doctor's limit opens as a **sheet** with Cancel. Help stays a sheet, now with a drag indicator.

### Step
- Moments of the step cross-fade with a slight scale (opacity only with Reduce Motion).
- Result: the before/after card is now the feeling face on the "after" colour, starting from how the step felt before and settling into how it feels now. Both feelings are still written underneath, so colour never works alone. A success haptic lands with it.
- "Follow your Watch" says where the step is happening ("On your Apple Watch").

### Not feeling well
- Rows follow the capsule rule. Urgent rows carry a phone icon as well as red.
- "Noted" is no longer a system alert: the sheet turns into a confirmation with a check that bounces in with a success haptic, and says when we'll check in.

### Your story
- "Share with your doctor" is a drill-down row with a short description, under the fear card.
- Moments are grouped in one card, each with its date and two small feeling-colour dots (before, after) next to the words.

### Doctor's limit
- Sheet with Cancel. The number field uses tabular digits; the unit wraps under it at large text.

### Apple Watch
- Titles are mint (Watch accent), not grey.
- "You did it": full-strength feeling colour with dark ink (the dimmed gradient made it muddy), and the face settles from before to after.
- During a step: navy background like the home; past the doctor's limit the orb turns amber at the same time as the words change to "Slow down a little".
- Not feeling well: urgent rows are red platters with a phone icon and white text. "Call 112 now" sits on plain black so the red button is at full strength (the red gradient was dimmed and its footnote hard to read).

## Test by hand on a real device
- [ ] Digital Crown haptics in the Watch feeling picker (one detent per feeling).
- [ ] Dictating and scribbling a note on the Watch.
- [ ] Starting a step from the iPhone with the Watch on: the Watch opens, the iPhone shows "Follow your Watch", and the result arrives.
- [ ] Past the doctor's limit: wrist tap + amber orb + "Slow down a little"; back to calm 5 bpm under the limit.
- [ ] Real Health data in the doctor summary and Trends charts.
- [ ] Calling 112 from the iPhone and the Watch (use a test SIM or cancel before it connects).
- [ ] The check-in notification an hour after "Noted".
- [ ] Press feedback and haptics feel right under the finger (simulators don't play haptics).
- [ ] Reduce Motion on: orb still, step and result cross-fade only, faces jump straight to the "after" feeling.
