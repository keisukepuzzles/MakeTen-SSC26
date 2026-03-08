import SwiftUI

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    var onBackToStart: (() -> Void)? = nil

    init(
            score: Int,
            highScore: Int,
            onRestart: @escaping () -> Void,
            onBackToStart: (() -> Void)? = nil
        ) {
            self.score = score
            self.highScore = highScore
            self.onRestart = onRestart
            self.onBackToStart = onBackToStart
        }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Finish!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.pink)

                VStack(spacing: 12) {
                    Text("Score: \(score)")
                        .font(.title2)
                        .foregroundColor(.white)

                    if score == highScore && highScore > 0 {
                        Text("🎉 New High Score! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    } else if highScore > 0 {
                        Text("High Score: \(highScore)")
                            .font(.title3)
                            .foregroundColor(.yellow.opacity(0.85))
                    }
                    Text("Find numbers in everyday life and \n make math more accessible!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 18) {
                    Button(action: onRestart) {
                        Text("Restart")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }

                    if let onBackToStart = onBackToStart {
                        Button(action: onBackToStart) {
                            Text("Back to Home")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.gray)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    GameOverView(score: 100, highScore: 150, onRestart: {}, onBackToStart: nil)
}
