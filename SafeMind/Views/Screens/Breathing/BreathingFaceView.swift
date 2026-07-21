import SwiftUI

struct BreathingFaceView: View {
    let phase: BreathingPhase
    let circleScale: CGFloat

    // Eye state: 0=normal, 1=wide, 2=squint
    private var eyeState: CGFloat {
        switch phase {
        case .inhale: return 1.0
        case .exhale: return 2.0
        default: return 0.0
        }
    }

    // Mouth state: 0=smile, 1=O, 2=wide, 3=flat
    private var mouthState: CGFloat {
        switch phase {
        case .inhale: return 1.0
        case .exhale: return 2.0
        case .hold, .holdAfterExhale: return 3.0
        default: return 0.0
        }
    }

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let r = (size.width / 2) * 0.85

            drawEye(context: context, cx: cx - r * 0.28, cy: cy - r * 0.18, r: r, state: eyeState)
            drawEye(context: context, cx: cx + r * 0.28, cy: cy - r * 0.18, r: r, state: eyeState)
            drawMouth(context: context, cx: cx, cy: cy + r * 0.25, r: r, state: mouthState)
        }
        .frame(width: 180, height: 180)
    }

    private func drawEye(context: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, state: CGFloat) {
        let eyeR = r * 0.09
        var path = Path()
        var ctx = context
        ctx.stroke(
            eyePath(cx: cx, cy: cy, r: eyeR, state: state),
            with: .color(Color(red: 0.27, green: 0.12, blue: 0)),
            style: StrokeStyle(lineWidth: r * 0.028, lineCap: .round)
        )
    }

    private func eyePath(cx: CGFloat, cy: CGFloat, r: CGFloat, state: CGFloat) -> Path {
        var path = Path()
        if state <= 1 {
            let t = state
            let startAngle = Angle.radians(.pi + 0.45 * (1 - t))
            let endAngle   = Angle.radians(.pi * 2 - 0.45 * (1 - t))
            path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: startAngle, endAngle: endAngle, clockwise: false)
        } else {
            // squint: flatter arc
            let t = state - 1
            let startAngle = Angle.radians(.pi * 0.1 + .pi * 0.6 * t)
            let endAngle   = Angle.radians(.pi * 1.9 - .pi * 0.6 * t)
            path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: startAngle, endAngle: endAngle, clockwise: true)
        }
        return path
    }

    private func drawMouth(context: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, state: CGFloat) {
        var ctx = context
        ctx.stroke(
            mouthPath(cx: cx, cy: cy, r: r, state: state),
            with: .color(Color(red: 0.27, green: 0.12, blue: 0)),
            style: StrokeStyle(lineWidth: r * 0.028, lineCap: .round)
        )
    }

    private func mouthPath(cx: CGFloat, cy: CGFloat, r: CGFloat, state: CGFloat) -> Path {
        var path = Path()
        let mw = r * 0.26

        if state <= 1 {
            // smile → O
            let t = state
            if t < 0.05 {
                path.addArc(center: CGPoint(x: cx, y: cy - r * 0.05),
                            radius: mw * 0.75,
                            startAngle: .degrees(17), endAngle: .degrees(163), clockwise: false)
            } else if t > 0.95 {
                path.addArc(center: CGPoint(x: cx, y: cy), radius: r * 0.115,
                            startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            } else {
                let cr = mw * 0.75 * (1 - t) + r * 0.115 * t
                path.addArc(center: CGPoint(x: cx, y: cy),
                            radius: cr, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            }
        } else if state <= 2 {
            // O → wide smile
            let t = state - 1
            if t < 0.05 {
                path.addArc(center: CGPoint(x: cx, y: cy), radius: r * 0.115,
                            startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            } else {
                let cr = r * 0.115 + (mw - r * 0.115) * t
                path.addArc(center: CGPoint(x: cx, y: cy - r * 0.03 * t),
                            radius: cr,
                            startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
            }
        } else {
            // wide → flat
            let t = state - 2
            let curveY = cy - r * 0.10 * (1 - t)
            path.move(to: CGPoint(x: cx - mw * 0.9, y: cy))
            path.addQuadCurve(to: CGPoint(x: cx + mw * 0.9, y: cy),
                              control: CGPoint(x: cx, y: curveY))
        }
        return path
    }
}
