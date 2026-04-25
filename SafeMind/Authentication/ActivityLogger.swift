//
//  ActivityLogger.swift
//  SafeMind
//
//  Created by Assistant on 23/04/26
//

import Foundation

/// Minimal abstraction to provide current user context to the logger.
/// Conform your session/auth manager to this to supply uid and display name.
public protocol CurrentUserProviding {
    var currentUID: String? { get }
    var currentUserName: String? { get }
}

/// A thin façade around ProfileManager activity APIs for easy usage from features.
public final class ActivityLogger {
    public static let shared = ActivityLogger()

    /// Inject a provider at app startup (e.g., from your Auth/Session manager)
    public var userProvider: CurrentUserProviding?

    private init() {}

    // MARK: - Public convenience methods

    @discardableResult
    public func logMusicPlay(metadata: [String: String]? = nil) async -> Bool {
        await log(.music, metadata: metadata)
    }

    @discardableResult
    public func logBreathing(metadata: [String: String]? = nil) async -> Bool {
        await log(.breathing, metadata: metadata)
    }

    @discardableResult
    public func logAcupressure(metadata: [String: String]? = nil) async -> Bool {
        await log(.acupressure, metadata: metadata)
    }

    @discardableResult
    public func logCBT(metadata: [String: String]? = nil) async -> Bool {
        await log(.cbt, metadata: metadata)
    }

    // MARK: - Core logging

    @discardableResult
    private func log(_ action: UserActivity.Action, metadata: [String: String]?) async -> Bool {
        guard let uid = userProvider?.currentUID, let name = userProvider?.currentUserName else {
            #if DEBUG
            print("⚠️ ActivityLogger: Missing user context; cannot log \(action)")
            #endif
            return false
        }
        do {
            try await ProfileManager.shared.logActivity(uid: uid, userName: name, action: action, metadata: metadata)
            return true
        } catch {
            #if DEBUG
            print("❌ ActivityLogger: Failed to log \(action) for uid=\(uid):", error)
            #endif
            return false
        }
    }
}
