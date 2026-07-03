import Foundation

/// One interactive task inside a lesson (Duolingo-style).
///
/// The `prompt` carries only *content* (an emoji cue, a sentence with a blank,
/// a hint for a sentence to build). The instruction line ("Choose the word",
/// "Build the sentence", …) is derived from the kind by the UI so it can be
/// localised into the learner's language without touching course content.
public struct Exercise: Identifiable, Codable, Equatable, Sendable {
    public let id: ExerciseID
    public var kind: ExerciseKind

    public init(id: ExerciseID, kind: ExerciseKind) {
        self.id = id
        self.kind = kind
    }
}

public enum ExerciseKind: Codable, Equatable, Sendable {
    /// Pick the right option — used for emoji vocabulary ("🍎 = ?") and
    /// fill-in-the-blank grammar ("I ___ a student.").
    case choice(prompt: String, choices: [String], answerIndex: Int)
    /// Arrange a word bank into a sentence. `words` may contain distractors;
    /// correctness is judged against `answer` (normalised).
    case wordOrder(prompt: String, words: [String], answer: String)
    /// Type the answer. Compared normalised; `accepted` lists alternatives.
    case typeAnswer(prompt: String, answer: String, accepted: [String])
}

/// A learner's submitted answer, matching the exercise kind.
public enum ExerciseAnswer: Equatable, Sendable {
    case choice(Int)
    case words([String])
    case text(String)
}

extension Exercise {
    /// Whether `answer` is correct. A mismatched answer shape is just wrong.
    public func check(_ answer: ExerciseAnswer) -> Bool {
        switch (kind, answer) {
        case let (.choice(_, choices, answerIndex), .choice(picked)):
            return choices.indices.contains(picked) && picked == answerIndex
        case let (.wordOrder(_, _, expected), .words(picked)):
            return AnswerNormalizer.normalize(picked.joined(separator: " "))
                == AnswerNormalizer.normalize(expected)
        case let (.typeAnswer(_, expected, accepted), .text(typed)):
            let normalized = AnswerNormalizer.normalize(typed)
            guard !normalized.isEmpty else { return false }
            return ([expected] + accepted)
                .map(AnswerNormalizer.normalize)
                .contains(normalized)
        default:
            return false
        }
    }

    /// Display text for the "Correct answer: …" feedback banner.
    public var correctAnswerText: String {
        switch kind {
        case let .choice(_, choices, answerIndex):
            return choices.indices.contains(answerIndex) ? choices[answerIndex] : ""
        case let .wordOrder(_, _, answer):
            return answer
        case let .typeAnswer(_, answer, _):
            return answer
        }
    }
}

/// Tolerant text comparison: case, punctuation, and extra whitespace never
/// count against the learner ("Im fine" matches "I'm fine.").
public enum AnswerNormalizer {
    public static func normalize(_ text: String) -> String {
        // Apostrophes vanish entirely (don't → dont), other punctuation
        // becomes a space, then runs of whitespace collapse.
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let apostrophesRemoved = text.lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
        let mapped = apostrophesRemoved.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : " "
        }
        return String(mapped)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }
}
