//
//  DownloadsView.swift
//  VideoSaver
//
//  Screen 2 – Downloads: row Button (tap) + three-dot Menu (visible). No long-press.
//

import SwiftUI
import AVKit

private extension Notification.Name {
    static let videoSavedToPhotos = Notification.Name("videoSavedToPhotos")
}

struct DownloadsView: View {
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var searchText = ""
    @State private var selectedItem: MediaItem?
    @State private var renameItem: MediaItem?
    @State private var renameText = ""
    @State private var showRenameAlert = false
    @State private var shareMessage: String?
    @State private var showSavedToPhotosAlert = false

    private var items: [MediaItem] {
        downloadManager.filteredDownloads(searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Downloads")
                        .font(.system(size: 32, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    TextField("Search files", text: $searchText)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if items.isEmpty {
                        Spacer()
                        Text(searchText.isEmpty ? "No downloaded videos yet." : "No matching files.")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        List {
                            ForEach(items) { item in
                                HStack {
                                    if item.isCompleted {
                                        Button {
                                            selectedItem = nil
                                            DispatchQueue.main.async {
                                                selectedItem = item
                                            }
                                        } label: {
                                            DownloadRowContent(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        DownloadRowContent(item: item)
                                    }

                                    if item.isCompleted {
                                        Menu {
                                            Button("Play") {
                                                selectedItem = nil
                                                DispatchQueue.main.async {
                                                    selectedItem = item
                                                }
                                            }
                                            Button("Share") {
                                                shareItem(item)
                                            }
                                            Button("Rename") {
                                                renameItem = item
                                                renameText = item.title
                                                showRenameAlert = true
                                            }
                                            Button("Delete", role: .destructive) {
                                                downloadManager.deleteDownload(itemId: item.id)
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                                        .padding(.vertical, 5)
                                )
                            }
                            .onDelete { indexSet in
                                for i in indexSet {
                                    let item = items[i]
                                    downloadManager.deleteDownload(itemId: item.id)
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: downloadManager.downloads)
                        }
                        .listStyle(.plain)
                        .listRowSpacing(12)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $selectedItem) { item in
                VideoPlayerView(
                    mediaItem: item,
                    onDismiss: { selectedItem = nil }
                )
            }
            .alert("Rename", isPresented: $showRenameAlert) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    renameItem = nil
                }
                Button("Save") {
                    if let item = renameItem {
                        downloadManager.renameDownload(itemId: item.id, newTitle: renameText)
                    }
                    renameItem = nil
                }
            } message: {
                Text("Enter a new name for the video.")
            }
            .alert("Share", isPresented: Binding(
                get: { shareMessage != nil },
                set: { if !$0 { shareMessage = nil } }
            )) {
                Button("OK", role: .cancel) { shareMessage = nil }
            } message: {
                if let msg = shareMessage { Text(msg) }
            }
            .alert("Saved", isPresented: $showSavedToPhotosAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Video saved successfully to Photos.")
            }
            .onReceive(NotificationCenter.default.publisher(for: .videoSavedToPhotos)) { _ in
                showSavedToPhotosAlert = true
            }
        }
    }

    private func shareItem(_ item: MediaItem) {
        guard item.isCompleted else {
            shareMessage = "File not found."
            return
        }
        let url: URL? = {
            if let path = item.filePath, StorageService.shared.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
            let fileName = item.savedFileName ?? {
                let sanitized = item.title.replacingOccurrences(of: "/", with: "_")
                return (sanitized as NSString).pathExtension.isEmpty ? "\(sanitized).mp4" : sanitized
            }()
            let fallbackURL = StorageService.shared.localFileURL(fileName: fileName)
            if StorageService.shared.fileExists(atPath: fallbackURL.path) {
                return fallbackURL
            }
            return nil
        }()
        guard let shareURL = url else {
            shareMessage = "File not found."
            return
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let av = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        av.completionWithItemsHandler = { activityType, completed, _, _ in
            guard completed, activityType == .saveToCameraRoll else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .videoSavedToPhotos, object: nil)
            }
        }
        rootVC.present(av, animated: true)
    }
}

#Preview {
    DownloadsView()
        .environmentObject(DownloadManager.shared)
}
