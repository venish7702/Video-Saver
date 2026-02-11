//
//  AppConfig.swift
//  VideoSaver
//
//  Backend URL for analyze and download. Used when running from App Store (no env var).
//

import Foundation

enum AppConfig {
    /// Production backend URL. Used when BACKEND_URL is not set (e.g. App Store build).
    /// Before App Store: replace with your deployed backend URL (e.g. Railway).
    static let productionBackendURL = "https://your-backend.up.railway.app"
}
