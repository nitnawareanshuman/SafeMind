//
//  VerticalSliderQuestionView.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//
//  The "How is your energy level?" card: a draggable vertical track that
//  snaps between the question's options, top = highest, labels running down
//  the right-hand side. A face sits to the LEFT of the track (opposite the
//  labels) and moves up/down with the thumb, changing expression to match
//  the selected option (Very High = cheerful, Normal = smile, Low = straight
//  mouth, Exhausted = sad).
//

import SwiftUI

// MARK: - Face expression

enum MoodFaceExpression: Equatable {
    case celebrate
    case smile
    case straight
    case sad

    /// Tries to infer an expression from the option's label text.
    static func forLabel(_ label: String) -> MoodFaceExpression? {
        let l = label.lowercased()

        if l.contains("very high") || l.contains("great") || l.contains("energetic") {
            return .celebrate
        }
        if l.contains("exhausted") || l.contains("very low") || l.contains("terrible") || l.contains("drained") {
            return .sad
        }
        if l.contains("low") || l.contains("tired") {
            return .straight
        }
        if l.contains("normal") || l.contains("okay") || l.contains("ok") || l.contains("high") || l.contains("good") {
            return .smile
        }
        return nil
    }

    /// Fallback based on the option's relative position, top (0) = highest.
    static func forFraction(_ fraction: CGFloat) -> MoodFaceExpression {
        switch fraction {
        case ..<0.25: return .celebrate
        case ..<0.5: return .smile
        case ..<0.75: return .straight
        default: return .sad
        }
    }
}

// MARK: - Mouth shapes

private struct SmileMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: 0), control: CGPoint(x: rect.width / 2, y: rect.height))
        return path
    }
}

private struct FrownMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height), control: CGPoint(x: rect.width / 2, y: 0))
        return path
    }
}

private struct CelebrateMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.width * 0.5, height: rect.height * 0.5))
        return path
    }
}

// MARK: - Face view

struct MoodFaceView: View {
    let expression: MoodFaceExpression

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                Circle()
                    .stroke(Color.primary, lineWidth: max(size * 0.045, 2.5))

                eyes(size: size)
                    .offset(y: -size * 0.08)

                mouth(size: size)
                    .offset(y: size * 0.2)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .animation(.easeInOut(duration: 0.25), value: expression)
    }

    @ViewBuilder
    private func eyes(size: CGFloat) -> some View {
        switch expression {
        case .celebrate:
            HStack(spacing: size * 0.2) {
                eyeArc(size: size)
                eyeArc(size: size)
            }
        case .smile, .straight, .sad:
            HStack(spacing: size * 0.22) {
                Circle().fill(Color.primary).frame(width: size * 0.075, height: size * 0.075)
                Circle().fill(Color.primary).frame(width: size * 0.075, height: size * 0.075)
            }
        }
    }

    private func eyeArc(size: CGFloat) -> some View {
        Path { path in
            let w = size * 0.14
            let h = size * 0.09
            path.move(to: CGPoint(x: 0, y: h))
            path.addQuadCurve(to: CGPoint(x: w, y: h), control: CGPoint(x: w / 2, y: 0))
        }
        .stroke(Color.primary, style: StrokeStyle(lineWidth: max(size * 0.035, 2), lineCap: .round))
        .frame(width: size * 0.14, height: size * 0.09)
    }

    @ViewBuilder
    private func mouth(size: CGFloat) -> some View {
        switch expression {
        case .straight:
            Rectangle()
                .fill(Color.primary)
                .frame(width: size * 0.26, height: max(size * 0.035, 2))

        case .smile:
            SmileMouthShape()
                .stroke(Color.primary, style: StrokeStyle(lineWidth: max(size * 0.045, 2.5), lineCap: .round))
                .frame(width: size * 0.34, height: size * 0.16)

        case .sad:
            FrownMouthShape()
                .stroke(Color.primary, style: StrokeStyle(lineWidth: max(size * 0.045, 2.5), lineCap: .round))
                .frame(width: size * 0.3, height: size * 0.14)

        case .celebrate:
            CelebrateMouthShape()
                .fill(Color.primary)
                .frame(width: size * 0.34, height: size * 0.22)
        }
    }
}

// MARK: - Vertical slider question view

struct VerticalSliderQuestionView: View {
    let question: MoodQuestion
    let selected: MoodOption?
    var onSelect: (MoodOption) -> Void
    var onPrevious: () -> Void
    var showPrevious: Bool = false
    var onNext: () -> Void

    // Track geometry — face | track | labels, all sharing one vertical axis
    private let trackHeight: CGFloat = 400
    private let trackThickness: CGFloat = 15     // thicker line
    private let thumbDiameter: CGFloat = 48
    private let faceDiameter: CGFloat = 76

    /// Space reserved above/below the track so the thumb and face never clip.
    private var edgePadding: CGFloat {
        max(thumbDiameter, faceDiameter) / 2 + 6
    }

    private var containerHeight: CGFloat {
        edgePadding * 2 + trackHeight
    }

    private var defaultIndex: Int {
        question.options.firstIndex { $0.label.caseInsensitiveCompare("Normal") == .orderedSame }
            ?? question.options.count / 2
    }

    private var selectedIndex: Int {
        guard let selected, let i = question.options.firstIndex(of: selected) else {
            return defaultIndex
        }
        return i
    }

    private var step: CGFloat {
        trackHeight / CGFloat(max(question.options.count - 1, 1))
    }

    private var thumbY: CGFloat { CGFloat(selectedIndex) * step }

    private var expression: MoodFaceExpression {
        let fraction = CGFloat(selectedIndex) / CGFloat(max(question.options.count - 1, 1))
        return MoodFaceExpression.forLabel(question.options[selectedIndex].label)
            ?? MoodFaceExpression.forFraction(fraction)
    }

    private var rowHeight: CGFloat { trackHeight / CGFloat(question.options.count) }

    var body: some View {
        VStack(spacing: 0) {
            Text(question.text)
                .font(.system(size: 38, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 68)

            Spacer(minLength: 16)

            HStack(alignment: .top, spacing: 20) {
                // Face — left side, opposite the labels
                ZStack(alignment: .top) {
                    Color.clear
                    MoodFaceView(expression: expression)
                        .frame(width: faceDiameter, height: faceDiameter)
                        .offset(y: edgePadding + thumbY - faceDiameter / 2)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedIndex)
                }
                .frame(width: faceDiameter, height: containerHeight)
                .offset(y: 10)

                // Track + thumb
                sliderTrack
                    .frame(width: max(thumbDiameter, trackThickness), height: containerHeight)
                    .offset(y: -40)

                // Labels — right side
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                        Text(option.label)
                            .font(index == selectedIndex ? .title2.weight(.bold) : .title2.weight(.regular))
                            .foregroundColor(index == selectedIndex ? .primary : .secondary)
                            .frame(height: rowHeight, alignment: .center)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    onSelect(option)
                                }
                            }
                    }
                }
                .frame(height: trackHeight)
                .padding(.top, edgePadding)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            CheckInFooterButtons(onPrevious: onPrevious, onNext: onNext, nextEnabled: true, showPrevious: showPrevious)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .onAppear {
            // Default to "Normal" if nothing has been picked yet.
            if selected == nil, question.options.indices.contains(defaultIndex) {
                onSelect(question.options[defaultIndex])
            }
        }
    }

    private var sliderTrack: some View {
        ZStack(alignment: .top) {
            // Full track (untraveled) — light gray
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: trackThickness, height: trackHeight)
                .offset(y: edgePadding)

            // Traveled portion, from the top down to the thumb — dark
            Capsule()
                .fill(Color.primary)
                .frame(width: trackThickness, height: max(thumbY, trackThickness))
                .offset(y: edgePadding)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedIndex)

            // Thumb
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: thumbDiameter, height: thumbDiameter)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                .offset(y: edgePadding + thumbY - thumbDiameter / 2)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedIndex)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in updateSelection(forY: value.location.y) }
        )
    }

    private func updateSelection(forY y: CGFloat) {
        let relativeY = y - edgePadding
        let rawIndex = Int((relativeY / step).rounded())
        let clamped = min(max(rawIndex, 0), question.options.count - 1)
        if clamped != selectedIndex {
            onSelect(question.options[clamped])
        }
    }
}

#Preview {
    ZStack {
        BlurBackground()
        VerticalSliderQuestionView(
            question: MoodQuestion.dailyCheckInQuestions[2],
            selected: MoodQuestion.dailyCheckInQuestions[2].options[1],
            onSelect: { _ in },
            onPrevious: {},
            showPrevious: true,
            onNext: {}
        )
    }
}
