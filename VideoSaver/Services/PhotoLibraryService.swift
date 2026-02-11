//
//  PhotoLibraryService.swift
//  VideoSaver
//
//  Requests photo library permission and saves video to Camera Roll via PHPhotoLibrary.
//

import Foundation
import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case denied
    case restricted
    case saveFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .denied: return "Photo library access was denied."
        case .restricted: return "Photo library access is restricted."
        case .saveFailed(let e): return e?.localizedDescription ?? "Could not save to photo library."
        }
    }
}

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private init() {}

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }

    func saveVideoToCameraRoll(filePath: String) async throws {
        let status = await requestAuthorization()
        guard status else { throw PhotoLibraryError.denied }
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw PhotoLibraryError.saveFailed(nil)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibraryError.saveFailed(error))
                }
            }
        }
    }
}
