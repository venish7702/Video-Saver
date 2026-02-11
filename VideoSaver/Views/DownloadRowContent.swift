//
//  DownloadRowContent.swift
//  VideoSaver
//
//  Row content with thumbnail preview (URL or generated from video file).
//

import SwiftUI
import AVKit

struct DownloadRowContent: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 60, height: 60)

            if let urlString = item.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderIcon
                    case .empty:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if item.isCompleted, let path = item.filePath {
                VideoThumbnailView(filePath: path)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                placeholderIcon
            }
        }
    }

    private var placeholderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 60, height: 60)
            Image(systemName: "play.fill")
                .foregroundColor(.white)
        }
    }

    private var statusSubtitle: String {
        if item.isCompleted { return "Saved" }
        if item.isDownloading { return "Downloading…" }
        return "Failed"
    }
}

// MARK: - Video thumbnail from local file
private struct VideoThumbnailView: View {
    let filePath: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 60, height: 60)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard image == nil else { return }
        let url = URL(fileURLWithPath: filePath)
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 120, height: 120)
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        Task.detached(priority: .userInitiated) {
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return }
            let uiImage = UIImage(cgImage: cgImage)
            await MainActor.run {
                self.image = uiImage
            }
        }
    }
}
