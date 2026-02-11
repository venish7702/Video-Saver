//
//  StorageService.swift
//  VideoSaver
//
//  FileManager for ArchivedMedia directory; UserDefaults for download metadata.
//

import Foundation

final class StorageService {
    static let shared = StorageService()

    private let fileManager = FileManager.default
    private let mediaDirectoryName = "ArchivedMedia"
    private let metadataKey = "mediaManagerItems"

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var mediaDirectory: URL {
        documentsDirectory.appendingPathComponent(mediaDirectoryName, isDirectory: true)
    }

    private init() {
        createMediaDirectoryIfNeeded()
    }

    private func createMediaDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: mediaDirectory.path) {
            try? fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        }
    }

    func moveToDocuments(from tempURL: URL, fileName: String) throws -> String {
        createMediaDirectoryIfNeeded()
        let sanitized = fileName.replacingOccurrences(of: "/", with: "_")
        let finalName = (sanitized as NSString).pathExtension.isEmpty ? "\(sanitized).mp4" : sanitized
        let destURL = mediaDirectory.appendingPathComponent(finalName)
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        if fileManager.fileExists(atPath: tempURL.path) {
            do {
                try fileManager.moveItem(at: tempURL, to: destURL)
            } catch {
                try fileManager.copyItem(at: tempURL, to: destURL)
                try? fileManager.removeItem(at: tempURL)
            }
        } else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Temp file no longer exists"])
        }
        return destURL.path
    }

    /// Returns URL for a file in ArchivedMedia. Use for playback when item.isCompleted.
    func localFileURL(fileName: String) -> URL {
        mediaDirectory.appendingPathComponent(fileName)
    }

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func removeFile(atPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Renames file at fromPath to new fileName in same directory. Returns new path.
    func renameFile(fromPath: String, toFileName: String) throws -> String {
        let fromURL = URL(fileURLWithPath: fromPath)
        guard fileManager.fileExists(atPath: fromPath) else { return fromPath }
        let dir = fromURL.deletingLastPathComponent()
        let sanitized = toFileName.replacingOccurrences(of: "/", with: "_")
        let finalName = (sanitized as NSString).pathExtension.isEmpty ? "\(sanitized).mp4" : sanitized
        let destURL = dir.appendingPathComponent(finalName)
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.moveItem(at: fromURL, to: destURL)
        return destURL.path
    }

    func saveMetadata(_ items: [MediaItem]) {
        let key = metadataKey
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONEncoder().encode(items) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadMetadata() -> [MediaItem] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let items = try? JSONDecoder().decode([MediaItem].self, from: data) else { return [] }
        return items
    }
}
