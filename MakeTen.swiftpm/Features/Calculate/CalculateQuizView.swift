//
//  CalculateQuizView.swift
//  MakeTen
//
//  Created by 梶原景介 on 2025/11/16.
//

import SwiftUI

struct CalculateQuizView: View {
    @StateObject var viewModel: CalculateQuizViewModel
    @Environment(\.dismiss) var dismiss
    let isFromCar: Bool
    var onDismiss: (() -> Void)? = nil
    var onSuccess: (() -> Void)? = nil

    init(carNumbers: [Int]? = nil, onDismiss: (() -> Void)? = nil, onSuccess: (() -> Void)? = nil) {
        if let numbers = carNumbers {
            _viewModel = StateObject(wrappedValue: CalculateQuizViewModel(initialNumbers: numbers))
            isFromCar = true
        } else {
            _viewModel = StateObject(wrappedValue: CalculateQuizViewModel())
            isFromCar = false
        }
        self.onDismiss = onDismiss
        self.onSuccess = onSuccess
    }
    
    private func isHintedNumber(_ num: NumberValue) -> Bool {
        guard let hint = viewModel.hintStep,
              viewModel.hintLevel != .none else { return false }

        return num == hint.lhs || num == hint.rhs
    }

    // 数字の個数に応じてサイズと間隔を調整
    private var numberCircleSize: CGFloat {
        let count = viewModel.numbers.compactMap { $0 }.count
        return count >= 5 ? 52 : 64
    }

    private var numberCircleSpacing: CGFloat {
        let count = viewModel.numbers.compactMap { $0 }.count
        return count >= 5 ? 12 : 18
    }

    var body: some View {
        ZStack {
            // 車ゲームからでない場合は背景もデザイン
            if !isFromCar {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.9)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Make 10")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if !isFromCar {
                        Text("Use all the numbers to make 10.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 8)

                // バリエーション切替（車から来た場合は非表示）
                if !isFromCar {
                    Picker("数字数", selection: $viewModel.quizMode) {
                        ForEach(QuizMode.allCases) { mode in
                            Text(mode.label)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewModel.quizMode) { newValue in
                        viewModel.setQuizMode(newValue)
                    }
                }
                
                
                VStack(spacing: 4) {
                    HintBoxView(
                        hint: viewModel.hintStep,
                        hintLevel: viewModel.hintLevel,
                        cannotMakeTen: viewModel.cannotMakeTen
                    )
                }
                
                HStack(spacing: numberCircleSpacing) {
                    ForEach(viewModel.numbers.indices, id: \.self) { i in
                        if let num = viewModel.numbers[i] {
                            Button(action: {
                                viewModel.selectNumber(index: i)
                            }) {
                                Text(num.displayString)
                                    .font(num.displayString.count > 3 ? .title3 : .largeTitle)
                                    .frame(width: numberCircleSize, height: numberCircleSize)
                                    .background(viewModel.selectedIndices.contains(i) ? Color.green.opacity(0.9) : Color.yellow.opacity(0.8))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.selectedIndices.contains(i) ? Color.green : Color.gray, lineWidth: 3)
                                    )
                                    .foregroundColor(.black)
                            }
                        } else {
                            Circle()
                                .frame(width: numberCircleSize, height: numberCircleSize)
                                .opacity(0.0)
                        }
                    }
                }
                .padding(.top, 8)

                // 下段：四則演算
                HStack(spacing: 20) {
                    ForEach(CalculateOperator.allCases, id: \.self) { op in
                        Button(action: {
                            viewModel.selectOperator(op)
                        }) {
                            Text(op.symbol)
                                .font(.title)
                                .frame(width: 56, height: 56)
                                .background(viewModel.selectedOperator == op ? Color.green.opacity(0.9) : Color.blue.opacity(0.8))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        .disabled(viewModel.selectedIndices.isEmpty)
                    }
                }
                .padding(.top, 4)

                if viewModel.success {
                    Text("Success! You made 10! 🎉")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.top, 12)
                        .onAppear {
                            // 成功時にコールバックを呼ぶ
                            if isFromCar {
                                onSuccess?()
                            }
                        }
                } else if viewModel.failed {
                    Text("Oh no! You couldn't make 10...")
                        .font(.title3)
                        .foregroundColor(.red)
                        .padding(.top, 12)
                }

                VStack(spacing: 14) {

                    // Hint
                    Button {
                        viewModel.showNextHint()
                    } label: {
                        Text(viewModel.hintButtonTitle)
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.yellow.opacity(0.9), lineWidth: 2)
                            )
                    }

                    // Reset
                    Button {
                        viewModel.resetQuiz()
                    } label: {
                        Text("Reset")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                            )
                    }

                    // Close / Change
                    if !isFromCar {
                        Button {
                            viewModel.generateNewNumbers()
                        } label: {
                            Text("Change the Numbers")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                                )
                        }
                    } else {
                        Button {
                            onDismiss?() ?? dismiss()
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.8))
                                )
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 24)
            }
            .padding(24)
            .frame(maxWidth: 500)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: .white.opacity(0.4), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 16)
        }
        .background(isFromCar ? Color.clear : Color.black.opacity(0.6))
    }
}

#Preview {
    CalculateQuizView()
}


