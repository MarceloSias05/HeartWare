//
//  HelpView.swift
//  Hearthware
//
//  "Not feeling well". Chest pain or strong breathlessness go straight to 112.
//  Everything else is noted for the doctor, with a gentle check-in later.
//

import SwiftUI

struct HelpView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var noted: String?
    @State private var describing = false
    @State private var otherText = ""
    @State private var showingBreath = false

    private let urgent = SymptomList.urgent
    private let other = SymptomList.other

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How are you\nfeeling?")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 16)

                    sectionHeader("Needs help now")
                    ForEach(urgent, id: \.self) { item in
                        NavigationLink {
                            EmergencyView(symptom: item)
                        } label: {
                            row(item, color: .hwRed)
                        }
                        .buttonStyle(.plain)
                    }

                    sectionHeader("Tell us more").padding(.top, 16)
                    ForEach(other, id: \.self) { item in
                        Button {
                            if item == SymptomList.somethingElse { describing = true } else { note(item) }
                        } label: { row(item, color: .primary) }
                            .buttonStyle(.plain)
                    }

                    Text("We'll note it for your doctor and check on you later.")
                        .font(.subheadline)
                        .foregroundStyle(Color.hwSecondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .sheet(isPresented: $showingBreath, onDismiss: { dismiss() }) { BreathingView() }
            .alert("What's going on?", isPresented: $describing) {
                TextField("For example: my ankles are swollen", text: $otherText)
                Button("Save") { note(SymptomList.describe(otherText)); otherText = "" }
                Button("Cancel", role: .cancel) { otherText = "" }
            } message: {
                Text("Tell us in your own words. Your doctor will see it.")
            }
            // Only after a non-urgent symptom: urgent ones go straight to 112, never to breathing.
            .alert("Noted", isPresented: Binding(get: { noted != nil }, set: { if !$0 { noted = nil } })) {
                Button("Breathe") { showingBreath = true }
                Button("OK") { dismiss() }
            } message: {
                Text("We'll add \"\(noted ?? "")\" to your summary and check on you in an hour. If it gets worse, come back here.")
            }
        }
    }

    private func note(_ symptom: String) {
        model.logSymptom(symptom, urgent: false)
        noted = symptom
        Task { await CheckIn.schedule(after: symptom) }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.hwSecondary)
            .padding(.horizontal, 4)
    }

    private func row(_ text: String, color: Color) -> some View {
        HStack {
            Text(text).foregroundStyle(color)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.hwSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 56)
        .background(Color.hwCard, in: .rect(cornerRadius: 20))
        .contentShape(.rect)
    }
}

struct EmergencyView: View {
    let symptom: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// Log once, even if the view appears again after navigating back and forth.
    @State private var logged = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(Color.hwRed.opacity(0.1))
                Circle().fill(Color.hwRed).frame(width: 104, height: 104)
                Image(systemName: "phone.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 240)
            .accessibilityHidden(true)

            Text("Call 112 now")
                .font(.largeTitle.bold())
                .padding(.top, 28)
            Text("Chest pain can be serious. Sit down, stop what you're doing and call for help.")
                .foregroundStyle(Color.hwSecondary)
                .padding(.top, 10)
            Spacer(minLength: 24)
            VStack(spacing: 12) {
                if let url = URL(string: "tel://112") {
                    Link(destination: url) {
                        Label("Call 112", systemImage: "phone.fill")
                    }
                    .buttonStyle(.pillDestructive)
                }
                Button("I'm OK now") { dismiss() }
                    .buttonStyle(.pillSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear {
            guard !logged else { return }
            logged = true
            model.logSymptom(symptom, urgent: true)
        }
    }
}

#Preview {
    HelpView()
        .environment(AppModel(container: .empty))
}
