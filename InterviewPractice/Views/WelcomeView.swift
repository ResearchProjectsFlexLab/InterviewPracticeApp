import SwiftUI

struct WelcomeView: View {
    @Environment(InterviewSession.self) private var session

    var body: some View {
        VStack(spacing: 40) {
            Text("Interview Practice")
                .font(.extraLargeTitle)
                .multilineTextAlignment(.center)

            Text("This session contains \(session.questionCount) questions. You'll have \(session.secondsPerQuestion) seconds to answer each one.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)

            Button {
                session.start()
            } label: {
                Text("Start Practice")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(windowStyle: .automatic) {
    WelcomeView()
        .environment(InterviewSession())
}
