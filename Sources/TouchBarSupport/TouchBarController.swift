//
//  TouchBarController.swift
//  TouchBarSupport
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit
import Observation

/// Owns the main window Touch Bar and keeps its items in sync with app state.
@MainActor
final class TouchBarController: NSObject, NSTouchBarDelegate {
    enum Identifier {
        static let prefix = "com.swiftcraftlauncher.touchbar"
        static let playerLabel = NSTouchBarItem.Identifier("\(prefix).player-label")
        static let selectedGame = NSTouchBarItem.Identifier("\(prefix).selected-game")
        static let playStop = NSTouchBarItem.Identifier("\(prefix).play-stop")
        static let openSettings = NSTouchBarItem.Identifier("\(prefix).open-settings")
        static let exportModPack = NSTouchBarItem.Identifier("\(prefix).export-modpack")
        static let showInFinder = NSTouchBarItem.Identifier("\(prefix).show-in-finder")
        static let deleteInstance = NSTouchBarItem.Identifier("\(prefix).delete-instance")
    }

    weak var window: NSWindow?
    let touchBar = NSTouchBar()
    var cachedItems: [String: NSTouchBarItem] = [:]
    var configuration: TouchBarSupportConfiguration?

    private var isObservingState = false
    private var observationGeneration = 0
    private var lastAppliedFingerprint: Int?
    var lastRenderedGameName: String?
    var playerLabelWidthConstraint: NSLayoutConstraint?

    func install(on window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        touchBar.delegate = self
        window.touchBar = touchBar
    }

    func update(with configuration: TouchBarSupportConfiguration) {
        self.configuration = configuration
        refreshIfStateChanged()
        scheduleStateObservationIfNeeded()
    }

    /// Rebuilds the Touch Bar only when the underlying state actually changed.
    ///
    /// SwiftUI re-evaluates the hosting view frequently and re-creates the
    /// configuration struct, and observable state is often re-written with the
    /// same value (no-op writes still notify observers). Without this guard
    /// every such event would rebuild the whole bar.
    func refreshIfStateChanged() {
        guard configuration != nil else { return }
        let fingerprint = observedStateFingerprint()
        guard fingerprint != lastAppliedFingerprint else { return }
        lastAppliedFingerprint = fingerprint
        refresh()
    }

    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier,
    ) -> NSTouchBarItem? {
        itemOrMake(for: identifier)
    }

    /// Returns the cached item for `identifier`, creating and caching it on first use.
    func itemOrMake(for identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if let item = cachedItems[identifier.rawValue] {
            return item
        }
        guard let item = makeMainItem(for: identifier) else { return nil }
        cachedItems[identifier.rawValue] = item
        return item
    }

    func refresh() {
        let currentGameName = configuration?.currentGameName()
        let currentPlayer = configuration?.currentPlayerName()

        TouchBarLog.log.debug("Touch Bar refresh: player=\(currentPlayer ?? "none"), selected=\(currentGameName ?? "none")")

        configureTouchBarLayout(
            hasPlayer: currentPlayer != nil,
            hasGame: currentGameName != nil,
            canExportModPack: configuration?.canExportModPack() ?? true,
        )
        updatePlayerLabelItem(currentPlayer: currentPlayer)
        updateSelectedGameItem(currentGameName: currentGameName)
        updatePlayStopItem(hasCurrentPlayer: currentPlayer != nil)
    }

    private func configureTouchBarLayout(hasPlayer: Bool, hasGame: Bool, canExportModPack: Bool) {
        var identifiers: [NSTouchBarItem.Identifier] = []
        if hasPlayer {
            identifiers.append(Identifier.playerLabel)
        }
        if hasGame {
            identifiers.append(Identifier.selectedGame)
            identifiers.append(Identifier.showInFinder)
            if canExportModPack {
                identifiers.append(Identifier.exportModPack)
            }
            identifiers.append(Identifier.playStop)
            identifiers.append(Identifier.openSettings)
            identifiers.append(Identifier.deleteInstance)
        }

        touchBar.defaultItemIdentifiers = identifiers
    }

    private func scheduleStateObservationIfNeeded() {
        guard !isObservingState else { return }
        isObservingState = true
        observationGeneration += 1
        let generation = observationGeneration

        withObservationTracking {
            _ = observedStateFingerprint()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isObservingState = false
                guard generation == observationGeneration else { return }
                refreshIfStateChanged()
                scheduleStateObservationIfNeeded()
            }
        }
    }

    private func observedStateFingerprint() -> Int {
        var fingerprint = configuration?.currentGameName()?.hashValue ?? 0
        fingerprint &+= configuration?.currentPlayerName()?.hashValue ?? 0
        fingerprint &+= (configuration?.isRunning() ?? false) ? 1 : 0
        fingerprint &+= (configuration?.isLaunching() ?? false) ? 1 : 0
        fingerprint &+= (configuration?.canExportModPack() ?? true) ? 1 : 0
        return fingerprint
    }
}
