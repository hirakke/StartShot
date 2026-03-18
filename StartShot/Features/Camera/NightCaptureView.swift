import SwiftUI
import UIKit

struct NightCaptureView: View {
    let onClose: () -> Void
    let onCapture: (UIImage) -> Void

    @StateObject private var camera = CameraSessionController()
    @State private var errorMessage: String?
    @State private var isCapturing = false

    var body: some View {
        FullScreenCaptureScaffold(
            intent: .nightSetup,
            helperText: nil,
            cameraState: camera.state,
            isShutterEnabled: camera.state == .running && !isCapturing,
            onBack: onClose,
            onShutter: capture,
            onOpenSettings: openAppSettings,
            onRetry: camera.retry
        ) {
            CustomCameraPreview(session: camera.session)
        }
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
        .alert("撮影できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func capture() {
        guard !isCapturing else {
            return
        }

        HapticFeedback.tap()
        isCapturing = true
        camera.capturePhoto { result in
            isCapturing = false
            switch result {
            case .success(let image):
                HapticFeedback.success()
                onCapture(image)
            case .failure(let error):
                HapticFeedback.error()
                errorMessage = error.localizedDescription
            }
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}
