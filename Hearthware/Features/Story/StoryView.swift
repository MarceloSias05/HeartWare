//
//  StoryView.swift
//  Hearthware
//
//  The fear getting smaller, the moments you got back, and the summary
//  for your doctor. Still no numbers for the patient.
//

import SwiftUI

struct StoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                fearCard
                NavigationLink {
                    DoctorSummaryView()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share with your doctor").font(.headline)
                            Text("A summary with everything they need.")
                                .font(.subheadline)
                                .foregroundStyle(Color.hwSecondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hwSecondary)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .padding(16)
                    .background(Color.hwCard, in: .rect(cornerRadius: Radius.card))
                }
                .buttonStyle(.card)
                if !model.records.isEmpty {
                    Text("Moments you got back")
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 16)
                    VStack(spacing: 0) {
                        ForEach(model.records.reversed()) { record in
                            momentRow(record)
                            if record.id != model.records.first?.id { Divider().padding(.leading, 56) }
                        }
                    }
                    .background(Color.hwCard, in: .rect(cornerRadius: Radius.card))
                }
            }
            .padding(.horizontal, Space.screen)
            .padding(.bottom, 24)
        }
        .navigationTitle("Your story")
    }

    private var fearCard: some View {
        Container {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.fearIsShrinking ? "Your fear is getting smaller" : "Your story starts here")
                    .font(.title3.bold())
                if let goal = model.goalTitle {
                    Text("Working towards: \(goal)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.hwSecondary)
                }
                Text("Every step you took, from the first one to today.")
                    .font(.subheadline)
                    .foregroundStyle(Color.hwSecondary)
                FearDots(records: model.records)
                    .frame(height: 48)
                    .padding(.top, 16)
                HStack {
                    Text("First step")
                    Spacer()
                    Text("Today")
                }
                .font(.subheadline)
                .foregroundStyle(Color.hwSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fearCardLabel)
    }

    private var fearCardLabel: String {
        let fear = model.fearIsShrinking ? "Your fear is getting smaller with every step." : "No steps yet."
        guard let goal = model.goalTitle else { return fear }
        return "Working towards: \(goal). \(fear)"
    }

    /// The feeling before and after as two colour dots, always next to the words.
    private func momentRow(_ record: StepRecord) -> some View {
        HStack(alignment: .top, spacing: 16) {
            HStack(spacing: -6) {
                feelingDot(record.before)
                feelingDot(record.after)
            }
            .frame(width: 24)
            .padding(.top, 4)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title).font(.headline)
                Text("\(record.before.title) before, \(record.after.title.lowercased()) after")
                    .font(.subheadline)
                    .foregroundStyle(Color.hwSecondary)
                Text(record.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.footnote)
                    .foregroundStyle(Color.hwSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }

    private func feelingDot(_ feeling: Feeling) -> some View {
        Circle()
            .fill(FeelingPalette.color(at: Double(Feeling.veryScared.rawValue - feeling.rawValue)))
            .stroke(Color.hwCard, lineWidth: 2)
            .frame(width: 16, height: 16)
    }
}

/// One dot per step. Bigger and warmer means more fear before the step.
struct FearDots: View {
    let records: [StepRecord]

    var body: some View {
        GeometryReader { geo in
            let count = max(records.count, 1)
            let spacing = geo.size.width / CGFloat(count)
            ZStack(alignment: .leading) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    let level = CGFloat(record.before.rawValue)
                    Circle()
                        .fill(level >= 2 ? Color.hwAmber : Color.hwMint)
                        .frame(width: 14 + level * 10, height: 14 + level * 10)
                        .position(x: spacing * (CGFloat(index) + 0.5), y: geo.size.height / 2)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { StoryView() }
        .environment(AppModel(container: .empty))
}
