//
//  WatchHomeView.swift
//  HearthwareWatch Watch App
//
//  Home on the wrist: today's step and "Not feeling well". A step started from the
//  iPhone takes over the screen until it ends.
//

import SwiftUI
import WatchKit

private let mint = Color(red: 0, green: 0.76, blue: 0.66)
private let red = Color(red: 0.84, green: 0, blue: 0.08)
/// The navy of the app icon. Dark and plain, so the mint and red buttons keep their full contrast.
private let navy = Color(red: 0.06, green: 0.14, blue: 0.18)

struct WatchRootView: View {
    @Environment(StepWorkout.self) private var workout
    @Environment(WatchStore.self) private var store

    var body: some View {
        if workout.phase != .idle && store.localStep == nil {
            WatchStepView()
        } else {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let today = store.today {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                WatchOrb(size: 14)
                                Text(today.bigStep ? "Today's step · a big one" : "Today's step")
                                    .font(.footnote)
                                    .foregroundStyle(mint)
                            }
                            Text(today.title)
                                .font(.title3.bold())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        NavigationLink {
                            WatchStepFlowView(today: today)
                        } label: {
                            Label("Start step", systemImage: "figure.walk")
                                .font(.headline)
                                .foregroundStyle(navy)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(mint)
                    } else {
                        WatchOrb(size: 40)
                        Text("Open Steady on your iPhone to set up your first step.")
                            .font(.headline)
                    }
                    // Red and with words, like on the iPhone, so it is never missed.
                    NavigationLink {
                        WatchHelpView()
                    } label: {
                        Label("Not feeling well", systemImage: "heart.text.square.fill")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // The greeting is the title: one row less, so both buttons fit on the first screen.
            .navigationTitle(store.today.map { $0.name.isEmpty ? "Steady" : "Hi \($0.name)" } ?? "Steady")
            .containerBackground(navy, for: .navigation)
        }
    }
}

// MARK: Step from the Watch

/// Before (Crown) → ask your doctor for big steps → the step → after (Crown) → done.
struct WatchStepFlowView: View {
    let today: WatchToday

    @Environment(StepWorkout.self) private var workout
    @Environment(WatchStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    enum Phase { case before, askDoctor, moving, after, done }
    @State private var phase: Phase = .before
    @State private var before: Feeling = .nervous
    @State private var after: Feeling = .calm
    @State private var noteBefore = ""
    @State private var noteAfter = ""
    @State private var step: String?
    @State private var startedAt = Date.now

    var body: some View {
        Group {
            switch phase {
            case .before:
                WatchFeelingPicker(question: "How do you feel about it?", buttonTitle: "Start",
                                   feeling: $before, note: $noteBefore) {
                    if today.bigStep { phase = .askDoctor } else { begin() }
                }
            case .askDoctor:
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A big step").font(.headline)
                        Text("Ask your doctor first. A quick check will help you feel sure.")
                            .font(.footnote)
                        Button("My doctor said it's OK") { begin() }
                            .buttonStyle(.borderedProminent)
                            .tint(mint)
                        Button("Not now") { dismiss() }
                    }
                }
            case .moving:
                WatchStepView()
            case .after:
                WatchFeelingPicker(question: "How did it feel?", buttonTitle: "Done",
                                   feeling: $after, note: $noteAfter) { finish() }
            case .done:
                WatchDoneView(before: before, after: after) { dismiss() }
            }
        }
        .navigationBarBackButtonHidden(phase == .moving || phase == .after || phase == .done)
        .onChange(of: store.localResult) {
            if store.localResult != nil, phase == .moving { phase = .after }
        }
        .onDisappear {
            // Leaving mid-step: stop it without saving anything.
            if phase == .moving, let step { workout.cancel(step: step) }
            if phase != .done { store.localStep = nil }
        }
    }

    private func begin() {
        let id = UUID().uuidString
        step = id
        startedAt = .now
        store.localStep = id
        store.localResult = nil
        phase = .moving
        Task { await workout.start(step: id, title: today.title, limit: today.heartRateLimit) }
    }

    private func finish() {
        store.send(WatchStepLog(date: startedAt, title: today.title, before: before, after: after,
                                result: store.localResult ?? WatchResult(),
                                noteBefore: noteBefore, noteAfter: noteAfter))
        store.localStep = nil
        store.localResult = nil
        WKInterfaceDevice.current().play(.success)
        phase = .done
    }
}

/// "You did it" with the words before and after. Never numbers on the wrist.
struct WatchDoneView: View {
    let before: Feeling
    let after: Feeling
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                FeelingFace(calmness: Double(Feeling.veryScared.rawValue - after.rawValue) / 3)
                    .scaleEffect(0.32)
                    .frame(width: 70, height: 48)
                    .accessibilityHidden(true)
                Text(after.rawValue < before.rawValue ? "You did it" : "You showed up")
                    .font(.title3.bold())
                Text("\(before.title) → \(after.title)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Text("Saved to your iPhone.").font(.footnote).foregroundStyle(.secondary)
                Button("Close", action: close)
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(FeelingPalette.color(at: Double(Feeling.veryScared.rawValue - after.rawValue)).gradient,
                             for: .navigation)
    }
}

// MARK: Not feeling well

struct WatchHelpView: View {
    @Environment(WatchStore.self) private var store
    @State private var noted: String?

    var body: some View {
        List {
            Section("Needs help now") {
                ForEach(SymptomList.urgent, id: \.self) { symptom in
                    NavigationLink {
                        WatchEmergencyView(symptom: symptom)
                    } label: {
                        Text(symptom).foregroundStyle(red)
                    }
                }
            }
            Section("Tell us more") {
                ForEach(SymptomList.other, id: \.self) { symptom in
                    Button(symptom) {
                        store.send(WatchSymptom(date: .now, symptom: symptom, urgent: false))
                        WKInterfaceDevice.current().play(.success)
                        noted = symptom
                    }
                }
            }
        }
        .navigationTitle("Not feeling well")
        .alert("Noted", isPresented: Binding(get: { noted != nil }, set: { if !$0 { noted = nil } })) {
            Button("OK") { noted = nil }
        } message: {
            Text("We'll add it to your summary and check on you in an hour.")
        }
    }
}

/// Chest pain or strong breathlessness: call now. Logged once for the doctor.
struct WatchEmergencyView: View {
    let symptom: String
    @Environment(WatchStore.self) private var store
    @State private var logged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Call 112 now").font(.title3.bold())
                Text("Don't wait to see if it passes.").font(.footnote)
                Link(destination: URL(string: "tel:112")!) {
                    Label("Call 112", systemImage: "phone.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(red)
                Text("You can also press and hold the side button for Emergency SOS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(red.gradient, for: .navigation)
        .onAppear {
            guard !logged else { return }
            logged = true
            store.send(WatchSymptom(date: .now, symptom: symptom, urgent: true))
            WKInterfaceDevice.current().play(.notification)
        }
    }
}
