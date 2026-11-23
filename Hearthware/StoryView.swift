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
                    if !model.records.isEmpty {
                        Text("Moments you got back")
                            .font(.title3.bold())
                            .padding(.top, 8)
                        VStack(spacing: 0) {
                            ForEach(model.records.reversed()) { record in
                                momentRow(record)
                                if record.id != model.records.first?.id { Divider().padding(.leading, 44) }
                            }
                        }
                    }
                    NavigationLink {
                        DoctorSummaryView()
                    } label: {
                        Label("Share with your doctor", systemImage: "doc.text")
                    }
                    .buttonStyle(.pillSecondary)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Your story")
    }

    private var fearCard: some View {
        Container {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.fearIsShrinking ? "Your fear is getting smaller" : "Your story starts here")
                    .font(.title3.bold())
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
        .accessibilityLabel(model.fearIsShrinking ? "Your fear is getting smaller with every step." : "No steps yet.")
    }

    private func momentRow(_ record: StepRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                Text("\(record.before.title) before, \(record.after.title.lowercased()) after")
                    .font(.subheadline)
                    .foregroundStyle(Color.hwSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
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
        .environment(AppModel(preview: true))
}
