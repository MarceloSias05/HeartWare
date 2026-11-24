# Hearthware

Getting back to your life after a heart problem, one small step at a time.

After a heart attack, heart surgery or a new diagnosis, everyday things like climbing the stairs, walking to the market or playing with the grandkids can feel frightening. Hearthware turns the goal the person wants back into a ladder of small steps. Before and after each step it asks how they feel, in words and never as a score. The patient never sees numbers. Their doctor gets them all in a PDF summary.

Apple Developer Academy, challenge 2 (Health).

## What it does

### On the iPhone
- **Onboarding** in 5 pages:
  1. Name.
  2. Goal, from a list or in their own words.
  3. How they feel about that goal today, picked with the face slider.
  4. What happened to their heart, from a list or in their own words.
  5. Connecting Apple Health (read only).
- **Today:** the next step on the ladder for their goal.
- **A step:**
  - How do you feel about it? A face you slide from *very scared* to *calm*; the screen takes the feeling's colour.
  - Big steps ask the person to check with their doctor first.
  - The step itself, on the Apple Watch when there is one.
  - How did it feel? Then what the body did.
  - An optional note before and after.
- **Not feeling well:**
  - Chest pain or strong breathlessness go straight to the emergency number.
  - Anything else is saved for the doctor, with a check-in notification an hour later.
- **Story:** how the fear has been shrinking.
- **For your doctor:** a multi-page PDF. It contains:
  - A short paragraph written on device by Apple Intelligence.
  - At a glance and how the patient feels: fear trend, ladder position, symptoms.
  - Age, sex, height, weight and BMI from Apple Health.
  - Swift Charts trends from 30 days before joining until today.
  - Heart, movement and body tables (before joining vs. the last 7 days).
  - Every step with its notes.

### On the Apple Watch
Everything the person reports can also be done from the wrist. It follows the watchOS Human Interface Guidelines:
- Short interactions and large type.
- The Digital Crown to pick a value, with haptic feedback.
- Nothing reported is ever lost.

| Screen | What happens |
|---|---|
| **Home** | "Hi Marcelo", today's step, **Start step**, **Not feeling well**. |
| **Before the step** | "How do you feel about it?" **Turning the Digital Crown** moves through the four feelings (very scared, nervous, a little nervous, calm). The face, the word and the full-screen colour follow, with one haptic detent per feeling. The top-right button adds a note by dictation or Scribble. |
| **Big step** | "Ask your doctor first": *My doctor said it's OK* / *Not now*. |
| **During the step** | A walking workout keeps the person company with a soft tap every minute. It measures the peak heart rate, then how long the heart takes to settle back to rest. |
| **After the step** | "How did it feel?" with the Crown again, plus an optional note. |
| **Done** | "You did it" (or "You showed up") with the feeling before → after. In words, never numbers. |
| **Not feeling well** | Urgent symptoms show **Call 112** and a reminder that holding the side button calls Emergency SOS. Other symptoms are noted, and the iPhone sends the one-hour check-in (it also appears on the Watch). |

A step can still be started from the iPhone. The Watch then takes over the screen until the step ends and sends what it measured back to that step.

VoiceOver reads each feeling as a word. Swiping up or down changes it, one feeling at a time.

## How the iPhone and the Watch talk

The iPhone owns all the data, in SwiftData. The Watch keeps nothing of its own; it reports what happened.

```
iPhone ──application context──▶ Watch
        today's step: name, title, hint, big step?   (kept up to date as the person advances)
        a step started on the iPhone: id + title     (then HealthKit opens the Watch app)

Watch ──transferUserInfo (queued)──▶ iPhone
        WatchStepLog   a whole step done on the Watch: date, title, feeling before/after,
                       peak heart rate, recovery, notes        → saved as a StepRecord
        WatchSymptom   "Not feeling well": date, symptom, urgent → saved as a SymptomRecord
                                                                  (+ check-in if not urgent)
Watch ──sendMessage, falls back to transferUserInfo──▶ iPhone
        WatchResult    what the Watch measured for a step started on the iPhone
```

- **Nothing is lost.** Reports use `transferUserInfo`, so they are delivered even if the iPhone is out of range or the app is closed. They arrive the next time the iPhone app runs.
- **Dates are the Watch's.** A step done on the Watch at 9:00 and delivered at 11:00 is saved at 9:00.
- **One application context.** Today's step and a step start share the single context dictionary (`WatchLink.context`), so one never wipes out the other.
- **Every step has an id.** A late result from a cancelled step is ignored, never saved on the wrong step.

The message formats live in `Shared/WatchResult.swift` and are covered by `Checks`.

## Project structure

```
Hearthware/                  iPhone app
  App/                       entry point, injects AppModel and WatchLink
  Data/AppModel.swift        the single source of truth the views observe; the only place that writes
  Domain/                    pure logic: Coach (the ladder), Profile, StepRecord, SymptomRecord,
                             HealthMetric, SummaryFacts, BodyProfile, Trends
  Services/                  HealthHistory (Apple Health), WatchLink (the Watch), CheckIn
                             (notifications), DoctorNarrative (Apple Intelligence)
  DesignSystem/              colours, pill buttons, QuestionPage, FeelingPage
  Features/                  Onboarding, Today, Step, Help, Story, DoctorSummary
HearthwareWatch Watch App/   Watch app
  WatchHomeView.swift        home, step flow, done, Not feeling well, emergency
  WatchFeelingPicker.swift   the Digital Crown feeling picker
  WatchStore.swift           today's step and reporting to the iPhone
  StepWorkout.swift          the HealthKit workout during a step
  PhoneLink.swift            WatchConnectivity on the Watch side
Shared/                      compiled into both apps: Feeling, FeelingFace (face + colours),
                             SymptomList, WatchResult (messages)
Checks/                      assert-based checks for Domain, Data and Shared (run.sh)
docs/app-icon.swift          redraws the app icon
```

## Frameworks

| Framework | Used for |
|---|---|
| SwiftUI | All the interface, on the iPhone and the Watch |
| Observation | `AppModel`, `WatchLink`, `WatchStore`, `StepWorkout` |
| SwiftData | Profile, steps (with notes) and symptoms, on the phone |
| HealthKit | Heart, movement and body history for the summary; the workout that measures a step on the Watch |
| WatchConnectivity | Today's step to the Watch; steps, symptoms and results back to the iPhone |
| WatchKit | The Watch app and its haptics |
| Swift Charts | The "Trends" page of the PDF |
| FoundationModels | The doctor paragraph, written on device by Apple Intelligence |
| UserNotifications | The "How are you feeling now?" check-in an hour after a symptom |

## Privacy

- Apple Health is **read only**. Nothing leaves the phone until the person taps **Share PDF**.
- The Apple Intelligence paragraph is written **on device**. It is checked before use: every number in it must appear in the data it was given, otherwise it is discarded and the PDF goes without it.
- The patient's screens never show numbers; only the doctor summary does.

## Build and run

Requirements:
- Xcode 27.
- iOS 26+.
- watchOS 27.2+.
- The Apple Intelligence paragraph also needs a device that supports it.

```sh
open Hearthware.xcodeproj      # schemes: "Hearthware" (iPhone) and "HearthwareWatch Watch App"
Checks/run.sh                  # logic checks, prints "all checks OK"
```

To try the Watch:
1. Run the **Hearthware** scheme on an iPhone simulator that is paired with a Watch simulator, or on real devices.
2. Finish onboarding on the iPhone. The Watch then shows today's step.
3. On the simulator, turn the Digital Crown with the mouse wheel or trackpad over the Watch window.

Still to test on real devices:
- The Crown haptics.
- Dictating a note.
- Calling 112.
- A Watch step showing up on the iPhone.
