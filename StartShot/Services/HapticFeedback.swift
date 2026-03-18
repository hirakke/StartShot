import UIKit

enum HapticFeedback {
    private static let tapGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func tap() {
        runOnMain {
            tapGenerator.impactOccurred()
            tapGenerator.prepare()
        }
    }

    static func selection() {
        runOnMain {
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }

    static func success() {
        runOnMain {
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        }
    }

    static func error() {
        runOnMain {
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
        }
    }

    static func prepare() {
        runOnMain {
            tapGenerator.prepare()
            selectionGenerator.prepare()
            notificationGenerator.prepare()
        }
    }

    private static func runOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
