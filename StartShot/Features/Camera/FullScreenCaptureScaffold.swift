import SwiftUI

enum CameraCaptureIntent {
    case nightSetup
    case morningStart

    var title: String {
        switch self {
        case .nightSetup:
            return "明日はどこから始める？"
        case .morningStart:
            return "1日を始めましょう🔥"
        }
    }

    var helperText: String? {
        switch self {
        case .nightSetup:
            return nil
        case .morningStart:
            return "絶対やるぞー！"
        }
    }
}

struct FullScreenCaptureScaffold<Preview: View>: View {
    let intent: CameraCaptureIntent
    let cameraState: CameraSessionState
    let isShutterEnabled: Bool
    let onBack: () -> Void
    let onShutter: () -> Void
    let onOpenSettings: () -> Void
    let onRetry: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                Spacer(minLength: 14)

                capturePane
                    .padding(.horizontal, 24)

                if let helperText = intent.helperText {
                    Text(helperText)
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.top, 20)
                }

                Spacer(minLength: 28)

                shutterButton
                    .padding(.bottom, 28)
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black.opacity(0.8))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)

            Text(intent.title)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.black)

            Spacer()
        }
    }

    private var capturePane: some View {
        ZStack {
            switch cameraState {
            case .running:
                preview()
            case .requestingAccess:
                statusPane(
                    title: "カメラを準備中です",
                    message: "権限を確認しています。"
                ) {
                    ProgressView()
                }
            case .unauthorized:
                statusPane(
                    title: "カメラ権限が必要です",
                    message: "設定アプリでカメラアクセスを許可してください。"
                ) {
                    Button("設定を開く", action: onOpenSettings)
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                }
            case .unavailable:
                statusPane(
                    title: "カメラが利用できません",
                    message: "このデバイスでは撮影できません。"
                ) {
                    EmptyView()
                }
            case .failed(let message):
                statusPane(
                    title: "カメラを起動できません",
                    message: message
                ) {
                    Button("再試行", action: onRetry)
                        .buttonStyle(.bordered)
                }
            case .idle:
                statusPane(
                    title: "カメラを起動します",
                    message: "準備ができるまでお待ちください。"
                ) {
                    ProgressView()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 560)
        .background(Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusPane<ActionContent: View>(
        title: String,
        message: String,
        @ViewBuilder action: () -> ActionContent
    ) -> some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            action()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.12))
    }

    private var shutterButton: some View {
        Button(action: onShutter) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.7), lineWidth: 2)
                    .frame(width: 62, height: 62)
                Circle()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isShutterEnabled)
        .opacity(isShutterEnabled ? 1 : 0.35)
    }
}
