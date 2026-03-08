import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var sampleNumbers = "248"

    var body: some View {
        if isActive {
            TutorialView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("MakeTen with Plate")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                            .opacity(opacity)

                        Text("Let's make the number 10 using \n the digits on the license plate.")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.85))
                            .opacity(opacity)
                    }

                    SplashNumberPlateView(numbers: sampleNumbers)
                        .scaleEffect(opacity == 1.0 ? 1.0 : 0.9)
                        .opacity(opacity)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                }
            }
            .onAppear {
                sampleNumbers = "248"

                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct SplashNumberPlateView: View {
    let numbers: String

    private let leftLetters: String
    private let rightLetters: String

    init(numbers: String) {
        self.numbers = numbers
        self.leftLetters = SplashNumberPlateView.randomLetters(count: 2)
        self.rightLetters = SplashNumberPlateView.randomLetters(count: 2)
    }

    private var plateText: String {
        "\(leftLetters)-\(numbers)-\(rightLetters)"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(width: 260, height: 110)
            .overlay(
                Text(plateText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .kerning(4)
                    .foregroundColor(.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 4)
            )
    }

    private static func randomLetters(count: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<count).compactMap { _ in letters.randomElement() })
    }
}

#Preview {
    SplashView()
}

