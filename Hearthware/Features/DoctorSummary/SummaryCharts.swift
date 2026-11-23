//
//  SummaryCharts.swift
//  Hearthware
//
//  Swift Charts for the "Trends" page of the doctor summary. Printed on white,
//  so colours are fixed: brand teal for the main line, amber for "before".
//

import Charts
import SwiftUI

/// A titled chart box sized for a half A4 column.
struct ChartCard<Content: View>: View {
    let title: String
    let unit: String
    var height: CGFloat = 76
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 10, weight: .semibold))
                Spacer()
                Text(unit).font(.system(size: 8)).foregroundStyle(Color(white: 0.42))
            }
            content
                .frame(height: height)
                .font(.system(size: 7))
        }
        .padding(10)
        .background(Color(white: 0.965), in: .rect(cornerRadius: 8))
    }
}

/// Fear before and after every step, from what the person answered in the app.
struct FearChart: View {
    let records: [StepRecord]

    var body: some View {
        Chart {
            ForEach(records) { r in
                LineMark(x: .value("Date", r.date), y: .value("Feeling", r.before.chartLevel),
                         series: .value("When", "Before the step"))
                    .foregroundStyle(by: .value("When", "Before the step"))
                LineMark(x: .value("Date", r.date), y: .value("Feeling", r.after.chartLevel),
                         series: .value("When", "After the step"))
                    .foregroundStyle(by: .value("When", "After the step"))
            }
        }
        .chartForegroundStyleScale(["Before the step": Color.hwAmber, "After the step": Color.hwMint])
        .chartYScale(domain: 0...3)
        .chartYAxis {
            AxisMarks(values: [0, 1, 2, 3]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let level = value.as(Int.self),
                       let feeling = Feeling(rawValue: Feeling.veryScared.rawValue - level) {
                        Text(feeling.title).font(.system(size: 7))
                    }
                }
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.system(size: 7)) } }
        .chartLegend(position: .top, alignment: .leading) {
            HStack(spacing: 10) {
                legendItem("Before the step", .hwAmber)
                legendItem("After the step", .hwMint)
            }
        }
    }

    private func legendItem(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).font(.system(size: 8)).foregroundStyle(Color(white: 0.42))
        }
    }
}

/// Peak heart rate the Watch measured during each step.
struct PeakHeartRateChart: View {
    let records: [StepRecord]

    var body: some View {
        Chart(records.filter { $0.peakHeartRate != nil }) { r in
            LineMark(x: .value("Date", r.date), y: .value("Peak HR", r.peakHeartRate ?? 0))
                .foregroundStyle(Color.hwMint)
            PointMark(x: .value("Date", r.date), y: .value("Peak HR", r.peakHeartRate ?? 0))
                .foregroundStyle(Color.hwMint)
                .symbolSize(14)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .smallAxes()
    }
}

/// One Health measure (or two, for blood pressure) day by day, with the day the person joined.
struct MetricTrendChart: View {
    let series: [TrendSeries]
    let joined: Date

    private let palette: [Color] = [.hwMint, Color(red: 0.0, green: 0.45, blue: 0.40)]

    var body: some View {
        Chart {
            ForEach(Array(series.enumerated()), id: \.offset) { index, s in
                ForEach(s.points, id: \.date) { p in
                    if s.metric == .steps {
                        BarMark(x: .value("Day", p.date, unit: .day), y: .value(s.metric.title, s.metric.chartValue(p.value)))
                            .foregroundStyle(p.date < joined ? Color.hwAmber.opacity(0.7) : palette[0])
                    } else {
                        LineMark(x: .value("Day", p.date, unit: .day), y: .value(s.metric.title, s.metric.chartValue(p.value)),
                                 series: .value("Measure", s.metric.title))
                            .foregroundStyle(palette[index % palette.count])
                            .interpolationMethod(.monotone)
                    }
                }
            }
            RuleMark(x: .value("Joined", joined, unit: .day))
                .foregroundStyle(Color(white: 0.45))
                .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
        }
        .chartYScale(domain: .automatic(includesZero: series.first?.metric == .steps))
        .smallAxes()
    }
}

private extension View {
    func smallAxes() -> some View {
        chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated)).font(.system(size: 7))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel().font(.system(size: 7))
            }
        }
    }
}
