import SwiftUI

@main
struct InterviewPracticeApp: App {
    @State private var session = InterviewSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .defaultSize(width: 960, height: 680)
        .windowResizability(.contentMinSize)
    }
}
