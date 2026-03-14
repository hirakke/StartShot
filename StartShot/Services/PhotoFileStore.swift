import Foundation
import UIKit

enum PhotoRole {
    case planned
    case actual

    var filename: String {
        switch self {
        case .planned:
            "planned.jpg"
        case .actual:
            "actual.jpg"
        }
    }
}

enum PhotoStoreError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            "画像の保存に失敗しました。"
        }
    }
}

struct PhotoFileStore {
    static func saveImage(
        _ image: UIImage,
        targetDate: Date,
        role: PhotoRole,
        dateService: DateService = .shared
    ) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw PhotoStoreError.encodingFailed
        }

        let baseURL = try baseDirectory()
        let dayDirectory = baseURL.appendingPathComponent(dateService.dayString(for: targetDate), isDirectory: true)
        try FileManager.default.createDirectory(at: dayDirectory, withIntermediateDirectories: true)

        let fileURL = dayDirectory.appendingPathComponent(role.filename)
        try data.write(to: fileURL, options: .atomic)

        return fileURL.path.replacingOccurrences(of: baseURL.path + "/", with: "")
    }

    static func image(for relativePath: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: relativePath).path)
    }

    static func url(for relativePath: String) -> URL {
        (try? baseDirectory().appendingPathComponent(relativePath)) ?? URL(fileURLWithPath: relativePath)
    }

    private static func baseDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("MissionPhotos", isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        return baseURL
    }
}
