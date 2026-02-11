//
//  ContentView.swift
//  VideoSaver
//
//  3-screen: Fetch, Downloads, Settings. On fetch success → start download, switch to Downloads.
//

import SwiftUI

enum Tab: Int, CaseIterable {
    case fetch = 0
    case downloads = 1
    case settings = 2
}

struct ContentView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var selectedTab: Tab = .fetch

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FetchView()
            }
            .tabItem {
                Label("Fetch", systemImage: "plus.square")
            }
            .tag(Tab.fetch)
            .onChange(of: appViewModel.flowState) { newState in
                if case .success(let item) = newState {
                    downloadManager.startDownload(item: item) {
                        selectedTab = .downloads
                    }
                    selectedTab = .downloads
                }
            }

            DownloadsView()
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
                .tag(Tab.downloads)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(DownloadManager.shared)
}
