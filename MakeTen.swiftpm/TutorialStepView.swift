//
//  TutorialStepView.swift
//  MakeTen
//
//  Created by 梶原景介 on 2026/03/01.
//

import SwiftUI

struct TutorialStepView: View {
    let step: Int
    let title: String
    let instruction: String
    let initialNumbers: [Int]
    let operators: [CalculateOperator]
    let onComplete: () -> Void
    let isActive: Bool


    @StateObject private var viewModel: CalculateQuizViewModel
    @State private var selectedIndices: [Int] = []
    @State private var selectedOperator: CalculateOperator? = nil
    @State private var displayNumbers: [Int?] = []
    @State private var showSuccess = false
    @State private var canProceed = false
    @State private var showPlate = false


    // ⭐ 追加：導入アニメーション用
    @State private var showPlateIntro = true
    @State private var movePlateUp = false
    @State private var showCalculationUI = false

    init(
        step: Int,
        isActive: Bool,
        title: String,
        instruction: String,
        numbers: [Int],
        operators: [CalculateOperator],
        onComplete: @escaping () -> Void
    ) {
        self.step = step
        self.isActive = isActive
        self.title = title
        self.instruction = instruction
        self.initialNumbers = numbers
        self.operators = operators
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: CalculateQuizViewModel(initialNumbers: numbers))
        _displayNumbers = State(initialValue: numbers.map { Optional($0) })
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // ① 最初に出るナンバープレート
            if showPlateIntro {
                LicensePlateView(numbers: initialNumbers)
                    .offset(y: movePlateUp ? -300 : 0)
                    .animation(.easeInOut(duration: 0.8), value: movePlateUp)
            }

            // ② 計算画面
            if showCalculationUI {
                calculationContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onChange(of: isActive) { active in
            if active {
                resetIntroState()
                startIntroAnimation()
            }
        }
        .onAppear {
            if isActive {
                resetIntroState()
                startIntroAnimation()
            }
        }


    }

    private func resetIntroState() {
        showPlateIntro = true
        movePlateUp = false
        showCalculationUI = false
    }


    private var calculationContent: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(instruction)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }

            // ===== 成功表示 =====
            if showSuccess {
                    VStack(spacing: 20) {
                        Text("Success!")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)

                        Text("You made 10🎊")
                            .font(.title)
                            .foregroundColor(.white)

                        if canProceed {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.yellow)
                                .opacity(0.8)
                                .animation(
                                    .easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true),
                                    value: canProceed
                                )
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .onTapGesture {
                        if canProceed {
                            withAnimation {
                                showPlate = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()) {
                                onComplete()
                            }
                        }
                    }
            } else {

                // ===== 通常の計算UI =====
                if step == 0 {
                    HStack(spacing: 30) {
                        numberButton(index: 0)

                        operatorButton(.plus)

                        numberButton(index: 1)
                    }
                } else {
                    VStack(spacing: 30) {
                        HStack(spacing: 40) {
                            ForEach(displayNumbers.indices, id: \.self) { index in
                                numberButton(index: index)
                            }
                        }

                        HStack(spacing: 20) {
                            ForEach(operators, id: \.self) { op in
                                operatorButton(op)
                            }
                        }
                    }
                }
            }

            if !showSuccess {
                Button("Reset") {
                    resetCalculation()
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(20)
            }

            Spacer()
        }
        .padding()
    }

    private func numberButton(index: Int) -> some View {
        Group {
            if let num = displayNumbers[index] {
                Button {
                    selectNumber(index: index)
                } label: {
                    Text("\(num)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(width: 80, height: 80)
                        .background(
                            selectedIndices.contains(index)
                            ? Color.green.opacity(0.8)
                            : Color.yellow.opacity(0.7)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedIndices.contains(index)
                                    ? Color.green
                                    : Color.gray,
                                    lineWidth: 3
                                )
                        )
                        .foregroundColor(.black)
                }
            } else {
                Circle()
                    .frame(width: 80, height: 80)
                    .opacity(0)
            }
        }
    }

    private func operatorButton(_ op: CalculateOperator) -> some View {
        Button {
            selectOperator(op)
        } label: {
            Text(op.symbol)
                .font(.title)
                .fontWeight(.bold)
                .frame(width: 60, height: 60)
                .background(
                    selectedOperator == op
                    ? Color.green.opacity(0.8)
                    : Color.blue.opacity(0.7)
                )
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .disabled(selectedIndices.count != 1)
    }

    private func startIntroAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                movePlateUp = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                showCalculationUI = true
            }
        }
    }

    private func selectNumber(index: Int) {
        guard index < displayNumbers.count,
              displayNumbers[index] != nil else { return }

        if let i = selectedIndices.firstIndex(of: index) {
            selectedIndices.remove(at: i)
        } else {
            guard selectedIndices.count < 2 else { return }
            selectedIndices.append(index)

            if selectedIndices.count == 2,
               let op = selectedOperator {
                performCalculation(op: op)
            }
        }
    }

    private func selectOperator(_ op: CalculateOperator) {
        guard selectedIndices.count == 1 else { return }
        selectedOperator = op
    }

    private func resetCalculation() {
        displayNumbers = initialNumbers.map { Optional($0) }
        selectedIndices = []
        selectedOperator = nil
    }

    private func performCalculation(op: CalculateOperator) {
        guard selectedIndices.count == 2 else { return }

        let aIndex = selectedIndices[0]
        let bIndex = selectedIndices[1]

        guard let a = displayNumbers[aIndex],
              let b = displayNumbers[bIndex] else { return }

        var result: Int?
        switch op {
        case .plus: result = a + b
        case .minus: result = a - b
        case .multiply: result = a * b
        case .divide:
            if b != 0 && a % b == 0 {
                result = a / b
            }
        }

        guard let value = result else {
            selectedIndices = []
            selectedOperator = nil
            return
        }

        displayNumbers[bIndex] = value
        displayNumbers[aIndex] = nil

        if value == 10 {
            withAnimation {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    canProceed = true
                }
            }
        } else {
            selectedIndices = [bIndex]
            selectedOperator = nil
        }
    }
}
