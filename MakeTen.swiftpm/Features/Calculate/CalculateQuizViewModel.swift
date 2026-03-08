import Foundation
import SwiftUI

struct Fraction: Equatable {
    let numerator: Int
    let denominator: Int

    // 約分された分数を返す
    var reduced: Fraction {
        let gcd = greatestCommonDivisor(abs(numerator), abs(denominator))
        let sign = (numerator < 0) != (denominator < 0) ? -1 : 1
        return Fraction(
            numerator: sign * abs(numerator) / gcd,
            denominator: abs(denominator) / gcd
        )
    }

    // 文字列表現
    var displayString: String {
        let reduced = self.reduced
        if reduced.denominator == 1 {
            return "\(reduced.numerator)"
        }
        return "\(reduced.numerator)/\(reduced.denominator)"
    }

    // 最大公約数を計算
    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var a = abs(a)
        var b = abs(b)
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }
}

enum CalculateOperator: CaseIterable {
    case plus, minus, multiply, divide

    var symbol: String {
        switch self {
        case .plus: return "+"
        case .minus: return "-"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }
}

enum QuizMode: Int, CaseIterable, Identifiable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .two: return "2 digits"
        case .three: return "3 digits"
        case .four: return "4 digits"
        case .five: return "5 digits"
        }
    }
}

enum NumberValue: Equatable {
    case integer(Int)
    case fraction(Fraction)

    var displayString: String {
        switch self {
        case .integer(let value):
            return "\(value)"
        case .fraction(let fraction):
            return fraction.displayString
        }
    }

    var integerValue: Int? {
        switch self {
        case .integer(let value):
            return value
        case .fraction(let fraction):
            let reduced = fraction.reduced
            return reduced.denominator == 1 ? reduced.numerator : nil
        }
    }
}

enum HintLevel {
    case none
    case numbers          // ① 数字2つ
    case numbersAndOp     // ② 数字 + 演算子
    case fullStep         // ③ 中間結果
}

struct HintStep {
    let lhs: NumberValue
    let rhs: NumberValue
    let op: CalculateOperator
    let result: NumberValue
}

class CalculateQuizViewModel: ObservableObject {
    @Published var numbers: [NumberValue?] = []
    @Published var selectedIndices: [Int] = []
    @Published var selectedOperator: CalculateOperator? = nil
    @Published var success: Bool = false
    @Published var failed: Bool = false
    @Published var quizMode: QuizMode = .four
    @Published var hintLevel: HintLevel = .none
    @Published var hintStep: HintStep? = nil
    @Published var cannotMakeTen: Bool = false
    private var originalNumbers: [Int] = []
    private static let quizModeKey = "lastQuizMode"
    
    init(initialNumbers: [Int]? = nil) {
        if let numbers = initialNumbers {
            originalNumbers = numbers
            self.numbers = numbers.map { Optional(NumberValue.integer($0)) }
            // 車から来たときは数字の個数に合わせる（範囲外ならデフォルト4つ）
            quizMode = QuizMode(rawValue: numbers.count) ?? .four
        } else {
            // Practice から来た場合は、前回のモード or 初回は2つ
            let stored = UserDefaults.standard.integer(forKey: Self.quizModeKey)
            if let savedMode = QuizMode(rawValue: stored) {
                quizMode = savedMode
            } else {
                quizMode = .two
            }
            generateNewNumbers()
        }
    }
    func resetQuiz() {
        numbers = originalNumbers.map { Optional(NumberValue.integer($0)) }
        selectedIndices = []
        selectedOperator = nil
        success = false
        failed = false
        hintLevel = .none
        hintStep = nil
        cannotMakeTen = false
    }
    func generateNewNumbers() {
        let n = quizMode.rawValue
        var candidate: [Int] = []
        for _ in 0..<10000 {
            let arr = (1...9).shuffled().prefix(n).map { $0 }
            if canMakeTen(numbers: arr) {
                candidate = arr
                break
            }
        }
        originalNumbers = candidate
        numbers = candidate.map { Optional(NumberValue.integer($0)) }
        selectedIndices = []
        selectedOperator = nil
        success = false
        failed = false
        hintLevel = .none
        hintStep = nil
        cannotMakeTen = false
    }
    func selectNumber(index: Int) {
        guard numbers[safe: index] != nil, numbers[index] != nil else { return }
        hintLevel = .none
        hintStep = nil
        if let i = selectedIndices.firstIndex(of: index) {
            selectedIndices.remove(at: i)
            return
        }
        if selectedIndices.count == 1 && selectedOperator == nil {
            selectedIndices = [index]
            return
        }
        guard selectedIndices.count < 2 else { return }
        selectedIndices.append(index)
        if selectedIndices.count == 2, let op = selectedOperator {
            let idx1 = selectedIndices[0]
            let idx2 = selectedIndices[1]
            guard let a = numbers[idx1], let b = numbers[idx2], idx1 != idx2,
                  let result = calculate(lhs: a, rhs: b, op: op) else {
                selectedIndices = []
                return
            }
            numbers[idx1] = nil
            numbers[idx2] = result
            hintLevel = .none
            hintStep = nil
            selectedIndices = [idx2]
            selectedOperator = nil
            let visibleNumbers = numbers.compactMap { $0 }
                    if visibleNumbers.count == 1 {
                        if let integerValue = visibleNumbers.first?.integerValue, integerValue == 10 {
                            success = true
                            cannotMakeTen = false
                        } else {
                            failed = true
                            cannotMakeTen = !canMakeTenFromNumberValues(visibleNumbers)
                        }
                    } else {
                        cannotMakeTen = !canMakeTenFromNumberValues(visibleNumbers)
            }
        }
    }
    func selectOperator(_ op: CalculateOperator) {
        selectedOperator = op
    }
    func setQuizMode(_ mode: QuizMode) {
        quizMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.quizModeKey)
        generateNewNumbers()
    }
    func showNextHint() {
        if hintStep == nil {
            guard let step = findHintStep() else { return }
            hintStep = step
            hintLevel = .numbers
            return
        }
        switch hintLevel {
        case .none:
            hintLevel = .numbers
        case .numbers:
            hintLevel = .numbersAndOp
        case .numbersAndOp:
            hintLevel = .fullStep
        case .fullStep:
            break
        }
    }
    
    
    private func findHintStep() -> HintStep? {
        let values = numbers.enumerated().compactMap { index, value -> (Int, NumberValue)? in
            guard let value else { return nil }
            return (index, value)
        }
        
        for i in 0..<values.count {
            for j in 0..<values.count where i != j {
                let (idx1, lhs) = values[i]
                let (idx2, rhs) = values[j]
                
                for op in CalculateOperator.allCases {
                    guard let result = calculate(lhs: lhs, rhs: rhs, op: op) else { continue }
                    if let intValue = result.integerValue, intValue < 0 {
                        continue
                    }
                    var rest = values
                        .filter { $0.0 != idx1 && $0.0 != idx2 }
                        .map { $0.1 }
                    
                    rest.append(result)
                    
                    if canMakeTenFromNumberValues(rest) {
                        return HintStep(
                            lhs: lhs,
                            rhs: rhs,
                            op: op,
                            result: result
                        )
                    }
                }
            }
        }
        return nil
    }
    
    private func canMakeTenFromNumberValues(_ values: [NumberValue]) -> Bool {
        if values.count == 1 {
            return values.first?.integerValue == 10
        }
        
        for i in 0..<values.count {
            for j in 0..<values.count where i != j {
                let lhs = values[i]
                let rhs = values[j]
                
                let rest = values.enumerated()
                    .filter { $0.offset != i && $0.offset != j }
                    .map { $0.element }
                
                for op in CalculateOperator.allCases {
                    guard let result = calculate(lhs: lhs, rhs: rhs, op: op) else { continue }
                    if canMakeTenFromNumberValues(rest + [result]) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func calculate(lhs: NumberValue, rhs: NumberValue, op: CalculateOperator) -> NumberValue? {
        switch op {
        case .plus:
            return add(lhs: lhs, rhs: rhs)
        case .minus:
            return subtract(lhs: lhs, rhs: rhs)
        case .multiply:
            return multiply(lhs: lhs, rhs: rhs)
        case .divide:
            return divide(lhs: lhs, rhs: rhs)
        }
    }
    
    private func add(lhs: NumberValue, rhs: NumberValue) -> NumberValue {
        switch (lhs, rhs) {
        case (.integer(let a), .integer(let b)):
            return .integer(a + b)
        case (.fraction(let a), .fraction(let b)):
            let num = a.numerator * b.denominator + b.numerator * a.denominator
            let den = a.denominator * b.denominator
            return .fraction(Fraction(numerator: num, denominator: den).reduced)
        case (.integer(let a), .fraction(let b)):
            let num = a * b.denominator + b.numerator
            return .fraction(Fraction(numerator: num, denominator: b.denominator).reduced)
        case (.fraction(let a), .integer(let b)):
            let num = a.numerator + b * a.denominator
            return .fraction(Fraction(numerator: num, denominator: a.denominator).reduced)
        }
    }
    
    private func subtract(lhs: NumberValue, rhs: NumberValue) -> NumberValue {
        switch (lhs, rhs) {
        case (.integer(let a), .integer(let b)):
            return .integer(a - b)
        case (.fraction(let a), .fraction(let b)):
            let num = a.numerator * b.denominator - b.numerator * a.denominator
            let den = a.denominator * b.denominator
            return .fraction(Fraction(numerator: num, denominator: den).reduced)
        case (.integer(let a), .fraction(let b)):
            let num = a * b.denominator - b.numerator
            return .fraction(Fraction(numerator: num, denominator: b.denominator).reduced)
        case (.fraction(let a), .integer(let b)):
            let num = a.numerator - b * a.denominator
            return .fraction(Fraction(numerator: num, denominator: a.denominator).reduced)
        }
    }
    
    private func multiply(lhs: NumberValue, rhs: NumberValue) -> NumberValue {
        switch (lhs, rhs) {
        case (.integer(let a), .integer(let b)):
            return .integer(a * b)
        case (.fraction(let a), .fraction(let b)):
            let num = a.numerator * b.numerator
            let den = a.denominator * b.denominator
            return .fraction(Fraction(numerator: num, denominator: den).reduced)
        case (.integer(let a), .fraction(let b)):
            let num = a * b.numerator
            return .fraction(Fraction(numerator: num, denominator: b.denominator).reduced)
        case (.fraction(let a), .integer(let b)):
            let num = a.numerator * b
            return .fraction(Fraction(numerator: num, denominator: a.denominator).reduced)
        }
    }
    
    private func divide(lhs: NumberValue, rhs: NumberValue) -> NumberValue? {
        switch (lhs, rhs) {
        case (.integer(let a), .integer(let b)):
            if b == 0 { return nil }
            // 割り切れる場合は整数、そうでない場合は分数
            if a % b == 0 {
                return .integer(a / b)
            } else {
                return .fraction(Fraction(numerator: a, denominator: b).reduced)
            }
        case (.fraction(let a), .fraction(let b)):
            if b.numerator == 0 { return nil }
            let num = a.numerator * b.denominator
            let den = a.denominator * b.numerator
            return .fraction(Fraction(numerator: num, denominator: den).reduced)
        case (.integer(let a), .fraction(let b)):
            if b.numerator == 0 { return nil }
            let num = a * b.denominator
            return .fraction(Fraction(numerator: num, denominator: b.numerator).reduced)
        case (.fraction(let a), .integer(let b)):
            if b == 0 { return nil }
            let num = a.numerator
            let den = a.denominator * b
            return .fraction(Fraction(numerator: num, denominator: den).reduced)
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
                    if let res = calculateInteger(lhs: a, rhs: b, op: op) {
                        let next = rest + [res]
                        if canMakeTen(numbers: next) { return true }
                    }
                }
            }
        }
        return false
    }
    
    private func calculateInteger(lhs: Int, rhs: Int, op: CalculateOperator) -> Int? {
        switch op {
        case .plus: return lhs + rhs
        case .minus: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide:
            if rhs != 0 && lhs % rhs == 0 { return lhs / rhs } else { return nil }
        }
    }
    var hintButtonTitle: String {
        switch hintLevel {
        case .none:
            return "Hint"
        case .numbers:
            return "Hint 1"
        case .numbersAndOp:
            return "Hint 2"
        case .fullStep:
            return "Hint 3"
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
