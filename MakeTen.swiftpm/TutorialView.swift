import SwiftUI

struct TutorialView: View {
    @State private var currentStep = -2
    @State private var showStartView = false
    @State private var carX: CGFloat = -400
    @State private var zoomScale: CGFloat = 1.0
    @State private var showStepMinusOneText = false
    @State private var carScale: CGFloat = 0.3
    @State private var carOpacity: Double = 1.0
    @State private var plateOffsetY: CGFloat = 0
    @State private var fallingPlateOffsetY: CGFloat = -500
    @State private var showFallingPlate = false
    @State private var plateFixed = false
    @State private var introScale: CGFloat = 0.3
    @State private var introOffsetY: CGFloat = -200
    @State private var showIntroCar = false
    @State private var plateArrived = false


    var body: some View {
        if showStartView {
            StartView()
        } else {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()

                // 導入画面
                if currentStep == -2 {
                    VStack(spacing: 40) {
                        VStack(spacing: 16) {
                            Text("MakeTen with Plate")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)

                            Text("You can find numbers everywhere in everyday life.\nIn this game, we’ll focus on license plates!")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .opacity(0.8)
                            .animation(
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true),
                                value: currentStep
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    currentStep = -1
                                }
                            }
                    }
                }

                if currentStep == -1 {
                    ZStack {
                        Color.black.opacity(0.9)
                            .ignoresSafeArea()

                        // ===== 車が走るシーン =====
                        ZStack {
                                    // ===== テキスト =====
                                    if showStepMinusOneText {
                                        tutorialTextView
                                            .transition(.opacity)
                                    }
                            
                        }
                        .offset(y: plateOffsetY)
                    }
                    .onAppear {
                        showStepMinusOneText = false
                        startStepMinusOneAnimation()
                    }
                }

                // チュートリアル本編
                else {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            TutorialStepView(
                                step: 0,
                                isActive: currentStep == 0,
                                title: "Let's try 3 + 7",
                                instruction: "Press in this order: 3 → + → 7",
                                numbers: [3, 7],
                                operators: [.plus],
                                onComplete: {
                                    withAnimation {
                                        currentStep = 1
                                    }
                                }
                            )
                            .frame(width: geometry.size.width)

                            TutorialStepView(
                                step: 1,
                                isActive: currentStep == 1,
                                title: "Let's try 2 × 5",
                                instruction: "Press in this order: 2 → × → 5",
                                numbers: [2, 5],
                                operators: [.plus, .multiply],
                                onComplete: {
                                    withAnimation {
                                        currentStep = 2
                                    }
                                }
                            )
                            .frame(width: geometry.size.width)

                            TutorialStepView(
                                step: 2,
                                isActive: currentStep == 2,
                                title: "Let's make 10\nusing 2,3,and 4.",
                                instruction: "Hint: Combine 6 and 4 to make 10!",
                                numbers: [2,3,4],
                                operators: [.plus, .multiply],
                                onComplete: {
                                    withAnimation {
                                        showStartView = true
                                    }
                                }
                            )
                            .frame(width: geometry.size.width)
                        }
                        .offset(x: -CGFloat(currentStep) * geometry.size.width)
                    }
                }
            }
        }
    }
    
    private var tutorialTextView: some View {
        VStack(spacing: 30) {

            Text("For example…")
                .font(.headline)
                .foregroundColor(.yellow)

            ZStack {
                // 最終的に残るナンバー
                if plateArrived {
                    LicensePlateView(numbers: [2,4,8])
                }

                // 車＋ナンバー（奥から来る）
                if showIntroCar {
                    ZStack {
                        Image("carImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 800)
                            .opacity(carOpacity)

                        LicensePlateView(numbers: [2,4,8] , width: 120)
                            .frame(width: 120)
                            .offset(y: 25)
                    }
                    .scaleEffect(introScale)
                    .offset(y: introOffsetY)
                }
            }
            .frame(height: 150)

            VStack(spacing: 8) {
                Text("The number “248” on the plate")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))

                Text("Use all three of these\nnumbers to make 10!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text("Tap to proceed to the tutorial!")
                .font(.headline)
                .foregroundColor(.yellow)
                .opacity(0.8)
                .onTapGesture {
                    withAnimation {
                        currentStep = 0
                    }
                }
        }
    }
    
    private func startStepMinusOneAnimation() {

        showStepMinusOneText = true
        showIntroCar = true
        plateArrived = false

        introScale = 0.3
        introOffsetY = -200
        carOpacity = 1.0

        // ① 奥から手前へ
        withAnimation(.easeOut(duration: 2.0)) {
            introScale = 1.0
            introOffsetY = 0
        }

        // ② 車だけ消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                carOpacity = 0.0
            }
        }

        // ③ ナンバー固定
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            plateArrived = true
            showIntroCar = false
        }
    }
    
}

struct LicensePlateView: View {
    let numbers: [Int]
    var width: CGFloat = 220   // ← デフォルトサイズ

    private var numbersText: String {
        numbers.map(String.init).joined()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: width, height: width * (120/280))
            .overlay(
                Text(numbersText)
                    .font(.system(size: width * 0.25, weight: .bold, design: .rounded))
                    .kerning(width * 0.02)
                    .foregroundColor(.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 4)
            )
    }
}

struct TutorialNumberPlateSampleView: View {
    let numbers: [Int]

    private var numbersText: String {
        numbers.map(String.init).joined()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .frame(width: 260, height: 100)
            .overlay(
                Text("\(numbersText)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .kerning(3)
                    .foregroundColor(.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black, lineWidth: 3)
            )
    }
}

#Preview {
    TutorialView()
}

