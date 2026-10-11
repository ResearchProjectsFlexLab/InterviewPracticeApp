import SwiftUI

struct RootView: View {
    @Environment(InterviewSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch session.phase {
            case .welcome:
                WelcomeView()
            case .inProgress:
                InterviewView()
            case .completed:
                CompletionView()
            }
        }
        .frame(minWidth: 640, minHeight: 520)
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            session.setSceneActive(newPhase == .active)
        }
    }
}

#Preview(windowStyle: .automatic) {
    RootView()
        .environment(InterviewSession())
}
