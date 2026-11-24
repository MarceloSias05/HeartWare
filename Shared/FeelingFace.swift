//
//  FeelingFace.swift
//  Hearthware
//
//  The face and colours of each feeling, shared by the iPhone and the Watch.
//

import SwiftUI

/// One clear colour per feeling, blended between neighbours while dragging.
/// Very scared → orange, nervous → sunflower, a little nervous → green, calm → mint.
enum FeelingPalette {
    static let stops: [Color] = [
        Color(red: 1.00, green: 0.60, blue: 0.33),
        Color(red: 1.00, green: 0.79, blue: 0.29),
        Color(red: 0.60, green: 0.86, blue: 0.40),
        Color(red: 0.33, green: 0.86, blue: 0.73),
    ]

    /// `level` 0 (very scared) … 3 (calm).
    static func color(at level: Double) -> Color {
        let l = min(max(level, 0), 3)
        let i = min(Int(l), 2)
        return stops[i].mix(with: stops[i + 1], by: l - Double(i))
    }
}

/// Two eyes and a mouth: wide-open eyes and a frown when scared, relaxed eyes and a smile when calm.
struct FeelingFace: View {
    /// 0 very scared … 1 calm.
    var calmness: Double

    var body: some View {
        let ink = Color(white: 0.12)
        VStack(spacing: 26) {
            HStack(spacing: 22) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule().fill(ink)
                        .frame(width: 80, height: 56 - 30 * calmness)
                }
            }
            .frame(height: 56)
            Mouth(curve: calmness * 2 - 1)
                .stroke(ink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 70 + 30 * calmness, height: 34)
        }
    }
}

/// curve 1 = smile, -1 = frown, 0 = flat.
struct Mouth: Shape {
    var curve: Double

    var animatableData: Double {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let lift = curve * rect.height / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - lift))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY - lift),
                          control: CGPoint(x: rect.midX, y: rect.midY + lift * 1.6))
        return path
    }
}
