//
//  PreviewView.swift
//  VideoSaver
//
//  Full-screen video: same simple setup as before quality — SwiftUI VideoPlayer + one AVPlayer.
//

import SwiftUI
import AVKit

/// Full-screen video player. Same approach as before quality: one AVPlayer created in onAppear, SwiftUI VideoPlayer.
struct VideoPlayerView: View {
    let mediaItem: MediaItem
    let onDismiss: () -> Void

    @State private var player: AVPlayer?
    @State private var showFileNotFoundAlert = false
    @State private var playbackFailed = false
    @State private var statusObserver: NSKeyValueObservation?
    @State private var loadTimeout: DispatchWorkItem?

    /// Same URL logic as before: local file when completed (filePath or filename in ArchivedMedia), else directMediaURL.
    private var playbackURL: URL? {
        if mediaItem.isCompleted {
            if let filePath = mediaItem.filePath, FileManager.default.fileExists(atPath: filePath) {
                return URL(fileURLWithPath: filePath)
            }
            let fileName = mediaItem.savedFileName ?? mediaItem.title.replacingOccurrences(of: "/", with: "_") + ".mp4"
            let fallbackURL = StorageService.shared.localFileURL(fileName: fileName)
            if FileManager.default.fileExists(atPath: fallbackURL.path) {
                return fallbackURL
            }
            return nil
        }
        if let remote = mediaItem.directMediaURL, !remote.isEmpty {
            return URL(string: remote)
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Video: only one branch so SwiftUI doesn't wrap in extra views
            if playbackURL == nil {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text(mediaItem.isCompleted ? "File not found." : "Invalid video URL")
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if playbackFailed {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Couldn't play this video")
                        .foregroundStyle(.white)
                        .font(.headline)
                    Text("The file may be corrupt or in an unsupported format.")
                        .foregroundStyle(.white.opacity(0.8))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if let p = player {
                VideoPlayer(player: p)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                ProgressView("Loading…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

            // Done on top
            Button("Done") {
                onDismiss()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .id(mediaItem.id)
        .onAppear {
            playbackFailed = false
            loadTimeout?.cancel()
            if player == nil, let url = playbackURL {
                // Create item first so we can observe status (currentItem is set async with AVPlayer(url:))
                let item = AVPlayerItem(url: url)
                observePlaybackStatus(item, failed: $playbackFailed)
                let p = AVPlayer(playerItem: item)
                DispatchQueue.main.async {
                    player = p
                    p.play()
                }
                // If still not ready after 12s, show error (avoids endless black screen)
                let failedBinding = $playbackFailed
                let work = DispatchWorkItem {
                    if item.status != .readyToPlay && item.status != .failed {
                        DispatchQueue.main.async { failedBinding.wrappedValue = true }
                    }
                }
                loadTimeout = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)
            }
            if playbackURL == nil, mediaItem.isCompleted {
                showFileNotFoundAlert = true
            }
        }
        .onDisappear {
            loadTimeout?.cancel()
            loadTimeout = nil
            statusObserver?.invalidate()
            statusObserver = nil
            player?.pause()
            player = nil
        }
        .alert("File not found", isPresented: $showFileNotFoundAlert) {
            Button("OK", role: .cancel) { onDismiss() }
        } message: {
            Text("File not found. Please re-download.")
        }
    }

    private func observePlaybackStatus(_ item: AVPlayerItem, failed: Binding<Bool>) {
        statusObserver?.invalidate()
        statusObserver = item.observe(\.status, options: [.new, .initial]) { _, change in
            guard change.newValue == .failed else { return }
            DispatchQueue.main.async { failed.wrappedValue = true }
        }
    }
}
