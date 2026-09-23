import SwiftUI

/// Ambient blurred-blob background used across most screens.
///
/// Blob positions are a pure function of wall-clock time (via `TimelineView`)
/// instead of an `@State` value that's toggled in `onAppear`. That matters
/// because this view gets torn down and recreated every time it's pushed or
/// popped off a `NavigationStack` (e.g. Articles list -> Article detail ->
/// back). With the old `onAppear`-driven `@State`, every fresh instance
/// reset its blobs to the same starting offsets, so navigating back looked
/// like the background "snapped" to a different position. Driving the
/// motion from `Date()` means a new instance picks up exactly where the
/// motion already was, so the background reads as one continuous scene
/// across pushes/pops instead of restarting.
struct BlurBackground: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let period: Double = 6
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                (isDark ? Color(hex: "090E1B") : Color(.systemBackground))
                    .overlay(isDark ? Color.clear : Color.black.opacity(0.05))
                    .ignoresSafeArea()

                blob(color: (isDark ? Color(hex: "465AD6").opacity(0.42) : .blue.opacity(0.6)), size: 300, blur: 120,
                     baseX: -115, baseY: -195, ampX: 35, ampY: 25, phase: 0, t: t)

                blob(color: (isDark ? Color(hex: "178D85").opacity(0.42) : .green.opacity(0.6)), size: 300, blur: 120,
                     baseX: 145, baseY: -150, ampX: 25, ampY: 30, phase: 1.6, t: t)

                blob(color: (isDark ? Color(hex: "7254AC").opacity(0.28) : .pink.opacity(0.5)), size: 350, blur: 150,
                     baseX: 0, baseY: 255, ampX: 20, ampY: 25, phase: 3.1, t: t)

                blob(color: (isDark ? Color(hex: "465AD6").opacity(0.12) : .yellow.opacity(0.5)), size: 350, blur: 150,
                     baseX: 0, baseY: -250, ampX: 40, ampY: 30, phase: 4.7, t: t)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A single soft, blurred circle that drifts smoothly around a base
    /// point using a sine/cosine of absolute time — continuous regardless of
    /// when this view instance was created.
    private func blob(color: Color, size: CGFloat, blur: CGFloat,
                       baseX: CGFloat, baseY: CGFloat,
                       ampX: CGFloat, ampY: CGFloat,
                       phase: Double, t: Double) -> some View {
        let angle = (t * (2 * .pi / period)) + phase
        let x = baseX + ampX * CGFloat(sin(angle))
        let y = baseY + ampY * CGFloat(cos(angle))

        return Circle()
            .fill(color)
            .frame(width: size)
            .blur(radius: blur)
            .offset(x: x, y: y)
    }
}

#Preview("Light") {
    BlurBackground().preferredColorScheme(.light)
}

#Preview("Midnight Aurora") {
    BlurBackground().preferredColorScheme(.dark)
}
