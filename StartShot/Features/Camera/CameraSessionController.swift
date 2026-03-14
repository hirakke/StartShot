import AVFoundation
import Combine
import Foundation
import UIKit

enum CameraSessionState: Equatable {
    case idle
    case requestingAccess
    case running
    case unauthorized
    case unavailable
    case failed(String)
}

enum CameraSessionError: LocalizedError {
    case captureUnavailable
    case imageProcessingFailed
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .captureUnavailable:
            return "カメラが利用できない状態です。"
        case .imageProcessingFailed:
            return "撮影した画像の処理に失敗しました。"
        case .captureFailed:
            return "撮影に失敗しました。"
        }
    }
}

final class CameraSessionController: NSObject, ObservableObject {
    @Published private(set) var state: CameraSessionState = .idle

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "StartShot.CameraSessionQueue")

    private var isConfigured = false
    private var pendingCaptureHandler: ((Result<UIImage, Error>) -> Void)?

    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSessionOnQueue()
        case .notDetermined:
            requestAccessAndStart()
        case .denied, .restricted:
            setState(.unauthorized)
        @unknown default:
            setState(.failed("カメラ権限の状態を取得できませんでした。"))
        }
    }

    func stopSession() {
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
        setState(.idle)
    }

    func retry() {
        setState(.idle)
        startSession()
    }

    func capturePhoto(_ handler: @escaping (Result<UIImage, Error>) -> Void) {
        guard state == .running else {
            handler(.failure(CameraSessionError.captureUnavailable))
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }
            guard self.pendingCaptureHandler == nil else {
                DispatchQueue.main.async {
                    handler(.failure(CameraSessionError.captureFailed))
                }
                return
            }

            self.pendingCaptureHandler = handler
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func requestAccessAndStart() {
        setState(.requestingAccess)
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else {
                return
            }
            if granted {
                self.startSessionOnQueue()
            } else {
                self.setState(.unauthorized)
            }
        }
    }

    private func startSessionOnQueue() {
        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            if !self.isConfigured {
                guard self.configureSessionOnQueue() else {
                    return
                }
                self.isConfigured = true
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
            self.setState(.running)
        }
    }

    private func configureSessionOnQueue() -> Bool {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            setState(.unavailable)
            return false
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                setState(.failed("カメラの初期化に失敗しました。"))
                return false
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            return true
        } catch {
            setState(.failed("カメラの準備中にエラーが発生しました。"))
            return false
        }
    }

    private func setState(_ newState: CameraSessionState) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let result: Result<UIImage, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            result = .success(image)
        } else {
            result = .failure(CameraSessionError.imageProcessingFailed)
        }

        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }
            let handler = self.pendingCaptureHandler
            self.pendingCaptureHandler = nil

            DispatchQueue.main.async {
                handler?(result)
            }
        }
    }
}
