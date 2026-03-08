import SwiftUI

struct PauseView: View {
    let onRestart: () -> Void
    let onResume: () -> Void
    var onBackToStart: (() -> Void)? = nil

    init(
         onRestart: @escaping () -> Void,
         onResume: @escaping () -> Void,
         onBackToStart: (() -> Void)? = nil
     ) {
         self.onRestart = onRestart
         self.onResume = onResume
         self.onBackToStart = onBackToStart
     }

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Paused")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                VStack(spacing: 18) {
                    Button(action: onRestart) {
                        Text("Try Again")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.red)
                            .cornerRadius(20)
                    }

                    Button(action: onResume) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }

                    if let onBackToStart = onBackToStart {
                        Button(action: onBackToStart) {
                            Text("Back to Home")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Color.gray)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    PauseView(onRestart: {}, onResume: {}, onBackToStart: nil)
}

