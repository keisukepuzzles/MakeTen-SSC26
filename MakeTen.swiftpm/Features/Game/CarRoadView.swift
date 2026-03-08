import SwiftUI

struct CarRoadView: View {
    var hideLifeLines: Bool = false
    let isDemoMode: Bool
    var cityType: CityType? = nil
    var onRestartFromBeginning: (() -> Void)? = nil

    init(hideLifeLines: Bool = false, isDemoMode: Bool, cityType: CityType? = nil, onRestartFromBeginning: (() -> Void)? = nil) {
        self.hideLifeLines = hideLifeLines
        self.isDemoMode = isDemoMode
        self.cityType = cityType
        self.onRestartFromBeginning = onRestartFromBeginning
    }
    @State private var gameManager = GameManager()
    // デモ用(背景)では車・ライフ変動/入力受付等をストップ

    @State private var timer: Timer?
    @State private var spawnTimer: Timer?
    @State private var regularSpawnTimer: Timer?
    @State private var selectedCar: Car? = nil
    @State private var showQuiz = false
    @State private var showGameOver = false
    @State private var showSuccessMessage = false
    @State private var carRemovedWhileQuizOpen = false
    @State private var scoreAnimation: ScoreAnimation? = nil
    @State private var comboAnimationScale: CGFloat = 1.0
    @State private var previousComboCount: Int = 0
    @State private var isPaused = false
    @State private var wasPaused = false
    @State private var pauseCount = 0
    @State private var lastPauseTime: Date? = nil
    @State private var showPauseButton = true
    @State private var hasTappedFirstCar = false
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    private var backgroundImageName: String {
        cityType?.backgroundImageName ?? "road_default"
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 道路の背景色（上部に余白を設ける）
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: geometry.size.height - gameManager.roadTopOffset)
                    .position(x: geometry.size.width / 2, y: gameManager.roadTopOffset + (geometry.size.height - gameManager.roadTopOffset) / 2)

                // 道路の背景画像
                Image (backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height - gameManager.roadTopOffset)
                    .position(x: geometry.size.width / 2, y: gameManager.roadTopOffset + (geometry.size.height - gameManager.roadTopOffset) / 2)
                    .foregroundColor(.gray.opacity(0.3))

                // 下のライフライン（横向きの線）- 画面の下の方に配置（上から下の車用）
                if !hideLifeLines {
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: geometry.size.width, height: 2)
                        .position(x: geometry.size.width / 2, y: gameManager.roadTopOffset + gameManager.bottomLifeLine)

                    // 上のライフライン（横向きの線）- 道路の一番上に配置（下から上の車用）
                    Rectangle()
                        .fill(Color.red.opacity(0.5))
                        .frame(width: geometry.size.width, height: 2)
                        .position(x: geometry.size.width / 2, y: gameManager.roadTopOffset + gameManager.topLifeLine)
                }

                // 車を表示（道路の位置に合わせて調整）
                ForEach(gameManager.cars) { car in
                    CarView(car: car)
                        .position(x: car.xPosition, y: gameManager.roadTopOffset + car.yPosition)
                        .onTapGesture {
                            if !hasTappedFirstCar {
                                   hasTappedFirstCar = true
                               }
                            selectedCar = car
                            showQuiz = true
                        }
                }

                if !isDemoMode {
                    // 左上にポーズボタン
                    VStack {
                        HStack {
                            if showPauseButton && !showGameOver && !showQuiz {
                                Button(action: {
                                    // ポーズ連打対策：3秒以内に3回以上押したら無効
                                    let now = Date()
                                    if let lastTime = lastPauseTime, now.timeIntervalSince(lastTime) < 3.0 {
                                        pauseCount += 1
                                        if pauseCount >= 3 {
                                            // 3回以上連続で押されたら一時的にボタンを無効化
                                            showPauseButton = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                                pauseCount = 0
                                                showPauseButton = true
                                            }
                                            return
                                        }
                                    } else {
                                        pauseCount = 1
                                    }
                                    lastPauseTime = now

                                    // ポーズ処理
                                    stopGame()
                                    isPaused = true
                                }) {
                                    Image(systemName: "pause.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }

                    // 上部にライフとスコア表示（道路と被らないように）
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Text("TIME:")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("\(Int(gameManager.remainingTime))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(
                                    gameManager.remainingTime <= 10 ? .red : .green
                                )
                            if gameManager.showTimeBonus {
                                    TimeBonusInlineView(text: gameManager.timeBonusText)
                                        .transition(
                                            .move(edge: .trailing).combined(with: .opacity)
                                        )
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        // 総合スコア表示
                        HStack(spacing: 8) {
                            Text("SCORE:")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(gameManager.totalScore)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                                .scaleEffect(scoreAnimation != nil ? 1.3 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scoreAnimation != nil)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)

                        // コンボ表示
                        if gameManager.comboCount > 1 {
                            HStack(spacing: 8) {
                                Text("COMBO")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("\(gameManager.comboCount)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.orange.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.orange, lineWidth: 2)
                                    )
                            )
                            .scaleEffect(comboAnimationScale)
                            .onChange(of: gameManager.comboCount) { newValue in
                                // コンボ数が変わった時だけアニメーションを実行
                                if newValue > 1 && newValue != previousComboCount {
                                    comboAnimationScale = 1.2
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        comboAnimationScale = 1.0
                                    }
                                    previousComboCount = newValue
                                } else if newValue <= 1 {
                                    // コンボがリセットされた時
                                    previousComboCount = 0
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .top)
                    
                    if !hasTappedFirstCar {
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(height: gameManager.topLifeLine)
                                .allowsHitTesting(false)

                            Spacer()
                        }
                        .ignoresSafeArea()

                        VStack {
                            VStack(spacing: 8) {
                                Text("Tap the Car !")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)

                            Spacer()
                        }
                        .padding(.top, 40) // ← スコア表示に被る位置
                        .transition(.opacity)
                    }
                // 計算画面を中央に表示
                if showQuiz, let car = selectedCar {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    // タップで閉じないようにする（削除）

                    if showSuccessMessage {
                        // 成功メッセージを表示
                        VStack(spacing: 20) {
                            Text("You made 10！🎉")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
                        .background(Color.clear) // 背景を透明に
                    } else {
                        CalculateQuizView(
                            carNumbers: car.numbers,
                            onDismiss: {
                                if !showSuccessMessage {
                                    showQuiz = false
                                }
                            },
                            onSuccess: {
                                // 成功時の処理 - 10ができた瞬間に車を削除
                                if let car = selectedCar {
                                    gameManager.removeCar(id: car.id)
                                    let result = gameManager.increaseDifficulty(carColor: car.color)
                                    gameManager.addTimeBonus(1.0)
                                    // スコアエフェクトを表示
                                    scoreAnimation = ScoreAnimation(
                                        basePoints: result.basePoints,
                                        comboBonus: result.comboBonus,
                                        totalPoints: result.totalPoints,
                                        color: car.color
                                    )
                                    // コンボアニメーション（onChangeで処理されるためここでは不要）
                                    // エフェクトを消す
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        scoreAnimation = nil
                                    }
                                }
                                // 成功メッセージを表示してから画面を閉じる
                                showSuccessMessage = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    showSuccessMessage = false
                                    showQuiz = false
                                    selectedCar = nil
                                }
                            }
                        )
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
                        .background(Color.clear) // 背景を透明に
                    }
                }

                // スコアエフェクト表示
                if let animation = scoreAnimation {
                    ScoreEffectView(animation: animation)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
                }


                // ゲームオーバー画面
                if showGameOver {
                    GameOverView(
                        score: gameManager.totalScore,
                        highScore: UserDefaults.standard.integer(forKey: "highScore"),
                        onRestart: {
                            showGameOver = false
                            stopGame()
                            
                            // 状態リセット（再生成しない）
                            gameManager.cars.removeAll()
                            gameManager.remainingTime = gameManager.timeLimit
                            gameManager.totalScore = 0
                            gameManager.comboCount = 0
                            gameManager.correctCount = 0
                            gameManager.hasFirstCorrect = false
                            gameManager.lastCorrectTime = nil

                            setupGame(geometry: geometry)
                            startGame()
                        },
                        onBackToStart: {
                            dismiss()
                        }
                    )
                }
            }
                // ポーズ画面（最前面に表示）
                if isPaused {
                    PauseView(
                        onRestart: {
                            // カウントダウンから再開
                            stopGame()
                            if let onRestart = onRestartFromBeginning {
                                onRestart()
                            } else {
                                // コールバックがない場合は直接リセット
                                isPaused = false
                                wasPaused = false
                                stopGame()

                                gameManager.cars.removeAll()
                                gameManager.remainingTime = gameManager.timeLimit
                                gameManager.totalScore = 0
                                gameManager.comboCount = 0
                                gameManager.correctCount = 0
                                gameManager.hasFirstCorrect = false
                                gameManager.lastCorrectTime = nil
                                setupGame(geometry: geometry)
                                startGame()
                            }
                        },
                        onResume: {
                            isPaused = false
                            wasPaused = false
                            startGame()
                        },
                        onBackToStart: {
                            dismiss()
                        }
                    )
                }
            }
            .onAppear {
                setupGame(geometry: geometry)
                gameManager.remainingTime = gameManager.timeLimit
                gameManager.setupSpawnPositions() // 出現位置を設定
                if let cityType = cityType {
                    gameManager.setCityType(cityType)
                }
                if !wasPaused {
                    startGame()
                }
            }
            .onChange(of: geometry.size) { _ in
                // 画面サイズが変わった時やゲームオーバー後に再設定
                setupGame(geometry: geometry)
            }
            .onDisappear {
                stopGame()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background, .inactive:
                    // アプリがバックグラウンドに入ったら一時停止
                    if !isPaused && !showGameOver {
                        stopGame()
                        isPaused = true
                        wasPaused = true
                    }
                case .active:
                    // アプリがフォアグラウンドに戻ったらポーズ画面を表示（即座に）
                    if wasPaused && !showGameOver {
                        // ゲームを停止したままにして、ポーズ画面を表示
                        isPaused = true
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    private func startGame() {
        // 初期車を生成（車が存在しない場合のみ）
        if gameManager.cars.isEmpty {
            gameManager.spawnCar()
        }

        // タイマーで車を動かす
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            gameManager.tick()



            // 車が削除されたときに計算画面を閉じる
            if showQuiz, let car = selectedCar {
                if !gameManager.cars.contains(where: { $0.id == car.id }) {
                    showQuiz = false
                    showSuccessMessage = false
                    selectedCar = nil
                }
            }

            // ライフが0になったらゲームオーバー
            if gameManager.remainingTime <= 0 {
                stopGame()
                // ハイスコアを記録
                let currentHighScore = UserDefaults.standard.integer(forKey: "highScore")
                if gameManager.totalScore > currentHighScore {
                    UserDefaults.standard.set(gameManager.totalScore, forKey: "highScore")
                }
                showGameOver = true
            }

        }



        var lastSpawnDate = Date()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard !isPaused else { return }


            let now = Date()
            let elapsed = now.timeIntervalSince(lastSpawnDate)
            
                let spawnInterval: TimeInterval
                switch gameManager.remainingTime {
                case 0..<10:
                    spawnInterval = 2.0
                case 10..<30:
                    spawnInterval = 2.5
                default:
                    spawnInterval = 3.0
                }

                if elapsed >= spawnInterval || gameManager.cars.isEmpty {
                    gameManager.spawnCar()
                    lastSpawnDate = now
                }
        }
    }

    private func stopGame() {
        timer?.invalidate()
        timer = nil
        spawnTimer?.invalidate()
        spawnTimer = nil
        regularSpawnTimer?.invalidate()
        regularSpawnTimer = nil
    }

    private func setupGame(geometry: GeometryProxy) {
        gameManager.roadWidth = geometry.size.width
        gameManager.roadHeight = geometry.size.height - gameManager.roadTopOffset
        gameManager.bottomLifeLine = (geometry.size.height - gameManager.roadTopOffset) * 1.0 // 道路の100%の位置にライン（下の方）
        gameManager.topLifeLine = 0 // 道路の一番上（0の位置）にライン
        gameManager.setupSpawnPositions() // 出現位置を設定
    }
}

#Preview {
    CarRoadView(isDemoMode: false)
}

