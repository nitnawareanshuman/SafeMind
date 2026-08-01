//
//  MoodQuestionStyle.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  Each question in the check-in picks one of these presentations. This is
//  what lets "How are you feeling right now?" render as a big emoji face with
//  a scrolling pill row, "How is your energy level?" render as a vertical
//  slider, and "What's worrying you?" render as a colorful 2x2 grid — all
//  from the same underlying MoodQuestion / MoodOption data.
//

import Foundation

enum MoodQuestionStyle {
    /// Big colored circle with a large emoji "face" + horizontally scrolling
    /// pill selector underneath. Used for the opening "how do you feel" question.
    case emojiFace
    /// Colorful 2x2 grid of rounded buttons, one color per option. Used for
    /// "What's worrying you?".
    case colorGrid
    /// A vertical slider that snaps between an ordered set of labelled stops.
    /// Used for "How is your energy level?".
    case verticalSlider
    /// Plain vertical stack of pill buttons — the fallback for every other
    /// question (focus, tension, sleep, stated need).
    case simpleList
}
