//
//  TodayView.swift
//  Hearthware
//
//  Three things only: how your body is, today's step (pinned at the bottom), and your story.
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
                    NavigationLink {
                        StoryView()
                    } label: {
                        storyCard
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            // The main action stays in reach on any phone and text size; the cards scroll behind it.
            .safeAreaInset(edge: .bottom) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHelp = true
                    } label: {
                        Label("Not feeling well", systemImage: "heart.text.square")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(Color.hwRed)
                    }
                    .accessibilityLabel("Not feeling well")
                }
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
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.hwSecondary)
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
                OrbView(calm: state.calm, size: 124)
                    .padding(.vertical, 28)
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
