//
//  MediaItem.swift
//  VideoSaver
//
//  Media Manager: Identifiable, Codable, Equatable struct with computed localFileURL.
//

import Foundation

struct MediaFormat: Identifiable, Codable, Equatable {
    var id: String { url }
    let quality: String
    let url: String
    let size: Int?
}

struct MediaItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var filePath: String?
    var thumbnailURL: String?
    var sourceDomain: String?
    var directMediaURL: String?
    var fileSize: String
    var dateAdded: Date
    var progress: Double
    var isDownloading: Bool
    var isCompleted: Bool
    var taskId: Int?
    var availableFormats: [MediaFormat]?
    var selectedFormat: MediaFormat?

    init(
        id: UUID = UUID(),
        title: String,
        filePath: String? = nil,
        thumbnailURL: String? = nil,
        sourceDomain: String? = nil,
        directMediaURL: String? = nil,
        fileSize: String = "—",
        dateAdded: Date = Date(),
        progress: Double = 0,
        isDownloading: Bool = false,
        isCompleted: Bool = false,
        taskId: Int? = nil,
        availableFormats: [MediaFormat]? = nil,
        selectedFormat: MediaFormat? = nil
    ) {
        self.id = id
        self.title = title
        self.filePath = filePath
        self.thumbnailURL = thumbnailURL
        self.sourceDomain = sourceDomain
        self.directMediaURL = directMediaURL
        self.fileSize = fileSize
        self.dateAdded = dateAdded
        self.progress = progress
        self.isDownloading = isDownloading
        self.isCompleted = isCompleted
        self.taskId = taskId
        self.availableFormats = availableFormats
        self.selectedFormat = selectedFormat
    }

    /// Computed local file URL for playback when archiving is complete.
    var localFileURL: URL? {
        guard let path = filePath else { return nil }
        return URL(fileURLWithPath: path)
    }

    /// File name in ArchivedMedia (e.g. "Title.mp4") for resolving local playback.
    var savedFileName: String? {
        filePath.flatMap { ($0 as NSString).lastPathComponent }
    }
}
