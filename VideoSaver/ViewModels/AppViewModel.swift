//
//  AppViewModel.swift
//  VideoSaver
//
//  Validates video URL; calls backend /analyze for supported web video links.
//

import Foundation

enum AppFlowState: Equatable {
    case idle
    case analyzing(url: String)
    case qualitySelection(MediaItem)
    case success(MediaItem)
    case failure(String)
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var flowState: AppFlowState = .idle

    private let linkParserService = LinkParserService()

    func analyze(url: String) async {
        var trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            flowState = .failure("Please enter a URL.")
            return
        }

        // If no scheme, assume https (e.g. "pin.it/2jIP9oCmm")
        if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
            trimmed = "https://" + trimmed
        }

        // Accept any valid URL; backend validates and returns playable format
        guard let parsed = URL(string: trimmed),
              let host = parsed.host, !host.isEmpty, host.contains(".") else {
            flowState = .failure("Please paste a valid video URL.")
            return
        }

        flowState = .analyzing(url: trimmed)
        do {
            let response = try await linkParserService.parse(url: trimmed)
            guard !response.formats.isEmpty else {
                flowState = .failure("No playable video formats found")
                return
            }
            let item = MediaItem(
                id: UUID(),
                title: response.title,
                filePath: nil,
                thumbnailURL: response.thumbnail,
                sourceDomain: response.sourceDomain,
                directMediaURL: response.formats.first?.url,
                fileSize: "",
                progress: 0,
                isDownloading: false,
                isCompleted: false
            )
            flowState = .qualitySelection(item)
        } catch {
            flowState = .failure(error.localizedDescription)
        }
    }

    func reset() {
        flowState = .idle
    }

    func setSuccess(_ item: MediaItem) {
        flowState = .success(item)
    }

    func setFailure(_ message: String) {
        flowState = .failure(message)
    }
}
