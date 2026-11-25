//
//  TodayView.swift
//  Hearthware
//
//  One page: how the last step felt, today's step, a breathing guide, your story,
//  and "Not feeling well". The face says how the person feels; the orb only breathes.
//

import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showingStep = false
    @State private var showingHelp = false
    @State private var showingBreath = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    // No feeling yet: today's step comes first.
                    if let last = model.records.last { stateCard(last.after) }
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
                    Button { showingBreath = true } label: {
                        row("Breathe", "wind", "A minute of slow breathing, whenever you want.")
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the breathing guide")
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
            .sheet(isPresented: $showingBreath) {
                BreathingView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Side by side; stacked at accessibility sizes so neither gets squeezed.
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
            layout {
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                if !typeSize.isAccessibilitySize { Spacer() }
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

    /// The face of how the last step felt, on its colour, always with the words.
    private func stateCard(_ feeling: Feeling) -> some View {
        let state = model.todayState
        return VStack(spacing: 8) {
            FeelingFaceBadge(feeling: feeling)
            Text("After your last step")
                .font(.subheadline.weight(.semibold))
                .opacity(0.75)
            Text(feeling.title)
                .font(.title.bold())
            Text(state.detail)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color(white: 0.12))
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(FeelingFaceBadge.color(feeling), in: .rect(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    /// No number here: the limit itself only shows where it is typed.
    private var limitCard: some View {
        row("Your doctor's limit", "heart.circle",
            model.heartRateLimit == nil ? "Add the heart rate limit your doctor gave you." : "Your Watch tells you when to slow down.")
    }

    private var storyCard: some View {
        row("Your story", "book.closed",
            model.fearIsShrinking ? "Your steps feel easier than at the start." : "Every step you take will show up here.")
    }

    private func row(_ title: String, _ symbol: String, _ detail: String) -> some View {
        Container {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(title, systemImage: symbol)
                        .font(.headline)
                    Text(detail)
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
        .contentShape(.rect)
    }
}

#Preview {
    TodayView()
        .environment(AppModel(container: .empty))
        .environment(WatchLink())
}
