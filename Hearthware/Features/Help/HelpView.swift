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

    private let urgent = SymptomList.urgent
    private let other = SymptomList.other

    var body: some View {
        NavigationStack {
            Group {
                if let noted { NotedView(symptom: noted) { dismiss() } } else { list }
            }
            .animation(.smooth(duration: 0.35), value: noted)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .alert("What's going on?", isPresented: $describing) {
                TextField("For example: my ankles are swollen", text: $otherText)
                Button("Save") { note(SymptomList.describe(otherText)); otherText = "" }
                Button("Cancel", role: .cancel) { otherText = "" }
            } message: {
                Text("Tell us in your own words. Your doctor will see it.")
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("How are you\nfeeling?")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 16)

                sectionHeader("Needs help now")
                ForEach(urgent, id: \.self) { item in
                    NavigationLink {
                        EmergencyView(symptom: item)
                    } label: {
                        row(item, symbol: "phone.fill", color: .hwRedText)
                    }
                    .buttonStyle(.card)
                }

                sectionHeader("Tell us more").padding(.top, 16)
                ForEach(other, id: \.self) { item in
                    Button {
                        if item == SymptomList.somethingElse { describing = true } else { note(item) }
                    } label: { row(item, symbol: nil, color: .primary) }
                        .buttonStyle(.card)
                }

                Text("We'll note it for your doctor and check on you later.")
                    .font(.subheadline)
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, Space.screen)
            .padding(.bottom, 24)
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

    /// Urgent rows carry a phone icon as well as red, so colour never works alone.
    private func row(_ text: String, symbol: String?, color: Color) -> some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol).accessibilityHidden(true)
            }
            Text(text)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.hwSecondary)
                .accessibilityHidden(true)
        }
        .font(.body.weight(symbol == nil ? .regular : .semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .background(Color.hwCard, in: .rect(cornerRadius: Radius.pill))
        .contentShape(.rect(cornerRadius: Radius.pill))
    }
}

/// The symptom is saved: a check that lands with a tap, and when we'll check in.
struct NotedView: View {
    let symptom: String
    let done: () -> Void
    @State private var landed = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.hwMint)
                .symbolEffect(.bounce, value: landed)
                .accessibilityHidden(true)
            Text("Noted")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text("We'll add \"\(symptom)\" to your summary and check on you in an hour. If it gets worse, come back here.")
                .foregroundStyle(Color.hwSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Done", action: done)
                .buttonStyle(.pill)
        }
        .padding(.horizontal, Space.screen)
        .padding(.bottom, 8)
        .sensoryFeedback(.success, trigger: landed)
        .onAppear { landed = true }
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
                RoundedRectangle(cornerRadius: Radius.card).fill(Color.hwRed.opacity(0.1))
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
        .padding(.horizontal, Space.screen)
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
