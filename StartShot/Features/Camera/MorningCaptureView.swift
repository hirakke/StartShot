import SwiftUI
import UIKit

struct MorningCaptureView: View {
    let plannedImagePath: String?
    let missionMessage: String?
    let onClose: () -> Void
    let onGuideToSetup: () -> Void
    let onCapture: (UIImage) -> Void
    private let plannedReferenceImage: UIImage?

    @Environment(AppDateProvider.self) private var dateProvider

    @StateObject private var camera = CameraSessionController()
    @State private var isCapturing = false
    @State private var errorMessage: String?

    private let dateService = DateService.shared
    private var timePolicy: MissionTimePolicy {
        MissionTimePolicy(dateProvider: dateProvider, dateService: dateService)
    }
    private var isDeadlinePassed: Bool {
        dateService.isPastMissionExecutionDeadline(
            targetDate: timePolicy.todayTargetDate,
            at: timePolicy.now
        )
    }

    private var helperMessage: String? {
        let trimmedMessage = missionMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedMessage.isEmpty ? nil : trimmedMessage
    }

    init(
        plannedImagePath: String?,
        missionMessage: String?,
        onClose: @escaping () -> Void,
        onGuideToSetup: @escaping () -> Void,
        onCapture: @escaping (UIImage) -> Void
    ) {
        self.plannedImagePath = plannedImagePath
        self.missionMessage = missionMessage
        self.onClose = onClose
        self.onGuideToSetup = onGuideToSetup
        self.onCapture = onCapture
        self.plannedReferenceImage = plannedImagePath.flatMap { PhotoFileStore.image(for: $0) }
    }

    var body: some View {
        if plannedImagePath == nil {
            missingMissionContent
        } else if isDeadlinePassed {
            expiredMissionContent
        } else {
            FullScreenCaptureScaffold(
                intent: .morningStart,
                helperText: helperMessage,
                cameraState: camera.state,
                isShutterEnabled: camera.state == .running && !isCapturing,
                onBack: onClose,
                onShutter: capture,
                onOpenSettings: openAppSettings,
                onRetry: camera.retry
            ) {
                CustomCameraPreview(session: camera.session)
                    .overlay {
                        if let plannedReferenceImage {
                            referenceOverlay(image: plannedReferenceImage)
                        }
                    }
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
    }

    private func referenceOverlay(image: UIImage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(0.26)
                .padding(28)
                .allowsHitTesting(false)

            Label("昨夜の設定を重ねて表示中", systemImage: "moon.stars.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.black.opacity(0.56))
                .clipShape(Capsule())
                .padding(14)
                .allowsHitTesting(false)
        }
    }

    private var missingMissionContent: some View {
        VStack(spacing: 18) {
            Text("今日のミッションがありません。")
                .font(.title3.weight(.semibold))
            Text("前夜に設定したミッションがあるときだけ、朝の開始撮影を実行できます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button("明日のミッションを設定する", action: onGuideToSetup)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.29, green: 0.71, blue: 0.45))

            Button("戻る", action: onClose)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }

    private var expiredMissionContent: some View {
        VStack(spacing: 18) {
            Text("このミッションは期限切れです。")
                .font(.title3.weight(.semibold))
            Text("朝ミッションは10:00までに実行します。次のミッションを設定して明日に備えましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button("明日のミッションを設定する", action: onGuideToSetup)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.29, green: 0.71, blue: 0.45))

            Button("戻る", action: onClose)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
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
