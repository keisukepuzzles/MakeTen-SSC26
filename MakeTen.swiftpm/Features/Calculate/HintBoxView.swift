import SwiftUI

struct HintBoxView: View {
    let hint: HintStep?
    let hintLevel: HintLevel
    let cannotMakeTen: Bool

    private var isHint3: Bool {
        hintLevel == .fullStep
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("Hint 💡")
                .font(.caption)
                .foregroundColor(isHint3 ? .black : .yellow)

            hintContent
        }
        .frame(minHeight: 44)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHint3
                    ? Color.yellow.opacity(0.9)
                    : Color.black.opacity(0.25)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHint3
                    ? Color.yellow
                    : Color.yellow.opacity(hintLevel == .none ? 0.3 : 0.9),
                    lineWidth: 2
                )
        )
        .shadow(
            color: isHint3 ? Color.yellow.opacity(0.8) : .clear,
            radius: isHint3 ? 12 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: hintLevel)
    }

    // MARK: - Content
    @ViewBuilder
        private var hintContent: some View {
            if cannotMakeTen {
                Text("You can't make 10 from this situation.")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if let hint, hintLevel != .none {
                hintText(hint)
                    .font(.subheadline)
                    .foregroundColor(isHint3 ? .black : .white)
                    .multilineTextAlignment(.center)
            } else {
                Text(" ") // 空のViewでレイアウト維持
                    .font(.subheadline)
                    .opacity(0)
            }
        }
    // MARK: - Hint Text
    @ViewBuilder
    private func hintText(_ hint: HintStep) -> some View {
        switch hintLevel {
        case .numbers:
            Text("Try using \(hint.lhs.displayString) and \(hint.rhs.displayString)")
        case .numbersAndOp:
            Text("Use \(hint.lhs.displayString) \(hint.op.symbol) \(hint.rhs.displayString)")
        case .fullStep:
            Text("\(hint.lhs.displayString) \(hint.op.symbol) \(hint.rhs.displayString) = \(hint.result.displayString)")
        default:
            EmptyView()
        }
    }
}
