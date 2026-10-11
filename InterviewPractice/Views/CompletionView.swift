import SwiftUI

struct CompletionView: View {
    @Environment(InterviewSession.self) private var session

    var body: some View {
        VStack(spacing: 40) {
            Text("Practice Complete!")
                .font(.extraLargeTitle)
                .multilineTextAlignment(.center)

            Text("Great work! You answered all \(session.questionCount) questions. Keep practicing to build confidence for your next interview.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)

            HStack(spacing: 24) {
                Button {
                    session.reset()
                } label: {
                    Text("Practice Again")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    session.reset()
                } label: {
                    Text("Back to Home")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.extraLarge)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(windowStyle: .automatic) {
    CompletionView()
        .environment(InterviewSession())
}
