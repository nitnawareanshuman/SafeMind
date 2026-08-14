//
//  VideoCacheManager.swift
//  Irene
//
//  Downloads the small set of looping background videos once and caches
//  them on disk. LoopingVideoPlayer plays from the cached local file
//  instead of streaming, which is what was causing the lag/stutter.
//

import Foundation

actor VideoCacheManager {
    static let shared = VideoCacheManager()

    private let session = URLSession(configuration: .default)
    private let cacheDirectory: URL
    private var activeDownloads: [URL: Task<URL, Error>] = [:]

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("BackgroundVideos", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func localURL(for remoteURL: URL) -> URL {
        // Stable, filesystem-safe filename derived from the remote URL.
        let filename = remoteURL.absoluteString
            .data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent(filename).appendingPathExtension("mp4")
    }

    /// Returns a local file URL for the video, downloading it first if it
    /// isn't cached yet. Concurrent calls for the same URL share one download.
    func localFile(for remoteURL: URL) async throws -> URL {
        let destination = localURL(for: remoteURL)

        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }

        if let existing = activeDownloads[remoteURL] {
            return try await existing.value
        }

        let task = Task<URL, Error> {
            let (tempURL, _) = try await session.download(from: remoteURL)
            if FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: tempURL, to: destination)
            return destination
        }
        activeDownloads[remoteURL] = task

        do {
            let result = try await task.value
            activeDownloads[remoteURL] = nil
            return result
        } catch {
            activeDownloads[remoteURL] = nil
            throw error
        }
    }
}
