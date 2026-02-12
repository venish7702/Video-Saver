//
//  VideoSaverApp.swift
//  VideoSaver
//
//  Media Manager: global app state and preferences.
//

import SwiftUI

@main
struct VideoSaverApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var downloadManager = DownloadManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(downloadManager)
                .preferredColorScheme(.light)
        }
    }
}
