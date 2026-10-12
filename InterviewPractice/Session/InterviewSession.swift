import Foundation
import Observation

/// Single source of truth for the practice session: which screen is shown,
/// which question is active, how many seconds remain, and the countdown task.
@MainActor
@Observable
final class InterviewSession {
    enum Phase: Equatable {
        case welcome
        case inProgress
        case completed
    }

    /// Reasons the countdown is temporarily held while a session is in progress.
    enum SuspensionReason: Hashable {
        case sceneInactive
        case interviewViewHidden
    }

    let questions: [InterviewQuestion]
    let secondsPerQuestion: Int

    private(set) var phase: Phase = .welcome
    private(set) var currentIndex: Int = 0
    private(set) var remainingSeconds: Int

    @ObservationIgnored private let tickInterval: Duration
    @ObservationIgnored private let clock = ContinuousClock()
    @ObservationIgnored private var suspensionReasons: Set<SuspensionReason> = []
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    /// Identifies the live timer task; a task whose generation is stale must never tick.
    @ObservationIgnored private var timerGeneration: UInt64 = 0
    @ObservationIgnored private var nextTickDeadline: ContinuousClock.Instant?
    /// Unused part of the current one-second tick, carried over across a suspension.
    @ObservationIgnored private var carriedOverDelay: Duration?

    init(
        questions: [InterviewQuestion] = InterviewQuestion.standardSet,
        secondsPerQuestion: Int = 20,
        tickInterval: Duration = .seconds(1)
    ) {
        precondition(!questions.isEmpty, "A session needs at least one question.")
        precondition(secondsPerQuestion > 0, "Each question needs a positive duration.")
        self.questions = questions
        self.secondsPerQuestion = secondsPerQuestion
        self.tickInterval = tickInterval
        self.remainingSeconds = secondsPerQuestion
    }

    var currentQuestion: InterviewQuestion { questions[currentIndex] }
    var questionNumber: Int { currentIndex + 1 }
    var questionCount: Int { questions.count }
    var isTimerRunning: Bool { timerTask != nil }
    var isSuspended: Bool { !suspensionReasons.isEmpty }

    // MARK: - Session control

    /// Begins a new session at question 1. Only valid from the welcome screen.
    func start() {
        guard phase == .welcome else { return }
        stopTimer(preservingProgress: false)
        currentIndex = 0
        remainingSeconds = secondsPerQuestion
        suspensionReasons.remove(.interviewViewHidden)
        phase = .inProgress
        updateTimer()
    }

    /// Ends any session and returns to the welcome screen without a running timer.
    func reset() {
        stopTimer(preservingProgress: false)
        currentIndex = 0
        remainingSeconds = secondsPerQuestion
        suspensionReasons.remove(.interviewViewHidden)
        phase = .welcome
    }

    // MARK: - Lifecycle

    func setSceneActive(_ isActive: Bool) {
        setSuspended(!isActive, for: .sceneInactive)
    }

    func interviewViewDidAppear() {
        setSuspended(false, for: .interviewViewHidden)
    }

    func interviewViewDidDisappear() {
        setSuspended(true, for: .interviewViewHidden)
    }

    private func setSuspended(_ suspended: Bool, for reason: SuspensionReason) {
        if suspended {
            suspensionReasons.insert(reason)
        } else {
            suspensionReasons.remove(reason)
        }
        updateTimer()
    }

    // MARK: - Countdown

    /// Advances the countdown by exactly one step. Called once per tick by the timer task.
    /// Counts `secondsPerQuestion` down to 0, then the following tick moves to the next question.
    func tick() {
        guard phase == .inProgress else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            return
        }

        if currentIndex + 1 < questions.count {
            currentIndex += 1
            remainingSeconds = secondsPerQuestion
        } else {
            phase = .completed
            stopTimer(preservingProgress: false)
        }
    }

    /// Starts or stops the timer task so it runs exactly when it should; safe to call repeatedly.
    private func updateTimer() {
        let shouldRun = phase == .inProgress && suspensionReasons.isEmpty
        if shouldRun {
            if timerTask == nil { startTimer() }
        } else if timerTask != nil {
            stopTimer(preservingProgress: phase == .inProgress)
        }
    }

    private func startTimer() {
        let interval = tickInterval
        let clock = clock
        var delay = carriedOverDelay ?? interval
        carriedOverDelay = nil

        timerGeneration &+= 1
        let generation = timerGeneration

        timerTask = Task { [weak self] in
            while true {
                // Each wake-up is scheduled relative to the previous one finishing, so a stalled
                // main actor yields one late tick instead of a burst of catch-up ticks.
                self?.nextTickDeadline = clock.now.advanced(by: delay)
                do {
                    try await clock.sleep(for: delay)
                } catch {
                    return
                }
                guard let self, !Task.isCancelled, self.timerGeneration == generation else { return }
                self.tick()
                guard self.phase == .inProgress, self.timerGeneration == generation else { return }
                delay = interval
            }
        }
    }

    private func stopTimer(preservingProgress: Bool) {
        if preservingProgress, let deadline = nextTickDeadline {
            let remaining = clock.now.duration(to: deadline)
            carriedOverDelay = min(max(remaining, .zero), tickInterval)
        } else {
            carriedOverDelay = nil
        }
        timerTask?.cancel()
        timerTask = nil
        timerGeneration &+= 1
        nextTickDeadline = nil
    }
}
