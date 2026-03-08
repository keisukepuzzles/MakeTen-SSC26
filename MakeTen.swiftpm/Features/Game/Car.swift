//
//  Car.swift
//  MakeTen
//
//  Created by 梶原景介 on 2025/11/30.
//

import Foundation
import SwiftUI

@Observable
class Car: Identifiable {
    let id = UUID()
    var number: String
    var color: Color
    var numbers: [Int] = [] // 4桁の数字の配列
    var xPosition: CGFloat = 150
    var yPosition: CGFloat = -100
    var speed: CGFloat = 0.5 // 全体的に遅く
    var isFocused = false
    var hasCrossedLine = false // ラインを越えたかどうか
    var lane: CarLane = .left // 左車線か右車線か
    var direction: CarDirection = .down // 上から下か下から上か
    var isFlipped: Bool = false // 画像を反転するかどうか

    init(number: String, color: Color, xPosition: CGFloat = 150, speed: CGFloat? = nil, numbers: [Int] = [], lane: CarLane = .left, direction: CarDirection = .down) {
        self.number = number
        self.color = color
        self.xPosition = xPosition
        // 色ごとに速さを設定
        if let speed = speed {
            self.speed = speed
        } else {
            self.speed = Car.getSpeedForColor(color)
        }
        self.numbers = numbers
        self.lane = lane
        self.direction = direction
    }

    static func getSpeedForColor(_ color: Color) -> CGFloat {
        // 色ごとの速さ設定（3色のみ、全体的に遅く）
        switch color {
        case .red: return 0.5
        case .blue: return 0.5
        case .green: return 0.5
        case .yellow: return 0.5
        default: return 0.5
        }
    }

    func increaseSpeed() {
        speed += 1
    }

    func focus() {
        isFocused = true
    }
}


enum CarLane {
    case left
    case right
}

enum CarDirection {
    case up // 下から上
    case down // 上から下
}

struct CarView: View {
    let car: Car

    var body: some View {
        ZStack {
            // タクシー画像（色に応じて）
            let imageName = getTaxiImageName(for: car.color)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 80)
                .scaleEffect(x: car.isFlipped ? -1 : 1, y: 1) // 反転設定に応じて反転

            // 数字を横書きで車の前方に表示（方向に応じて位置を調整）
            HStack(spacing: 2) {
                ForEach(car.numbers.indices, id: \.self) { index in
                    Text("\(car.numbers[index])")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                }
            }
            .offset(y: car.direction == .down ? 50 : -50) // 下方向は下に、上方向は上に
        }
    }

    private func getTaxiImageName(for color: Color) -> String {
        switch color {
        case .red: return "赤色タクシー"
        case .blue: return "水色タクシー"
        case .green: return "緑色タクシー"
        case .yellow: return "黄色タクシー"
        default: return "赤色タクシー"
        }
    }
}

struct TimeBonusInlineView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial) // Liquid Glass
            )
            .shadow(color: .green.opacity(0.3), radius: 6)
    }
}

struct ScoreAnimation {
    let basePoints: Int
    let comboBonus: Int
    let totalPoints: Int
    let color: Color
}

struct ScoreEffectView: View {
    let animation: ScoreAnimation
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(spacing: 4) {
            if animation.comboBonus > 0 {
                Text("+\(animation.basePoints)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(animation.color)
                Text("COMBO +\(animation.comboBonus)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            } else {
                Text("+\(animation.totalPoints)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(animation.color)
            }
        }
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 0
                offset = -50
            }
        }
    }
}

struct TimeBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))

                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width * progress)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 12)
    }

    var barColor: Color {
        switch progress {
        case 0..<0.3: return .red
        case 0..<0.6: return .yellow
        default: return .green
        }
    }
}

