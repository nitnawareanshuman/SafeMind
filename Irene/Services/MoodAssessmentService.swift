//
//  MoodAssessmentService.swift
//  Irene
//
//  Part of the AI Mood Check-In feature.
//

import Foundation

/// Turns a completed set of check-in answers into a `MoodAssessment` using a
/// weighted-average algorithm.
///
/// Every `MoodOption` carries a 0–10 `impact` on all five wellness scores, and
/// every `MoodQuestion` carries a `weight` saying how much *that question*
/// should count toward each score. The final score for a dimension is the
/// weight-average of every answered option's impact on that dimension:
///
///     score = Σ(impact_i * weight_i) / Σ(weight_i)
///
/// This keeps scoring purely data-driven — adding, removing, or re-weighting
/// questions never requires touching this algorithm.
struct MoodAssessmentService {

    func computeAssessment(from answers: [(question: MoodQuestion, option: MoodOption)]) -> MoodAssessment {
        var weightedTotals = MoodImpact(stress: 0, energy: 0, focus: 0, calmness: 0, tension: 0)
        var totalWeights = MoodImpact(stress: 0, energy: 0, focus: 0, calmness: 0, tension: 0)

        for (question, option) in answers {
            let w = question.weight
            let i = option.impact

            weightedTotals = MoodImpact(
                stress: weightedTotals.stress + i.stress * w.stress,
                energy: weightedTotals.energy + i.energy * w.energy,
                focus: weightedTotals.focus + i.focus * w.focus,
                calmness: weightedTotals.calmness + i.calmness * w.calmness,
                tension: weightedTotals.tension + i.tension * w.tension
            )

            totalWeights = MoodImpact(
                stress: totalWeights.stress + w.stress,
                energy: totalWeights.energy + w.energy,
                focus: totalWeights.focus + w.focus,
                calmness: totalWeights.calmness + w.calmness,
                tension: totalWeights.tension + w.tension
            )
        }

        return MoodAssessment(
            stress: weightedAverage(weightedTotals.stress, totalWeights.stress),
            energy: weightedAverage(weightedTotals.energy, totalWeights.energy),
            focus: weightedAverage(weightedTotals.focus, totalWeights.focus),
            calmness: weightedAverage(weightedTotals.calmness, totalWeights.calmness),
            tension: weightedAverage(weightedTotals.tension, totalWeights.tension)
        )
    }

    /// Guards against divide-by-zero (e.g. an empty answer set) and clamps to the 0–10 scale.
    private func weightedAverage(_ total: Double, _ weight: Double) -> Double {
        guard weight > 0 else { return 5.0 } // neutral midpoint when no signal exists
        return min(max(total / weight, 0), 10)
    }
}
