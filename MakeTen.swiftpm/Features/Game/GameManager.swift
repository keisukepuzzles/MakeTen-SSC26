//
//  GameManager.swift
//  MakeTen
//
//  Created by 梶原景介 on 2025/11/30.
//

import SwiftUI

// 8箇所の出現位置
struct SpawnPosition {
    let x: CGFloat
    let y: CGFloat
    let direction: CarDirection
    let isFlipped: Bool
}

struct TimeBonusView: View {
    let text: String

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.85

    var body: some View {
            Text(text)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial) // 🌊 Liquid Glass
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.8),
                                            .white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .green.opacity(0.35), radius: 12)
                .scaleEffect(scale)
                .offset(y: offsetY)
                .opacity(opacity)
                .onAppear {
                    // 出現（ぷるっ）
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        opacity = 1
                        offsetY = 0
                        scale = 1.0
                    }

                    // 少し待ってから消える
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            opacity = 0
                            offsetY = -40
                            scale = 0.9
                        }
                    }
                }
        }
}

enum SpawnMode {
    case mode1 // 位置1-4を使用
    case mode2 // 位置5-8を使用
    case mode3 // 全位置を使用
    case custom([Int]) // カスタム位置（0-7のインデックス）
}

@Observable
class GameManager {
    var cars: [Car] = []
    var roadWidth: CGFloat = 300
    var roadHeight: CGFloat = 800
    var roadTopOffset: CGFloat = 120 // 道路の上部オフセット
    var bottomLifeLine: CGFloat = 800 // 下のライフラインの位置（上から下の車用）
    var topLifeLine: CGFloat = 125 // 上のライフラインの位置（下から上の車用）
    var correctCount: Int = 0 // 正解回数（難易度に使用）
    var difficultyLevel: Int = 1 // 難易度レベル
    var totalScore: Int = 0 // 総合スコア
    var comboCount: Int = 0 // コンボ数
    var lastCorrectTime: Date? = nil // 最後に正解した時間
    let comboTimeLimit: TimeInterval = 10.0 // コンボ継続時間（秒）
    var spawnMode: SpawnMode = .mode1 // 出現モード
    var spawnPositions: [SpawnPosition] = [] // 8箇所の出現位置
    var cityType: CityType? = nil // 選択された都市タイプ
    var hasFirstCorrect: Bool = false // 最初の正解をしたかどうか
    var timeLimit: TimeInterval = 60.0   // 制限時間（秒）
    var remainingTime: TimeInterval = 60.0
    var showTimeBonus: Bool = false
    var timeBonusText: String = "+1s"


    // 色ごとの点数
    func getPointsForColor(_ color: Color) -> Int {
        switch color {
        case .red: return 3
        case .blue: return 5
        case .green: return 7
        case .yellow: return 10
        default: return 0
        }
    }

    // コンボボーナスを計算
    func getComboBonus() -> Int {
        if comboCount <= 1 {
            return 0
        } else if comboCount <= 3 {
            return comboCount * 2 // 2-3コンボ: コンボ数×2
        } else if comboCount <= 5 {
            return comboCount * 3 // 4-5コンボ: コンボ数×3
        } else {
            return comboCount * 5 // 6コンボ以上: コンボ数×5
        }
    }

    func setCityType(_ cityType: CityType) {
        self.cityType = cityType
        self.hasFirstCorrect = false
        setupSpawnPositions() // ← 忘れず呼ぶ
    }

    func setupSpawnPositions() {
        guard let cityType = cityType else { return }
        let isRightHandTraffic: Bool
        switch cityType {
            case .france, .america:
                isRightHandTraffic = true   // 右側通行
            case .japan:
                isRightHandTraffic = false  // 左側通行
            }
        // 8箇所の出現位置を設定（日本版：左側通行）
        // 左の2車線（位置0,1,4,5）: 下から上
        // 右の2車線（位置2,3,6,7）: 上から下
        if isRightHandTraffic {
                // 🇫🇷🇺🇸 右側通行
                // 右の2車線（位置2,3,6,7）: 下から上
                // 左の2車線（位置0,1,4,5）: 上から下
                spawnPositions = [
                    // 位置0,1: 左側、上から下
                    SpawnPosition(x: roadWidth * 0.175, y: roadTopOffset - 100, direction: .down, isFlipped: false),
                    SpawnPosition(x: roadWidth * 0.375, y: roadTopOffset - 100, direction: .down, isFlipped: false),

                    // 位置2,3: 右側、下から上
                    SpawnPosition(x: roadWidth * 0.625, y: roadHeight, direction: .up, isFlipped: true),
                    SpawnPosition(x: roadWidth * 0.875, y: roadHeight, direction: .up, isFlipped: true),

                    // 位置4,5: 左側、上から下
                    SpawnPosition(x: roadWidth * 0.175, y: roadTopOffset - 100, direction: .down, isFlipped: false),
                    SpawnPosition(x: roadWidth * 0.375, y: roadTopOffset - 100, direction: .down, isFlipped: false),

                    // 位置6,7: 右側、下から上
                    SpawnPosition(x: roadWidth * 0.625, y: roadHeight, direction: .up, isFlipped: true),
                    SpawnPosition(x: roadWidth * 0.875, y: roadHeight, direction: .up, isFlipped: true)
                ]
            } else {
                // 🇯🇵 左側通行（今まで通り）
                spawnPositions = [
                    // 位置0,1: 左側、下から上
                    SpawnPosition(x: roadWidth * 0.175, y: roadHeight, direction: .up, isFlipped: true),
                    SpawnPosition(x: roadWidth * 0.375, y: roadHeight, direction: .up, isFlipped: true),

                    // 位置2,3: 右側、上から下
                    SpawnPosition(x: roadWidth * 0.625, y: roadTopOffset - 100, direction: .down, isFlipped: false),
                    SpawnPosition(x: roadWidth * 0.875, y: roadTopOffset - 100, direction: .down, isFlipped: false),

                    // 位置4,5: 左側、下から上
                    SpawnPosition(x: roadWidth * 0.175, y: roadHeight, direction: .up, isFlipped: true),
                    SpawnPosition(x: roadWidth * 0.375, y: roadHeight, direction: .up, isFlipped: true),

                    // 位置6,7: 右側、上から下
                    SpawnPosition(x: roadWidth * 0.625, y: roadTopOffset - 100, direction: .down, isFlipped: false),
                    SpawnPosition(x: roadWidth * 0.875, y: roadTopOffset - 100, direction: .down, isFlipped: false)
                ]
            }
    }

    // 出現位置をカスタマイズするメソッド（ユーザーが調整可能）
    func setSpawnPosition(index: Int, x: CGFloat, y: CGFloat, direction: CarDirection, isFlipped: Bool) {
        guard index >= 0 && index < 8 else { return }
        if index < spawnPositions.count {
            spawnPositions[index] = SpawnPosition(x: x, y: y, direction: direction, isFlipped: isFlipped)
        }
    }

    // 出現位置を取得するメソッド
    func getSpawnPosition(index: Int) -> SpawnPosition? {
        guard index >= 0 && index < spawnPositions.count else { return nil }
        return spawnPositions[index]
    }

    func getAvailableSpawnIndices() -> [Int] {
        switch spawnMode {
        case .mode1:
            return [0, 1, 2, 3] // 位置1-4
        case .mode2:
            return [4, 5, 6, 7] // 位置5-8
        case .mode3:
            return [0, 1, 2, 3, 4, 5, 6, 7] // 全位置
        case .custom(let indices):
            return indices
        }
    }

    func addTimeBonus(_ seconds: TimeInterval) {
        remainingTime = min(timeLimit, remainingTime + seconds)
        timeBonusText = "+\(Int(seconds))s"
        showTimeBonus = true

        // 1秒後に自動で消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showTimeBonus = false
        }
    }
    
    func resetForRestart() {
        cars.removeAll()

        correctCount = 0
        difficultyLevel = 1
        totalScore = 0
        comboCount = 0
        lastCorrectTime = nil
        hasFirstCorrect = false

        remainingTime = timeLimit
        showTimeBonus = false

        // ⭐️ cityType は触らない
        setupSpawnPositions()
    }

    func spawnCar() {
        guard cityType != nil else {
                return
            }

            if spawnPositions.count < 8 {
                setupSpawnPositions()
            }

            guard spawnPositions.count >= 8 else {
                return
            }
        // 難易度に応じて問題を生成
        var numbers: [Int] = []
        let maxAttempts = 10000

        // 都市タイプと正解回数に応じて桁数を決定
        let digitCount: Int
        if let cityType = cityType {
            if !hasFirstCorrect {
                // 最初の正解前
                switch cityType {
                case .france:
                    digitCount = 3
                case .japan:
                    digitCount = 4
                case .america:
                    digitCount = 5 
                }
            } else {
                // 最初の正解後
                switch cityType {
                case .france:
                    digitCount = 3
                case .japan:
                    digitCount = 4
                case .america:
                    digitCount = 5
                }
            }
        } else {
            // デフォルトは4桁
            digitCount = 4
        }

        // 正解回数に応じた数字の範囲
        let maxNumber: Int
        if correctCount < 1 {
            // 最初の1回は1から4
            maxNumber = 5
        } else if correctCount < 2 {
            // その後3回は1から7
            maxNumber = 7
        } else {
            // その後は1から9
            maxNumber = 9
        }

        // 数字を生成
        for _ in 0..<maxAttempts {
            let arr = (1...maxNumber).shuffled().prefix(digitCount).map { $0 }
            if canMakeTen(numbers: arr) {
                numbers = arr
                break
            }
        }

        // 見つからなかった場合は全範囲で再試行
        if numbers.isEmpty {
            for _ in 0..<maxAttempts {
                let arr = (1...9).shuffled().prefix(digitCount).map { $0 }
                if canMakeTen(numbers: arr) {
                    numbers = arr
                    break
                }
            }
        }

        let number = numbers.map { String($0) }.joined()
        let colors: [Color] = [.red, .blue, .green, .yellow] // 4種類の色のみ
        let color = colors.randomElement() ?? .red

        // 使用可能な出現位置からランダムに選択
        let availableIndices = getAvailableSpawnIndices()
        guard !availableIndices.isEmpty, let randomIndex = availableIndices.randomElement() else { return }
        let spawnPos = spawnPositions[randomIndex]

        let speed = Car.getSpeedForColor(color)
        // 左側（位置0,1,4,5）は左車線、右側（位置2,3,6,7）は右車線
        let lane: CarLane = (randomIndex == 0 || randomIndex == 1 || randomIndex == 4 || randomIndex == 5) ? .left : .right
        let newCar = Car(
            number: number,
            color: color,
            xPosition: spawnPos.x,
            speed: speed,
            numbers: numbers,
            lane: lane,
            direction: spawnPos.direction
        )
        newCar.yPosition = spawnPos.y
        newCar.isFlipped = spawnPos.isFlipped
        cars.append(newCar)
    }

    func increaseDifficulty(carColor: Color) -> (basePoints: Int, comboBonus: Int, totalPoints: Int) {
        correctCount += 1
        if !hasFirstCorrect {
            hasFirstCorrect = true
        }

        // コンボ判定
        let now = Date()
        if let lastTime = lastCorrectTime, now.timeIntervalSince(lastTime) <= comboTimeLimit {
            // コンボ継続
            comboCount += 1
        } else {
            // コンボリセット
            comboCount = 1
        }
        lastCorrectTime = now

        // 基本点数
        let basePoints = getPointsForColor(carColor)

        // コンボボーナス
        let comboBonus = getComboBonus()

        // 合計点数
        let totalPoints = basePoints + comboBonus
        totalScore += totalPoints

        // 難易度は正解回数に応じて自動的に変わる（spawnCarで判定）
        return (basePoints: basePoints, comboBonus: comboBonus, totalPoints: totalPoints)
    }

    func resetCombo() {
        comboCount = 0
        lastCorrectTime = nil
    }
    

    private func calculate(lhs: Int, rhs: Int, op: CalculateOperator) -> Int? {
        switch op {
        case .plus: return lhs + rhs
        case .minus: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide:
            if rhs != 0 && lhs % rhs == 0 { return lhs / rhs } else { return nil }
        }
    }

    private func canMakeTen(numbers: [Int]) -> Bool {
        guard !numbers.isEmpty else { return false }
        if numbers.count == 1 {
            return numbers[0] == 10
        }
        for i in 0..<numbers.count {
            for j in 0..<numbers.count where i != j {
                let a = numbers[i], b = numbers[j]
                let rest = numbers.enumerated().filter { $0.offset != i && $0.offset != j }.map { $0.element }
                for op in CalculateOperator.allCases {
                    if let res = calculate(lhs: a, rhs: b, op: op) {
                        let next = rest + [res]
                        if canMakeTen(numbers: next) { return true }
                    }
                }
            }
        }
        return false
    }

    func updateCar(id: UUID, action: (Car) -> Void) {
        if let car = cars.first(where: { $0.id == id }) {
            action(car)
        }
    }

    func removeCar(id: UUID) {
        cars.removeAll { $0.id == id }
    }

    func tick() {
        remainingTime -= 0.016
        if remainingTime < 0 {
            remainingTime = 0
        }

        // 車の移動とライフライン判定
        for car in cars {
            if car.direction == .down {
                // 上から下へ移動
                car.yPosition += car.speed

                // 下のライフラインを通過したら削除（上から来た車のみ反応）
                if car.yPosition >= bottomLifeLine {
                    removeCar(id: car.id)
                    continue
                }

                // 画面外に出たら削除（ペナルティなし）
                if car.yPosition > roadHeight + 100 {
                    removeCar(id: car.id)
                }
            } else {
                // 下から上へ移動
                car.yPosition -= car.speed

                // 上のライフラインを通過したら削除（下から来た車のみ反応）
                if car.yPosition <= topLifeLine {
                    removeCar(id: car.id)
                    continue
                }

                // 画面外に出たら削除（ペナルティなし）
                if car.yPosition < -100 {
                    removeCar(id: car.id)
                }
            }
        }
    }

    func startSpawning() {
        // 定期的に車を生成する処理（必要に応じて実装）
    }
}
