//
//  NotificationManager.swift
//  Cove
//
//  Created by Assistant on 8/8/25.
//

import Foundation
import Combine
import SwiftUI

/// NotificationManager orchestrates showing in-app banners for incoming notifications.
/// It exposes a single shared ObservableObject for SwiftUI overlays.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    /// The current banner payload; setting this triggers display.
    @Published private(set) var current: NotificationPayload?

    private var dismissTask: Task<Void, Never>?

    /// Shows a new in-app banner for a validated payload.
    /// - Parameters:
    ///   - payload: Validated payload to display
    ///   - duration: Auto-dismiss delay in seconds
    func show(_ payload: NotificationPayload, duration: TimeInterval = 3.0) {
        // Cancel any scheduled dismiss to avoid overlapping banners
        dismissTask?.cancel()

        // Set as current (SwiftUI overlay will animate in)
        self.current = payload

        // Auto-dismiss after duration with cooperative cancellation
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if Task.isCancelled { return }
            DispatchQueue.main.async { self?.dismiss() }
        }
    }

    /// Dismisses the current banner (animated by consuming view)
    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        self.current = nil
    }
} 