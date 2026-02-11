//
//  LinkParserService.swift
//  VideoSaver
//
//  Calls your Node.js backend /analyze. Uses BACKEND_URL from env (dev) or AppConfig.productionBackendURL (App Store).
//

import Foundation

/// Dev: set BACKEND_URL in Xcode scheme (e.g. http://localhost:3000). App Store: uses AppConfig.productionBackendURL.
private var defaultBackendURL: String {
    ProcessInfo.processInfo.environment["BACKEND_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        .flatMap { $0.isEmpty ? nil : $0 }
        ?? AppConfig.productionBackendURL
}

/// Session for backend: long timeout, ephemeral to avoid connection reuse issues after first request.
private let backendSession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 120
    config.timeoutIntervalForResource = 120
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
    /// Backend base URL: BACKEND_URL env (dev) or AppConfig.productionBackendURL (App Store).
    private var baseURL: String {
        defaultBackendURL.replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    }

    func parse(url: String) async throws -> LinkParserResponse {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LinkParserError.invalidURL
        }
        guard let endpoint = URL(string: "\(baseURL)/analyze"), !baseURL.isEmpty else {
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
        } catch let error as URLError {
            throw LinkParserError.connectionFailed(error.localizedDescription)
        } catch {
            throw LinkParserError.connectionFailed(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw LinkParserError.badResponse
        }
        guard http.statusCode == 200 else {
            if let errBody = try? JSONDecoder().decode(BackendErrorBody.self, from: data), let msg = errBody.error {
                throw LinkParserError.analyzeFailed(msg)
            }
            throw LinkParserError.badResponse
        }

        return try JSONDecoder().decode(LinkParserResponse.self, from: data)
    }
}

enum LinkParserError: LocalizedError {
    case invalidURL
    case invalidBackend
    case badResponse
    case analyzeFailed(String)
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Please enter a valid URL."
        case .invalidBackend: return "Backend URL is not set. Add BACKEND_URL in scheme environment variables."
        case .badResponse: return "Could not analyze this link."
        case .analyzeFailed(let msg): return msg
        case .connectionFailed(let msg): return "Could not connect to the server. \(msg)"
        }
    }
}
