//
//  LinkParserService.swift
//  VideoSaver
//
//  Calls your Node.js backend /analyze. Uses BACKEND_URL from env (dev) or production URL below (App Store).
//

import Foundation

/// Production backend URL when BACKEND_URL is not set (e.g. App Store). Change this if you deploy elsewhere.
private let productionBackendURL = "https://video-saver-production.up.railway.app"
/// Fallback when production URL fails on mobile data (e.g. custom domain). Set to nil if not used.
private let fallbackBackendURL: String? = "https://video-saver.videosaverapp.site"

/// Dev: set BACKEND_URL in Xcode scheme (e.g. http://localhost:3000). Otherwise uses productionBackendURL.
/// On mobile data, a local BACKEND_URL is unreachable; we retry with productionBackendURL so the app works.
private var defaultBackendURL: String {
    let raw = ProcessInfo.processInfo.environment["BACKEND_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let raw = raw, !raw.isEmpty { return raw }
    return productionBackendURL
}

/// True if the error is a connection/host unreachable (e.g. on mobile data when BACKEND_URL is a local IP).
private func isConnectionHostError(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

/// Session for backend: long timeout, allows cellular so it works on mobile data.
private let backendSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 120
    config.timeoutIntervalForResource = 120
    config.allowsCellularAccess = true
    config.waitsForConnectivity = false
    return URLSession(configuration: config)
}()

struct LinkParserResponse: Codable {
    let title: String
    let thumbnail: String
    let sourceDomain: String
    let formats: [MediaFormat]
}

private struct BackendErrorBody: Codable {
    let error: String?
}

final class LinkParserService {
    /// Backend base URL: BACKEND_URL env (dev) or production (App Store). No trailing slash.
    private var baseURL: String {
        defaultBackendURL.replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    }

    func parse(url: String) async throws -> LinkParserResponse {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LinkParserError.invalidURL
        }

        let productionBase = productionBackendURL.replacingOccurrences(of: "/$", with: "", options: .regularExpression)
        var fallbackBases: [String] = []
        if baseURL != productionBase { fallbackBases.append(productionBase) }
        if let fallback = fallbackBackendURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !fallback.isEmpty {
            fallbackBases.append(fallback.replacingOccurrences(of: "/$", with: "", options: .regularExpression))
        }

        var lastError: Error?
        for base in [baseURL] + fallbackBases {
            do {
                return try await performAnalyze(url: trimmed, baseURL: base)
            } catch {
                lastError = error
                if !LinkParserError.isConnectionFailure(error) { throw error }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                return try await performAnalyze(url: trimmed, baseURL: base)
            } catch {
                lastError = error
                if !LinkParserError.isConnectionFailure(error) { throw error }
            }
        }

        throw LinkParserError.connectionFailedWithHint("")
    }

    private func performAnalyze(url trimmed: String, baseURL: String) async throws -> LinkParserResponse {
        guard !baseURL.isEmpty, let endpoint = URL(string: "\(baseURL)/analyze") else {
            throw LinkParserError.invalidBackend
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["url": trimmed])
        request.timeoutInterval = 120

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await backendSession.data(for: request)
        } catch {
            throw LinkParserError.connectionFailed((error as? URLError)?.localizedDescription ?? error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw LinkParserError.badResponse
        }
        guard http.statusCode == 200 else {
            if let errBody = try? JSONDecoder().decode(BackendErrorBody.self, from: data), let msg = errBody.error {
                throw LinkParserError.analyzeFailed(sanitizedErrorMessage(msg))
            }
            throw LinkParserError.badResponse
        }

        return try JSONDecoder().decode(LinkParserResponse.self, from: data)
    }
}

/// Returns a user-facing message that never mentions any platform name.
private func sanitizedErrorMessage(_ message: String) -> String {
    let lower = message.lowercased()
    let platformTerms = ["instagram", "insta", "facebook", "fb.", "pinterest", "pin.", "tiktok", "blocked", "login required", "rate limit"]
    if platformTerms.contains(where: { lower.contains($0) }) {
        return "Please try again later."
    }
    return message
}

enum LinkParserError: LocalizedError {
    case invalidURL
    case invalidBackend
    case badResponse
    case analyzeFailed(String)
    case connectionFailed(String)
    case connectionFailedWithHint(String)

    /// True for connection/host unreachable (e.g. mobile data when BACKEND_URL is a local IP).
    static func isConnectionFailure(_ error: Error) -> Bool {
        if error is URLError { return isConnectionHostError(error) }
        if case .connectionFailed = error as? LinkParserError { return true }
        return false
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Please enter a valid URL."
        case .invalidBackend: return "Backend URL is not set. Add BACKEND_URL in scheme environment variables."
        case .badResponse: return "Could not analyze this link."
        case .analyzeFailed(let msg): return msg
        case .connectionFailed(let msg): return "Could not connect to the server. \(msg)"
        case .connectionFailedWithHint: return "Could not connect to the server. Try Wi‑Fi or another network—your mobile network may be blocking the server."
        }
    }
}
