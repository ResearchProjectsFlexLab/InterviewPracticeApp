import Foundation

/// A single interview prompt shown during a practice session.
struct InterviewQuestion: Identifiable, Hashable, Sendable {
    /// 1-based position of the question within the session.
    let id: Int
    let text: String
}

extension InterviewQuestion {
    /// The standard practice set, in the exact order it is presented.
    static let standardSet: [InterviewQuestion] = [
        "Tell me about yourself.",
        "Why are you interested in this position?",
        "Describe your current or most recent job role.",
        "Why are you looking for a new opportunity now?",
        "What are your strengths?",
        "What are your weaknesses?",
        "Why do you want to work for us?",
        "Where do you see yourself in five years?",
        "Why are you the best candidate for this job?",
        "Do you have any questions for me?",
    ]
    .enumerated()
    .map { InterviewQuestion(id: $0.offset + 1, text: $0.element) }
}
