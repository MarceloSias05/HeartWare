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
    @State private var preview: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Everything your doctor needs, numbers included. You don't have to read them.")
                    .foregroundStyle(Color.hwSecondary)
                Container {
                    // An image of the real page, so the preview always matches the PDF and fits any width.
                    Group {
                        if let preview {
                            Image(uiImage: preview)
                                .resizable()
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 6))
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        } else {
                            ProgressView("Reading Apple Health…")
                                .frame(maxWidth: .infinity, minHeight: 240)
                        }
                    }
                }
                .padding(.top, 20)
                .accessibilityLabel("Preview of the summary for your doctor")
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
            let health = await HealthHistory.report(joined: model.profile?.createdAt ?? .now)
            let page = DoctorPDFPage(name: model.name, condition: model.condition, goal: model.goalTitle,
                                     records: model.records, health: health)
            let renderer = ImageRenderer(content: page)
            renderer.scale = 2
            preview = renderer.uiImage
            pdfURL = makePDF(page)
        }
    }

    private func makePDF(_ page: DoctorPDFPage) -> URL? {
        let url = URL.temporaryDirectory.appending(path: "Hearthware summary.pdf")
        let renderer = ImageRenderer(content: page)
        var ok = false
        renderer.render { _, draw in
            var box = CGRect(x: 0, y: 0, width: 595, height: 842)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
            ok = true
        }
        return ok ? url : nil
    }
}

/// A4 page for the doctor. Plain, dense, printable.
struct DoctorPDFPage: View {
    let name: String
    let condition: HeartCondition?
    let goal: String?
    let records: [StepRecord]
    var health: HealthReport?

    /// Keeps the page to one A4 sheet.
    private static let maxStepRows = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("HEARTWARE  ·  PATIENT SUMMARY")
                .font(.system(size: 10, weight: .bold)).kerning(1)
                .foregroundStyle(Color(white: 0.42))
            Text(name).font(.system(size: 24, weight: .bold))
            Text("\(condition?.title ?? "Heart condition")  ·  Goal: \(goal ?? "Not set")  ·  \(records.count) steps logged  ·  Created by the patient")
                .font(.system(size: 11)).foregroundStyle(Color(white: 0.42))
            Divider()
            if let health {
                healthTable("Heart", health.shown(in: .heart))
                healthTable("Movement and tiredness", health.shown(in: .movement))
            }
            Text(records.count > Self.maxStepRows ? "Steps taken (last \(Self.maxStepRows) of \(records.count))" : "Steps taken")
                .font(.system(size: 13, weight: .bold))
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 3) {
                GridRow {
                    ForEach(["Date", "Step", "Fear before", "Fear after", "Peak HR", "Back to rest"], id: \.self) {
                        Text($0).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(white: 0.42))
                    }
                }
                ForEach(records.suffix(Self.maxStepRows)) { r in
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
            Divider()
            Text("Values come from Apple Health and Apple Watch and may differ from clinical devices. Only measures with data are listed. Alerts read \"None\" when there were none or when they are not shared. This summary is not a diagnosis.")
                .font(.system(size: 9))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color(white: 0.42))
            Spacer()
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 36)
        .frame(width: 595, height: 842, alignment: .topLeading)
        .background(.white)
        .environment(\.colorScheme, .light)
        .foregroundStyle(.black)
    }

    @ViewBuilder
    private func healthTable(_ title: String, _ rows: [MetricReading]) -> some View {
        if !rows.isEmpty {
            Text(title).font(.system(size: 13, weight: .bold))
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 2) {
                GridRow {
                    ForEach(["Measure", "\(HealthHistory.beforeDays) days before joining", "Last \(HealthHistory.recentDays) days", "Change"], id: \.self) {
                        Text($0).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(white: 0.42))
                    }
                }
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
}

#Preview {
    NavigationStack {
        DoctorSummaryView()
    }
    .environment(AppModel(container: .empty))
}
