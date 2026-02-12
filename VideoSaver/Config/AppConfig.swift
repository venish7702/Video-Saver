//
//  AppConfig.swift
//  VideoSaver
//
//  Backend URL for analyze and download. Used when running from App Store (no env var).
//

import Foundation

enum AppConfig {
    /// Production backend URL. Used when BACKEND_URL is not set (e.g. App Store build).
    static let productionBackendURL = "https://video-saver-production.up.railway.app"

    /// Optional fallback when production URL fails (e.g. on mobile data if carrier blocks *.railway.app).
    /// Add a custom domain in Railway (Settings → Networking → Custom Domain), then set it here (e.g. "https://api.yourdomain.com").
    static let fallbackBackendURL: String? = "https://video-saver.videosaverapp.site"
}
