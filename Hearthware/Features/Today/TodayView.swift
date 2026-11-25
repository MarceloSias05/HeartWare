//
//  TodayView.swift
//  Hearthware
//
//  One page: how your body is, today's step, your story and your doctor's limit.
//  "Not feeling well" sits in the header, red and with words. Nothing is pinned.
//

import SwiftUI

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showingStep = false
    @State private var showingHelp = false
    @State private var showingLimit = false
    @State private var showingBreath = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    // No feeling yet: today's step comes first.
                    if let last = model.records.last { stateCard(last.after) }
                    stepCard
                    moreCard
                }
                .padding(.horizontal, Space.screen)
                .padding(.bottom, 24)
            }
            // The step is the one immersive moment: it covers everything and has its own Close.
            .fullScreenCover(isPresented: $showingStep) {
                StepFlowView(idea: model.todayStep)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingBreath) {
                BreathingView()
            }
            .sheet(isPresented: $showingLimit) {
                NavigationStack { HeartLimitView() }
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Side by side; stacked at accessibility text sizes so neither gets squeezed.
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                                                      : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
            layout {
                date
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                helpButton
            }
            Text("\(Self.greeting(at: .now)),\n\(model.name)")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var date: some View {
        Text(Date.now, format: .dateTime.weekday(.wide).day().month(.abbreviated))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.hwSecondary)
    }

    /// Red and with words, so it is never missed and scrolls with the page.
    private var helpButton: some View {
        Button {
            showingHelp = true
        } label: {
            Label("Not feeling well", systemImage: "heart.text.square.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .padding(.vertical, 4)
                .background(Color.hwRed, in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.card)
    }

    static func greeting(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    // MARK: Cards

    /// The face of how the last step felt, on its colour, always with the words.
    private func stateCard(_ feeling: Feeling) -> some View {
        VStack(spacing: 8) {
            FeelingFaceBadge(feeling: feeling)
            Text("After your last step")
                .font(.subheadline.weight(.semibold))
                .opacity(0.75)
            Text(feeling.title)
                .font(.title2.bold())
            Text(model.todayState.detail)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color(white: 0.12))
        .frame(maxWidth: .infinity)
        .padding(Space.card)
        .background(FeelingFaceBadge.color(feeling), in: .rect(cornerRadius: Radius.card))
        .accessibilityElement(children: .combine)
    }

    private var stepCard: some View {
        let step = model.todayStep
        return Container {
            VStack(alignment: .leading, spacing: 8) {
                Label("Your step", systemImage: "figure.walk")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                Text(step.title)
                    .font(.title2.bold())
                Text(step.hint)
                    .foregroundStyle(Color.hwSecondary)
                Button("Start") { showingStep = true }
                    .buttonStyle(.pill)
                    .accessibilityLabel("Start your step: \(step.title)")
                    .padding(.top, 8)
            }
        }
    }

    /// Story and limit in one grouped card, like a short settings list.
    private var moreCard: some View {
        VStack(spacing: 0) {
            Button {
                showingBreath = true
            } label: {
                row("Breathe", "wind", "A minute of slow breathing, whenever you want.")
            }
            .accessibilityHint("Opens the breathing guide")
            Divider().padding(.leading, 60)
            NavigationLink {
                StoryView()
            } label: {
                row("Your story", "book.closed.fill",
                    model.fearIsShrinking ? "Your steps feel easier than at the start." : "Every step you take will show up here.")
            }
            Divider().padding(.leading, 60)
            Button {
                showingLimit = true
            } label: {
                row("Your doctor's limit", "heart.circle.fill",
                    model.heartRateLimit == nil ? "Add the heart rate limit your doctor gave you." : "Your Watch tells you when to slow down.")
            }
        }
        .buttonStyle(.card)
        .background(Color.hwCard, in: .rect(cornerRadius: Radius.card))
    }

    private func row(_ title: String, _ symbol: String, _ detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(.rect)
    }
}

#Preview {
    TodayView()
        .environment(AppModel(container: .empty))
        .environment(WatchLink())
}
