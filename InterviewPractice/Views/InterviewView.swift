import SwiftUI

/// Shows the active question and its countdown. Has no controls: questions advance automatically.
struct InterviewView: View {
    @Environment(InterviewSession.self) private var session

    var body: some View {
        VStack(spacing: 36) {
            Text("Question \(session.questionNumber) of \(session.questionCount)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.currentQuestion.text)
                .font(.system(size: 48, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 760)
                .padding(.horizontal, 48)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: .rect(cornerRadius: 36))

            VStack(spacing: 4) {
                Text("\(session.remainingSeconds)")
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(session.remainingSeconds == 1 ? "second remaining" : "seconds remaining")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(session.remainingSeconds) seconds remaining")
            .accessibilityIdentifier("countdown")
        }
        .padding(56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { session.interviewViewDidAppear() }
        .onDisappear { session.interviewViewDidDisappear() }
    }
}

#Preview(windowStyle: .automatic) {
    let session = InterviewSession()
    session.start()
    return InterviewView()
        .environment(session)
}
