//
//  DoctorSummaryView.swift
//  Hearthware
//
//  The only place with numbers. The patient shares it, the doctor reads it.
//

import SwiftUI

struct DoctorSummaryView: View {
    @Environment(AppModel.self) private var model
    @State private var pdfURL: URL?
    @State private var previews: [UIImage] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Everything your doctor needs, numbers included. You don't have to read them.")
                    .foregroundStyle(Color.hwSecondary)
                Container {
                    // Images of the real pages, so the preview always matches the PDF and fits any width.
                    if previews.isEmpty {
                        ProgressView("Reading Apple Health…")
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(previews.indices, id: \.self) { i in
                                Image(uiImage: previews[i])
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(.rect(cornerRadius: 6))
                                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Preview of the summary for your doctor, \(previews.count) pages")
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("For your doctor")
        .safeAreaInset(edge: .bottom) {
            Group {
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.pill)
                } else {
                    ProgressView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .task {
            let now = Date.now
            let joined = model.profile?.createdAt ?? now
            let summary = DoctorSummary(
                name: model.name, condition: model.condition, goal: model.goal, goalTitle: model.goalTitle,
                joined: joined, generated: now, records: model.records, symptoms: model.symptoms,
                health: await HealthHistory.report(joined: joined, now: now))
            let pages = (0..<summary.pageCount).map { DoctorPDFPage(summary: summary, page: $0) }
            previews = pages.compactMap { page in
                let renderer = ImageRenderer(content: page)
                renderer.scale = 2
                return renderer.uiImage
            }
            pdfURL = makePDF(pages)
        }
    }

    private func makePDF(_ pages: [DoctorPDFPage]) -> URL? {
        let url = URL.temporaryDirectory.appending(path: "Hearthware summary.pdf")
        var box = CGRect(x: 0, y: 0, width: DoctorPDFPage.width, height: DoctorPDFPage.height)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return nil }
        for page in pages {
            ImageRenderer(content: page).render { _, draw in
                context.beginPDFPage(nil)
                draw(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        return url
    }
}

/// Everything the summary shows, gathered once.
struct DoctorSummary {
    var name: String
    var condition: HeartCondition?
    var goal: Goal?
    var goalTitle: String?
    var joined: Date
    var generated: Date
    var records: [StepRecord]
    var symptoms: [SymptomRecord]
    var health: HealthReport?

    /// Steps table rows: the first part shares page 2 with the movement table.
    static let stepsOnFirstPage = 30
    static let stepsPerPage = 45
    /// Most recent symptoms listed on page 1.
    static let maxSymptoms = 10

    var stepPages: [Range<Int>] {
        SummaryFacts.stepPages(count: records.count, first: Self.stepsOnFirstPage, rest: Self.stepsPerPage)
    }
    var pageCount: Int { 1 + stepPages.count }
    var windows: (before: DateInterval, recent: DateInterval) { HealthReport.windows(joined: joined, now: generated) }
}

/// One A4 page for the doctor. Plain, dense, printable.
struct DoctorPDFPage: View {
    static let width: CGFloat = 595
    static let height: CGFloat = 842

    let summary: DoctorSummary
    let page: Int

    private let grey = Color(white: 0.42)

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if page == 0 {
                header
                glance
                patientReported
                if let health = summary.health { healthTable("Heart", health.shown(in: .heart)) }
            } else {
                if page == 1, let health = summary.health {
                    healthTable("Movement and tiredness", health.shown(in: .movement))
                }
                stepsTable(summary.stepPages[page - 1])
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 36)
        .frame(width: Self.width, height: Self.height, alignment: .topLeading)
        .background(.white)
        .environment(\.colorScheme, .light)
        .foregroundStyle(.black)
    }

    // MARK: Page 1

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HEARTWARE  ·  PATIENT SUMMARY")
                .font(.system(size: 10, weight: .bold)).kerning(1)
                .foregroundStyle(grey)
            Text(summary.name).font(.system(size: 24, weight: .bold))
            Text("\(summary.condition?.title ?? "Heart condition")  ·  Goal: \(summary.goalTitle ?? "Not set")  ·  Created by the patient")
                .font(.system(size: 11)).foregroundStyle(grey)
            Text("Using Hearthware since \(day(summary.joined))  ·  Generated \(day(summary.generated))")
                .font(.system(size: 11)).foregroundStyle(grey)
            Divider()
        }
    }

    private var glance: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("At a glance").font(.system(size: 13, weight: .bold))
            ForEach(SummaryFacts.glance(report: summary.health, records: summary.records,
                                        symptoms: summary.symptoms.count,
                                        urgentSymptoms: summary.symptoms.filter(\.urgent).count), id: \.self) {
                Text("•  \($0)").font(.system(size: 10))
            }
            Divider().padding(.top, 4)
        }
    }

    private var patientReported: some View {
        let ladder = SummaryFacts.ladderPosition(goal: summary.goal, records: summary.records)
        let calm = summary.records.filter { $0.after.isCalm }.count
        let shown = summary.symptoms.suffix(DoctorSummary.maxSymptoms)
        return VStack(alignment: .leading, spacing: 4) {
            Text("How the patient feels").font(.system(size: 13, weight: .bold))
            Group {
                if let fear = SummaryFacts.fearTrend(summary.records) {
                    Text("Fear before a step: \(fear.first.title) at the first step, \(fear.last.title.lowercased()) at the latest.")
                } else {
                    Text("Fear before a step: not enough steps yet to show a change.")
                }
                Text("Progress: step \(ladder.rung) of \(ladder.total) towards \(summary.goalTitle ?? "their goal").  \(summary.records.count) steps logged, \(calm) ended calm or a little nervous.")
            }
            .font(.system(size: 10))
            .fixedSize(horizontal: false, vertical: true)

            Text(summary.symptoms.count > shown.count
                 ? "Symptoms reported (last \(shown.count) of \(summary.symptoms.count))" : "Symptoms reported")
                .font(.system(size: 10, weight: .semibold))
                .padding(.top, 4)
            if shown.isEmpty {
                Text("None.").font(.system(size: 10))
            } else {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 2) {
                    ForEach(shown) { s in
                        GridRow {
                            Text(s.date, format: .dateTime.day().month(.abbreviated).hour().minute())
                            Text(s.symptom)
                            Text(s.urgent ? "Urgent: told to call 112" : "")
                                .foregroundStyle(s.urgent ? Color(red: 0.75, green: 0, blue: 0.07) : .black)
                        }
                        .font(.system(size: 9))
                    }
                }
            }
            Divider().padding(.top, 4)
        }
    }

    // MARK: Tables

    @ViewBuilder
    private func healthTable(_ title: String, _ rows: [MetricReading]) -> some View {
        if !rows.isEmpty {
            let (before, recent) = summary.windows
            Text(title).font(.system(size: 13, weight: .bold))
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 2) {
                GridRow {
                    Text("Measure")
                    Text("Before joining\n\(range(before))")
                    Text("Last \(HealthReport.recentDays) days\n\(range(recent))")
                    Text("Change")
                }
                .font(.system(size: 9, weight: .semibold)).foregroundStyle(grey)
                .fixedSize(horizontal: false, vertical: true)
                ForEach(rows, id: \.metric) { r in
                    GridRow {
                        Text(r.metric.title)
                        Text(r.before.map(r.metric.format) ?? "No data")
                        Text(r.recent.map(r.metric.format) ?? "No data")
                        Text(r.change)
                    }
                    .font(.system(size: 9))
                }
            }
            Divider()
        }
    }

    @ViewBuilder
    private func stepsTable(_ rows: Range<Int>) -> some View {
        let total = summary.records.count
        Text(total == 0 ? "Steps taken" : "Steps taken (\(rows.lowerBound + 1)–\(rows.upperBound) of \(total))")
            .font(.system(size: 13, weight: .bold))
        if total == 0 {
            Text("No steps logged yet.").font(.system(size: 10))
        } else {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 3) {
                GridRow {
                    ForEach(["Date", "Step", "Fear before", "Fear after", "Peak HR", "Back to rest"], id: \.self) {
                        Text($0).font(.system(size: 9, weight: .semibold)).foregroundStyle(grey)
                    }
                }
                ForEach(summary.records[rows]) { r in
                    GridRow {
                        Text(r.date, format: .dateTime.day().month(.abbreviated))
                        Text(r.title)
                        Text(r.before.title)
                        Text(r.after.title)
                        Text(r.peakHeartRate.map { "\($0) bpm" } ?? "Not yet")
                        Text(r.recoverySeconds.map { "\($0 / 60) min \($0 % 60) s" } ?? "Not yet")
                    }
                    .font(.system(size: 9))
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            if page == summary.pageCount - 1 {
                Text("Values come from Apple Health and Apple Watch and may differ from clinical devices. Only measures with data are listed. Alerts read \"None\" when there were none or when they are not shared. Fear and symptoms are reported by the patient. This summary is not a diagnosis.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("\(summary.name)  ·  Generated \(day(summary.generated))  ·  Page \(page + 1) of \(summary.pageCount)")
        }
        .font(.system(size: 8))
        .foregroundStyle(grey)
    }

    // MARK: Dates

    private func day(_ date: Date) -> String { date.formatted(.dateTime.day().month(.abbreviated).year()) }

    private func range(_ interval: DateInterval) -> String {
        let f = Date.FormatStyle().day().month(.abbreviated)
        return "\(interval.start.formatted(f)) – \(interval.end.formatted(f))"
    }
}

#Preview {
    NavigationStack {
        DoctorSummaryView()
    }
    .environment(AppModel(container: .empty))
}
