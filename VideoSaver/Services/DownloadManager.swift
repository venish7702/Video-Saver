//
//  DownloadManager.swift
//  VideoSaver
//
//  Foreground URLSession download; progress via delegate; StorageService for save and metadata.
//

import Foundation

/// Thread-safe store for taskId → title so the URLSession delegate (nonisolated) can read the file name.
private final class TaskIdToTitleStore {
    private let lock = NSLock()
    private var dict: [Int: String] = [:]
    func set(_ title: String, forTaskId taskId: Int) {
        lock.lock()
        dict[taskId] = title
        lock.unlock()
    }
    func title(forTaskId taskId: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return dict[taskId]
    }
    func remove(taskId: Int) {
        lock.lock()
        dict[taskId] = nil
        lock.unlock()
    }
}

private let taskIdToTitleStore = TaskIdToTitleStore()

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [MediaItem] = []
    @Published var downloadProgress: Double = 0

    private let storage = StorageService.shared
    private var activeTask: URLSessionDownloadTask?
    private var activeItemId: UUID?
    private var onCompleteCallback: (() -> Void)?
    /// Throttle progress UI updates so we don’t re-render dozens of times per second.
    private var lastProgressUIUpdate: Date = .distantPast
    private let progressUIInterval: TimeInterval = 0.2
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        downloads = storage.loadMetadata()
    }

    private func saveMetadata() {
        storage.saveMetadata(downloads)
    }

    func startDownload(item: MediaItem, onComplete: @escaping () -> Void) {
        guard let urlString = item.directMediaURL,
              let url = URL(string: urlString) else {
            print("Download failed: directMediaURL missing")
            return
        }

        cancelDownload(itemId: item.id)

        let task = session.downloadTask(with: url)

        if !downloads.contains(where: { $0.id == item.id }) {
            downloads.insert(item, at: 0)
        }

        guard let idx = downloads.firstIndex(where: { $0.id == item.id }) else { return }

        var entry = downloads[idx]
        entry.directMediaURL = urlString
        entry.selectedFormat = item.selectedFormat
        entry.availableFormats = item.availableFormats
        entry.isDownloading = true
        entry.isCompleted = false
        entry.progress = 0
        entry.taskId = task.taskIdentifier
        downloads[idx] = entry

        saveMetadata()

        activeItemId = item.id
        onCompleteCallback = onComplete
        downloadProgress = 0
        lastProgressUIUpdate = .distantPast
        activeTask = task
        taskIdToTitleStore.set(item.title, forTaskId: task.taskIdentifier)
        task.resume()
    }

    private func finishDownload(success: Bool, localPath: String?) {
        defer {
            activeTask = nil
            activeItemId = nil
            downloadProgress = 0
            onCompleteCallback?()
            onCompleteCallback = nil
            saveMetadata()
        }
        guard let id = activeItemId, let idx = downloads.firstIndex(where: { $0.id == id }) else { return }
        if let tid = downloads[idx].taskId {
            taskIdToTitleStore.remove(taskId: tid)
        }
        if success, let path = localPath {
            downloads[idx].filePath = path
            downloads[idx].isCompleted = true
        }
        downloads[idx].isDownloading = false
        downloads[idx].progress = success ? 1 : 0
    }

    func cancelDownload(itemId: UUID) {
        guard activeItemId == itemId else { return }
        activeTask?.cancel()
        activeTask = nil
        activeItemId = nil
        onCompleteCallback = nil
        downloadProgress = 0
        if let idx = downloads.firstIndex(where: { $0.id == itemId }) {
            downloads[idx].isDownloading = false
            downloads[idx].progress = 0
        }
        saveMetadata()
    }

    func deleteDownload(itemId: UUID) {
        if activeItemId == itemId {
            activeTask?.cancel()
            activeTask = nil
            activeItemId = nil
            onCompleteCallback = nil
        }
        if let item = downloads.first(where: { $0.id == itemId }), let path = item.filePath {
            try? storage.removeFile(atPath: path)
        }
        downloads.removeAll { $0.id == itemId }
        saveMetadata()
    }

    func renameDownload(itemId: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = downloads.firstIndex(where: { $0.id == itemId }) else { return }
        let oldPath = downloads[idx].filePath
        if let path = oldPath {
            do {
                let newPath = try storage.renameFile(fromPath: path, toFileName: trimmed)
                downloads[idx].filePath = newPath
                downloads[idx].title = trimmed
            } catch {
                downloads[idx].title = trimmed
            }
        } else {
            downloads[idx].title = trimmed
        }
        saveMetadata()
    }

    func filteredDownloads(searchText: String) -> [MediaItem] {
        guard !searchText.isEmpty else { return downloads }
        return downloads.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskId = downloadTask.taskIdentifier
        let title = taskIdToTitleStore.title(forTaskId: taskId)
        guard let title = title else {
            DispatchQueue.main.async { [weak self] in
                Task { @MainActor in
                    self?.finishDownload(success: false, localPath: nil)
                }
            }
            return
        }
        let fileName = "\(title).mp4"
        let newPath: String?
        do {
            newPath = try StorageService.shared.moveToDocuments(from: location, fileName: fileName)
        } catch {
            newPath = nil
        }
        let pathToSet = newPath
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                taskIdToTitleStore.remove(taskId: taskId)
                // Find row by taskId, or fallback to activeItemId (same in-progress download)
                let index = self.downloads.firstIndex(where: { $0.taskId == taskId })
                    ?? self.downloads.firstIndex(where: { $0.id == self.activeItemId })
                if let path = pathToSet, let idx = index {
                    self.downloads[idx].filePath = path
                    self.downloads[idx].progress = 1.0
                    self.downloads[idx].isDownloading = false
                    self.downloads[idx].isCompleted = true
                    self.activeTask = nil
                    self.activeItemId = nil
                    self.downloadProgress = 0
                    self.onCompleteCallback?()
                    self.onCompleteCallback = nil
                    self.saveMetadata()
                } else {
                    self.finishDownload(success: false, localPath: nil)
                }
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let taskId = downloadTask.taskIdentifier
        Task { @MainActor in
            let now = Date()
            guard now.timeIntervalSince(lastProgressUIUpdate) >= progressUIInterval || progress >= 1.0 else { return }
            lastProgressUIUpdate = now
            if let index = downloads.firstIndex(where: { $0.taskId == taskId }) {
                downloads[index].progress = progress
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            Task { @MainActor in
                finishDownload(success: false, localPath: nil)
            }
        }
    }
}
