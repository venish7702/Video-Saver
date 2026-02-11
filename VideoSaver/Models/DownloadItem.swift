//
//  DownloadItem.swift
//  VideoSaver
//

import Foundation

struct DownloadItem: Identifiable, Codable, Equatable {
    let id: UUID
    var fileName: String
    var fileSize: String
    var resolution: String
    var urlString: String
    var localURL: String?
    var dateAdded: Date
    var progress: Double
    var isCompleted: Bool
    var isDownloading: Bool

    init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: String,
        resolution: String,
        urlString: String,
        localURL: String? = nil,
        dateAdded: Date = Date(),
        progress: Double = 0,
        isCompleted: Bool = false,
        isDownloading: Bool = false
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.resolution = resolution
        self.urlString = urlString
        self.localURL = localURL
        self.dateAdded = dateAdded
        self.progress = progress
        self.isCompleted = isCompleted
        self.isDownloading = isDownloading
    }
}
