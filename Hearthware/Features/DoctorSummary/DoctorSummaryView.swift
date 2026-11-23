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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Everything your doctor needs, numbers included. You don't have to read them.")
                    .foregroundStyle(Color.hwSecondary)
                Container {
                    DoctorPDFPage(name: model.name, condition: model.condition, goal: model.goalTitle, records: model.records)
                        .frame(width: 595, height: 842)
                        .scaleEffect(0.3, anchor: .top)
                        .frame(width: 595 * 0.3, height: 842 * 0.3)
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
        .task { pdfURL = makePDF() }
    }

    private func makePDF() -> URL? {
        let url = URL.temporaryDirectory.appending(path: "Hearthware summary.pdf")
        let page = DoctorPDFPage(name: model.name, condition: model.condition, goal: model.goalTitle, records: model.records)
            .frame(width: 595, height: 842)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HEARTWARE  ·  PATIENT SUMMARY")
                .font(.system(size: 10, weight: .bold)).kerning(1)
                .foregroundStyle(Color(white: 0.42))
            Text(name).font(.system(size: 24, weight: .bold))
            Text("\(condition?.title ?? "Heart condition")  ·  Goal: \(goal ?? "Not set")  ·  \(records.count) steps logged  ·  Created by the patient")
                .font(.system(size: 11)).foregroundStyle(Color(white: 0.42))
            Divider()
            Text("Steps taken").font(.system(size: 13, weight: .bold))
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    ForEach(["Date", "Step", "Fear before", "Fear after", "Peak HR", "Back to rest"], id: \.self) {
                        Text($0).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color(white: 0.42))
                    }
                }
                ForEach(records) { r in
                    GridRow {
                        Text(r.date, format: .dateTime.day().month(.abbreviated))
                        Text(r.title)
                        Text(r.before.title)
                        Text(r.after.title)
                        Text(r.peakHeartRate.map { "\($0) bpm" } ?? "Not yet")
                        Text(r.recoverySeconds.map { "\($0 / 60) min \($0 % 60) s" } ?? "Not yet")
                    }
                    .font(.system(size: 10))
                }
            }
            Divider()
            Text("Heart rate values come from Apple Watch once it is connected and may differ from clinical devices. This summary is not a diagnosis.")
                .font(.system(size: 9))
                .foregroundStyle(Color(white: 0.42))
            Spacer()
        }
        .padding(48)
        .frame(width: 595, height: 842, alignment: .topLeading)
        .background(.white)
        .environment(\.colorScheme, .light)
        .foregroundStyle(.black)
    }
}

#Preview {
    NavigationStack {
        DoctorSummaryView()
    }
    .environment(AppModel(container: .empty))
}
