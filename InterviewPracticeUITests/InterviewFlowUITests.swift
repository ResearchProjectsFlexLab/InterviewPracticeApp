import XCTest

final class InterviewFlowUITests: XCTestCase {
    private let questions = [
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

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFullSessionRunsAutomaticallyAndResets() throws {
        let app = XCUIApplication()
        app.launch()

        // Welcome screen: the timer must not start on its own.
        XCTAssertTrue(app.staticTexts["Interview Practice"].waitForExistence(timeout: 120))
        let startButton = app.buttons["Start Practice"]
        XCTAssertTrue(startButton.exists)
        attachScreenshot(app, named: "1-Welcome")
        sleep(3)
        XCTAssertFalse(app.staticTexts["Question 1 of 10"].exists)

        startButton.tap()

        let countdown = app.descendants(matching: .any).matching(identifier: "countdown").firstMatch
        var previousAppearance: Date?

        for (index, question) in questions.enumerated() {
            let label = app.staticTexts["Question \(index + 1) of 10"]
            XCTAssertTrue(label.waitForExistence(timeout: index == 0 ? 15 : 40), "Question \(index + 1) never appeared")
            let appearedAt = Date()
            XCTAssertTrue(app.staticTexts[question].exists, "Wrong text for question \(index + 1)")

            if let previousAppearance {
                let interval = appearedAt.timeIntervalSince(previousAppearance)
                XCTAssertEqual(interval, 21, accuracy: 4, "Question \(index + 1) appeared after \(interval)s")
            }
            previousAppearance = appearedAt

            // No controls of any kind on the interview screen.
            XCTAssertEqual(app.buttons.count, 0, "Interview screen must not contain buttons")
            XCTAssertFalse(app.progressIndicators.firstMatch.exists)

            if index == 0 {
                XCTAssertTrue(countdown.exists)
                let first = secondsRemaining(countdown)
                sleep(3)
                let later = secondsRemaining(countdown)
                XCTAssertLessThan(later, first, "Countdown is not decreasing")
                XCTAssertGreaterThanOrEqual(first, 17)
                attachScreenshot(app, named: "2-Question1")
            }
            if index == 1 {
                attachScreenshot(app, named: "3-Question2")
            }
        }

        // Completion screen after question 10's countdown.
        XCTAssertTrue(app.staticTexts["Practice Complete!"].waitForExistence(timeout: 40))
        if let previousAppearance {
            XCTAssertEqual(Date().timeIntervalSince(previousAppearance), 21, accuracy: 4)
        }
        XCTAssertTrue(app.buttons["Practice Again"].exists)
        XCTAssertTrue(app.buttons["Back to Home"].exists)
        attachScreenshot(app, named: "4-Complete")

        app.buttons["Practice Again"].tap()

        XCTAssertTrue(app.buttons["Start Practice"].waitForExistence(timeout: 15))
        sleep(5)
        XCTAssertFalse(app.staticTexts["Question 1 of 10"].exists, "Timer started without pressing Start Practice")
        XCTAssertTrue(app.buttons["Start Practice"].exists)
        attachScreenshot(app, named: "5-AfterPracticeAgain")
    }

    @MainActor
    private func secondsRemaining(_ element: XCUIElement) -> Int {
        Int(element.label.split(separator: " ").first ?? "") ?? -1
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
