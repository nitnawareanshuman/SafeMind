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

    private let period: Double = 6

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()

                blob(color: .blue.opacity(0.6), size: 300, blur: 120,
                     baseX: -115, baseY: -195, ampX: 35, ampY: 25, phase: 0, t: t)

                blob(color: .green.opacity(0.6), size: 300, blur: 120,
                     baseX: 145, baseY: -150, ampX: 25, ampY: 30, phase: 1.6, t: t)

                blob(color: .pink.opacity(0.5), size: 350, blur: 150,
                     baseX: 0, baseY: 255, ampX: 20, ampY: 25, phase: 3.1, t: t)

                blob(color: .yellow.opacity(0.5), size: 350, blur: 150,
                     baseX: 0, baseY: -250, ampX: 40, ampY: 30, phase: 4.7, t: t)
            }
        }
        .ignoresSafeArea()
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

#Preview {
    BlurBackground()
}
