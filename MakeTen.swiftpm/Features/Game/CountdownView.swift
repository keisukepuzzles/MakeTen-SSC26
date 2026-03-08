import SwiftUI

struct CountdownView: View {
    let selectedCity: CityType
    @State private var countdown = 3
    @State private var showGame = false
    @State private var countdownTimer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if showGame {
                CarRoadView(
                    isDemoMode: false,
                    cityType: selectedCity,
                    onRestartFromBeginning: {
                        // カウントダウンを再開
                        showGame = false
                        countdown = 3
                        startCountdown()
                    }
                )
            } else {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(selectedCity.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Are you ready to make 10?")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    ZStack {
                        if countdown > 0 {
                            Text("\(countdown)")
                                .font(.system(size: 120, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("GO!")
                                .font(.system(size: 120, weight: .bold))
                                .foregroundColor(.yellow)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: countdown)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }

    private func startCountdown() {
        // 既存のタイマーを停止
        countdownTimer?.invalidate()
        countdownTimer = nil

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                countdownTimer = nil
                // 少し待ってからゲーム開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        showGame = true
                    }
                }
            }
        }
    }
}

#Preview {
    CountdownView(selectedCity: .france)
}

