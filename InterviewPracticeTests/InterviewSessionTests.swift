import Foundation
import Testing
@testable import InterviewPractice

@MainActor
struct InterviewQuestionTests {
    @Test func standardSetHasExactQuestionsInOrder() {
        let expected = [
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
        #expect(InterviewQuestion.standardSet.map(\.text) == expected)
        #expect(InterviewQuestion.standardSet.map(\.id) == Array(1...10))
    }
}

@MainActor
struct InterviewSessionTests {
    /// A long tick interval keeps the real timer from firing, so tests drive `tick()` directly.
    private func makeSession() -> InterviewSession {
        InterviewSession(tickInterval: .seconds(3600))
    }

    /// 20 ticks count 20 down to 0; one more tick moves to the next question.
    private let ticksPerQuestion = 21

    @Test func initialStateIsWelcomeWithNoTimer() {
        let session = makeSession()
        #expect(session.phase == .welcome)
        #expect(session.currentIndex == 0)
        #expect(session.remainingSeconds == 20)
        #expect(!session.isTimerRunning)
    }

    @Test func tickOnWelcomeScreenDoesNothing() {
        let session = makeSession()
        session.tick()
        #expect(session.phase == .welcome)
        #expect(session.remainingSeconds == 20)
    }

    @Test func startShowsFirstQuestionAndStartsTimer() {
        let session = makeSession()
        session.start()
        #expect(session.phase == .inProgress)
        #expect(session.questionNumber == 1)
        #expect(session.currentQuestion.text == "Tell me about yourself.")
        #expect(session.remainingSeconds == 20)
        #expect(session.isTimerRunning)
    }

    @Test func startWhileInProgressDoesNotRestart() {
        let session = makeSession()
        session.start()
        session.tick()
        session.tick()
        session.start()
        #expect(session.remainingSeconds == 18)
        #expect(session.currentIndex == 0)
    }

    @Test func countdownShowsEverySecondFrom20To0WithoutJumping() {
        let session = makeSession()
        session.start()
        var shown = [session.remainingSeconds]
        for _ in 0..<20 {
            session.tick()
            shown.append(session.remainingSeconds)
        }
        #expect(shown == Array((0...20).reversed()))
        #expect(session.currentIndex == 0)
    }

    @Test func advancesExactlyOneQuestionAfterZeroAndResetsTo20() {
        let session = makeSession()
        session.start()
        for _ in 0..<20 { session.tick() }
        #expect(session.currentIndex == 0)
        #expect(session.remainingSeconds == 0)

        session.tick()
        #expect(session.currentIndex == 1)
        #expect(session.currentQuestion.text == "Why are you interested in this position?")
        #expect(session.remainingSeconds == 20)
        #expect(session.isTimerRunning)
    }

    @Test func presentsAllQuestionsInOrderThenCompletes() {
        let session = makeSession()
        session.start()
        var presented: [Int] = [session.questionNumber]
        for _ in 0..<(10 * ticksPerQuestion) {
            session.tick()
            if session.phase == .inProgress, presented.last != session.questionNumber {
                presented.append(session.questionNumber)
            }
        }
        #expect(presented == Array(1...10))
        #expect(session.phase == .completed)
        #expect(!session.isTimerRunning)
    }

    @Test func lastQuestionCompletesAfterReachingZero() {
        let session = makeSession()
        session.start()
        for _ in 0..<(9 * ticksPerQuestion + 20) { session.tick() }
        #expect(session.phase == .inProgress)
        #expect(session.questionNumber == 10)
        #expect(session.remainingSeconds == 0)

        session.tick()
        #expect(session.phase == .completed)
    }

    @Test func startIsIgnoredOutsideWelcomeScreen() {
        let session = makeSession()
        session.start()
        for _ in 0..<(10 * ticksPerQuestion) { session.tick() }
        #expect(session.phase == .completed)
        session.start()
        #expect(session.phase == .completed)
        #expect(!session.isTimerRunning)
    }

    @Test func ticksAfterCompletionAreIgnored() {
        let session = makeSession()
        session.start()
        for _ in 0..<(10 * ticksPerQuestion + 5) { session.tick() }
        #expect(session.phase == .completed)
        #expect(session.currentIndex == 9)
        #expect(session.remainingSeconds == 0)
    }

    @Test func resetReturnsToWelcomeWithoutTimer() {
        let session = makeSession()
        session.start()
        for _ in 0..<(10 * ticksPerQuestion) { session.tick() }
        #expect(session.phase == .completed)
        session.reset()
        #expect(session.phase == .welcome)
        #expect(session.currentIndex == 0)
        #expect(session.remainingSeconds == 20)
        #expect(!session.isTimerRunning)

        session.start()
        #expect(session.phase == .inProgress)
        #expect(session.questionNumber == 1)
        #expect(session.isTimerRunning)
    }

    @Test func resetMidSessionCancelsTimer() {
        let session = makeSession()
        session.start()
        session.tick()
        session.reset()
        #expect(session.phase == .welcome)
        #expect(!session.isTimerRunning)
    }

    @Test func inactiveScenePausesAndActiveResumesFromRemainingTime() {
        let session = makeSession()
        session.start()
        for _ in 0..<12 { session.tick() }

        session.setSceneActive(false)
        #expect(!session.isTimerRunning)
        #expect(session.isSuspended)
        #expect(session.phase == .inProgress)
        #expect(session.remainingSeconds == 8)

        session.setSceneActive(true)
        #expect(session.isTimerRunning)
        #expect(session.remainingSeconds == 8)
        #expect(session.currentIndex == 0)
    }

    @Test func hiddenInterviewViewPausesTimer() {
        let session = makeSession()
        session.start()
        session.interviewViewDidDisappear()
        #expect(!session.isTimerRunning)
        session.interviewViewDidAppear()
        #expect(session.isTimerRunning)
    }

    @Test func repeatedAppearCallsDoNotDuplicateTimer() {
        let session = makeSession()
        session.start()
        session.interviewViewDidAppear()
        session.interviewViewDidAppear()
        session.setSceneActive(true)
        #expect(session.isTimerRunning)
        #expect(session.remainingSeconds == 20)
    }

    @Test func startWhileSceneInactiveWaitsForActivation() {
        let session = makeSession()
        session.setSceneActive(false)
        session.start()
        #expect(session.phase == .inProgress)
        #expect(!session.isTimerRunning)
        session.setSceneActive(true)
        #expect(session.isTimerRunning)
    }

    @Test func realTimerAdvancesAndCompletesOnItsOwn() async throws {
        let questions = Array(InterviewQuestion.standardSet.prefix(3))
        let session = InterviewSession(
            questions: questions,
            secondsPerQuestion: 3,
            tickInterval: .milliseconds(100)
        )
        session.start()

        var seenIndices: [Int] = [session.currentIndex]
        let clock = ContinuousClock()
        let started = clock.now
        while session.phase != .completed, clock.now - started < .seconds(15) {
            try await Task.sleep(for: .milliseconds(10))
            if session.phase == .inProgress, seenIndices.last != session.currentIndex {
                seenIndices.append(session.currentIndex)
            }
        }
        let elapsed = clock.now - started

        #expect(session.phase == .completed)
        #expect(seenIndices == [0, 1, 2])
        #expect(!session.isTimerRunning)
        // 12 ticks at 100 ms each; must not finish early from duplicated timers.
        #expect(elapsed >= .milliseconds(1150))
    }

    @Test func stalledMainActorDoesNotCauseCatchUpJumps() async throws {
        let session = InterviewSession(tickInterval: .milliseconds(200))
        session.start()

        // Block the main actor for the equivalent of 15 ticks.
        blockCurrentThread(seconds: 3)
        try await Task.sleep(for: .milliseconds(20))

        #expect(session.currentIndex == 0)
        #expect(session.remainingSeconds >= 19, "Timer jumped to \(session.remainingSeconds) after a stall")
        session.reset()
    }

    private func blockCurrentThread(seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
