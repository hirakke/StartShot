import SwiftUI

struct StartShotFilledButtonStyle: ButtonStyle {
    var height: CGFloat = 58
    var background: Color = .black
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(background, in: Capsule())
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}
