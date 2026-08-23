//
//  TouchBarSupport.swift
//  TouchBarSupport
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit
import os
import SwiftUI

/// The data sources and actions the app provides to the Touch Bar.
///
/// All state is supplied through closures so the package never depends on
/// application types; reading observable state inside the closures keeps the
/// Touch Bar in sync through Observation tracking.
public struct TouchBarSupportConfiguration {
    /// The name of the currently active player, or nil when none is signed in.
    public var currentPlayerName: @MainActor () -> String?
    /// The app's own avatar SwiftUI view for the current player, or nil.
    ///
    /// The view is hosted as-is so the Touch Bar renders exactly what the app
    /// displays (same loading states, same 3D skin rendering).
    public var playerAvatarView: @MainActor () -> AnyView?
    /// The display name of the currently selected game instance, or nil.
    public var currentGameName: @MainActor () -> String?
    /// The app-provided icon image of the currently selected game instance, or nil.
    ///
    /// Return nil to fall back to the built-in game symbol.
    public var gameIconImage: @MainActor () -> NSImage?
    /// Whether the currently selected game instance is running for the active player.
    public var isRunning: @MainActor () -> Bool
    /// Whether the currently selected game instance is launching for the active player.
    public var isLaunching: @MainActor () -> Bool
    /// Whether the currently selected game instance can export a mod pack.
    ///
    /// Vanilla instances cannot be exported, so the export button is hidden.
    public var canExportModPack: @MainActor () -> Bool
    /// Called when the user taps the play/stop button.
    public var onPlayStop: @MainActor () -> Void
    /// Called when the user taps the instance-settings button.
    public var onOpenSettings: @MainActor () -> Void
    /// Called when the user taps the export-mod-pack button.
    public var onExportModPack: @MainActor () -> Void
    /// Called when the user taps the show-in-finder button.
    public var onShowInFinder: @MainActor () -> Void
    /// Called when the user taps the delete-instance button.
    ///
    /// The app owns the actual deletion interaction; the Touch Bar only
    /// forwards the tap.
    public var onDeleteInstance: @MainActor () -> Void

    public init(
        currentPlayerName: @escaping @MainActor () -> String?,
        playerAvatarView: @escaping @MainActor () -> AnyView?,
        currentGameName: @escaping @MainActor () -> String?,
        gameIconImage: @escaping @MainActor () -> NSImage?,
        isRunning: @escaping @MainActor () -> Bool,
        isLaunching: @escaping @MainActor () -> Bool,
        canExportModPack: @escaping @MainActor () -> Bool,
        onPlayStop: @escaping @MainActor () -> Void,
        onOpenSettings: @escaping @MainActor () -> Void,
        onExportModPack: @escaping @MainActor () -> Void,
        onShowInFinder: @escaping @MainActor () -> Void,
        onDeleteInstance: @escaping @MainActor () -> Void,
    ) {
        self.currentPlayerName = currentPlayerName
        self.playerAvatarView = playerAvatarView
        self.currentGameName = currentGameName
        self.gameIconImage = gameIconImage
        self.isRunning = isRunning
        self.isLaunching = isLaunching
        self.canExportModPack = canExportModPack
        self.onPlayStop = onPlayStop
        self.onOpenSettings = onOpenSettings
        self.onExportModPack = onExportModPack
        self.onShowInFinder = onShowInFinder
        self.onDeleteInstance = onDeleteInstance
    }
}

/// Attaches the app-specific Touch Bar to the window that hosts the modified view.
public extension View {
    func touchBarSupport(_ configuration: TouchBarSupportConfiguration) -> some View {
        background(TouchBarInstaller(configuration: configuration))
    }
}

/// Centralized logger for the package.
enum TouchBarLog {
    static let log = Logger(subsystem: "com.swiftcraftlauncher.touchbar", category: "touchbar")
}
