//
//  TodayView.swift
//  Hearthware
//
//  One page: how your body is, today's step, your story, and "Not feeling well".
//

import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showingStep = false
    @State private var showingHelp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    stateCard
                    Button {
                        showingStep = true
                    } label: {
                        Text("Your step  ·  \(model.todayStep.title)")
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.pill)
                    .accessibilityHint("Starts today's step")
                    NavigationLink {
                        StoryView()
                    } label: {
                        storyCard
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        HeartLimitView()
                    } label: {
                        limitCard
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showingStep) {
                StepFlowView(idea: model.todayStep)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                Spacer()
                // Part of the page, red and with words, so it is never missed and moves with the rest.
                Button {
                    showingHelp = true
                } label: {
                    Label("Not feeling well", systemImage: "heart.text.square.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(Color.hwRed)
            }
            Text("Good morning,\n\(model.name)")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 4)
    }

    private var stateCard: some View {
        let state = model.todayState
        return Container {
            VStack(spacing: 12) {
                OrbView(calm: state.calm, size: 96)
                    .padding(.vertical, 12)
                Text(state.title)
                    .font(.title.bold())
                Text(state.detail)
                    .font(.body)
                    .foregroundStyle(Color.hwSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
        }
        .accessibilityElement(children: .combine)
    }

    /// No number here: the limit itself only shows where it is typed.
    private var limitCard: some View {
        Container {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your doctor's limit", systemImage: "heart.circle")
                        .font(.headline)
                    Text(model.heartRateLimit == nil ? "Add the heart rate limit your doctor gave you." : "Your Watch tells you when to slow down.")
                        .font(.subheadline)
                        .foregroundStyle(Color.hwSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var storyCard: some View {
        Container {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your story", systemImage: "book.closed")
                        .font(.headline)
                    Text(model.fearIsShrinking ? "Your steps feel easier than at the start." : "Every step you take will show up here.")
                        .font(.subheadline)
                        .foregroundStyle(Color.hwSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview {
    TodayView()
        .environment(AppModel(container: .empty))
        .environment(WatchLink())
}
