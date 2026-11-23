import SwiftUI
import AppKit

let mint = Color(red: 0.0, green: 0.76, blue: 0.66)
let deep = Color(red: 0.0, green: 0.42, blue: 0.40)
let amber = Color(red: 1.0, green: 0.70, blue: 0.25)
let navy = Color(red: 0.05, green: 0.11, blue: 0.15)

/// Classic parametric heart, fitted to `rect`.
func heart(in r: CGRect) -> Path {
    var p = Path()
    for i in 0...400 {
        let t = Double(i) / 400 * 2 * .pi
        let x = 16 * pow(sin(t), 3)
        let y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
        let pt = CGPoint(x: r.midX + x / 32 * r.width, y: r.minY + (y + 11.8) / 28.8 * r.height)
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    return p
}

func poly(_ pts: [CGPoint]) -> Path { var p = Path(); p.addLines(pts); return p }
func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: 512 + x, y: 512 + y) }

/// A: heart outline, a heartbeat inside that keeps rising: heart + longer life.
struct ConceptA: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [mint, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
            heart(in: CGRect(x: 172, y: 210, width: 680, height: 610))
                .stroke(.white, style: StrokeStyle(lineWidth: 64, lineCap: .round, lineJoin: .round))
            poly([P(-250, 70), P(-130, 70), P(-90, 10), P(-40, 150), P(20, -120), P(80, 60), P(130, 0), P(250, -170)])
                .stroke(.white, style: StrokeStyle(lineWidth: 48, lineCap: .round, lineJoin: .round))
            Circle().fill(amber).frame(width: 110, height: 110).position(P(262, -186))
        }
        .frame(width: 1024, height: 1024)
    }
}

/// B: the heart drawn as a circuit: 45° traces and pads (hardware), a pulse inside, amber pad going up.
struct ConceptB: View {
    var background = true
    var mono = false
    var body: some View {
        let mint = mono ? Color(white: 0.72) : mint
        let amber = mono ? Color.white : amber
        let outline = [P(0, 300), P(-280, 20), P(-280, -110), P(-180, -210), P(-90, -210), P(0, -120),
                       P(90, -210), P(180, -210), P(280, -110), P(280, 20), P(0, 300)]
        ZStack {
            if background {
                LinearGradient(colors: [Color(red: 0.07, green: 0.16, blue: 0.20), navy], startPoint: .top, endPoint: .bottom)
            }
            Group {
            poly(outline).stroke(mint, style: StrokeStyle(lineWidth: 46, lineCap: .round, lineJoin: .round))
            poly([P(-280, -40), P(-400, -40)]).stroke(mint, lineWidth: 30)
            poly([P(0, 300), P(0, 400)]).stroke(mint, lineWidth: 30)
            poly([P(180, -210), P(300, -330), P(360, -330)]).stroke(amber, style: StrokeStyle(lineWidth: 30, lineJoin: .round))
            Circle().fill(mint).frame(width: 74).position(P(-400, -40))
            Circle().fill(mint).frame(width: 74).position(P(0, 400))
            Circle().fill(amber).frame(width: 90).position(P(370, -330))
            poly([P(-170, 20), P(-80, 20), P(-40, -60), P(10, 100), P(60, -10), P(170, -10)])
                .stroke(.white, style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round))
            }
            .offset(y: -30)
        }
        .frame(width: 1024, height: 1024)
    }
}

/// C: a solid heart inside growing rings, like the rings of a tree or of the Watch: years added.
struct ConceptC: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.92, green: 0.99, blue: 0.96), Color(red: 0.78, green: 0.95, blue: 0.89)],
                           startPoint: .top, endPoint: .bottom)
            ForEach(0..<3, id: \.self) { i in
                let size = 540.0 + Double(i) * 150
                Circle().trim(from: 0, to: 0.55 + Double(i) * 0.13)
                    .stroke(i == 2 ? amber : mint.opacity(0.45 + Double(i) * 0.25),
                            style: StrokeStyle(lineWidth: 44, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: size, height: size)
            }
            heart(in: CGRect(x: 322, y: 345, width: 380, height: 342))
                .fill(LinearGradient(colors: [mint, deep], startPoint: .top, endPoint: .bottom))
            poly([P(-120, 15), P(-55, 15), P(-25, -35), P(15, 70), P(50, -5), P(120, -5)])
                .stroke(.white, style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor func save<V: View>(_ v: V, _ name: String) {
    let r = ImageRenderer(content: v); r.scale = 1
    let rep = NSBitmapImageRep(data: r.nsImage!.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1] + "/" + name))
}

MainActor.assumeIsolated {
    save(ConceptB(), "B.png"); save(ConceptB(background: false), "B-dark.png"); save(ConceptB(background: false, mono: true), "B-tinted.png")
    let watch = ConceptB().clipShape(.circle).background(navy).frame(width: 1024, height: 1024)
    save(ConceptB(), "B-watch.png"); _ = watch
    // Contact sheet: each concept as an iOS icon at large and home-screen size.
    let sheet = HStack(spacing: 40) {
        ForEach(0..<3, id: \.self) { i in
            VStack(spacing: 20) {
                Group {
                    switch i { case 0: ConceptA(); case 1: ConceptB(); default: ConceptC() }
                }
                .scaleEffect(260.0 / 1024).frame(width: 260, height: 260)
                .clipShape(.rect(cornerRadius: 58, style: .continuous))
                Group {
                    switch i { case 0: ConceptA(); case 1: ConceptB(); default: ConceptC() }
                }
                .scaleEffect(60.0 / 1024).frame(width: 60, height: 60)
                .clipShape(.rect(cornerRadius: 13.5, style: .continuous))
                Text(["A · Pulse that rises", "B · Circuit heart", "C · Rings of years"][i]).font(.system(size: 20, weight: .semibold))
            }
        }
    }
    .padding(40).background(Color(white: 0.93))
    save(sheet, "sheet.png")
}
