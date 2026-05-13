import SwiftUI

struct ClockView: View {
    let viewModel: LiveGameViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Start / Pause
            Button {
                if viewModel.isClockRunning {
                    viewModel.pauseClock()
                } else {
                    viewModel.startClock()
                }
            } label: {
                Image(systemName: viewModel.isClockRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.isClockRunning ? .orange : .green)
            }
            .disabled(viewModel.game.status == .fullTime)

            Text(viewModel.elapsedSeconds.clockString)
                .font(.title3.monospacedDigit().bold())
                .frame(width: 72)

            Spacer()

            // Half-time / Full-time controls
            switch viewModel.game.status {
            case .notStarted:
                EmptyView()
            case .firstHalf:
                Button("Half Time") {
                    viewModel.advanceToHalfTime()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            case .halfTime:
                Button("2nd Half") {
                    viewModel.startClock()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            case .secondHalf:
                Button("Full Time") {
                    viewModel.endGame()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            case .fullTime:
                Text("Full Time")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}
