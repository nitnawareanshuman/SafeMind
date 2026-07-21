//
//  AIChatBackground.swift
//  SafeMind
//

import SwiftUI

struct AIChatBackground: View {

    var body: some View {
        GeometryReader { geo in

            let width = geo.size.width
            let height = geo.size.height

            ZStack {

                // MARK: Base Background

                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.93),
                        Color(red: 0.94, green: 0.92, blue: 0.89)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // MARK: Large Ambient Blobs

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "F0C9A0").opacity(0.9),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: width * 0.45
                        )
                    )
                    .frame(width: width * 0.9)
                    .offset(
                        x: width * 0.28,
                        y: -height * 0.12
                    )
                    .blur(radius: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "A8C8E8").opacity(0.8),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: width * 0.42
                        )
                    )
                    .frame(width: width * 0.85)
                    .offset(
                        x: -width * 0.32,
                        y: height * 0.08
                    )
                    .blur(radius: 55)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "C5B8E8").opacity(0.75),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: width * 0.35
                        )
                    )
                    .frame(width: width * 0.75)
                    .offset(
                        x: width * 0.22,
                        y: height * 0.33
                    )
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "B8D8C0").opacity(0.75),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: width * 0.30
                        )
                    )
                    .frame(width: width * 0.70)
                    .offset(
                        x: -width * 0.22,
                        y: height * 0.42
                    )
                    .blur(radius: 60)

                // MARK: Floating Accent Dots

                Group {

                    Circle()
                        .fill(Color(hex: "D4A574").opacity(0.35))
                        .frame(width: 8, height: 8)
                        .position(x: 90, y: 90)

                    Circle()
                        .fill(Color(hex: "D4A574").opacity(0.35))
                        .frame(width: 5, height: 5)
                        .position(x: 110, y: 72)

                    Circle()
                        .fill(Color(hex: "D4A574").opacity(0.35))
                        .frame(width: 6, height: 6)
                        .position(x: 125, y: 98)

                    Circle()
                        .fill(Color(hex: "8AAEC8").opacity(0.35))
                        .frame(width: 7, height: 7)
                        .position(
                            x: width - 70,
                            y: height * 0.42
                        )

                    Circle()
                        .fill(Color(hex: "8AAEC8").opacity(0.35))
                        .frame(width: 5, height: 5)
                        .position(
                            x: width - 52,
                            y: height * 0.40
                        )

                    Circle()
                        .fill(Color(hex: "A89BC8").opacity(0.35))
                        .frame(width: 6, height: 6)
                        .position(
                            x: width * 0.48,
                            y: height * 0.88
                        )

                    Circle()
                        .fill(Color(hex: "A89BC8").opacity(0.35))
                        .frame(width: 4, height: 4)
                        .position(
                            x: width * 0.50,
                            y: height * 0.86
                        )
                }

                Group {

                    Circle()
                        .stroke(
                            Color(hex: "88A8C8").opacity(0.25),
                            lineWidth: 1
                        )
                        .frame(width: 30)

                    Circle()
                        .stroke(
                            Color(hex: "88A8C8").opacity(0.15),
                            lineWidth: 0.7
                        )
                        .frame(width: 50)
                }
                .position(
                    x: 65,
                    y: height - 80
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hex Color

extension Color {

    init(hex: String) {

        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(
            red: r,
            green: g,
            blue: b
        )
    }
}

#Preview {
    AIChatBackground()
}
