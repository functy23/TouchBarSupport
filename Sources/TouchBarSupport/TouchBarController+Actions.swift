//
//  TouchBarController+Actions.swift
//  TouchBarSupport
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit

extension TouchBarController {
    func symbolImage(_ name: String, accessibilityDescription: String? = nil) -> NSImage {
        NSImage(systemSymbolName: name, accessibilityDescription: accessibilityDescription) ?? NSImage()
    }

    /// Keeps the read-only current-player label in sync with the active player.
    func updatePlayerLabelItem(currentPlayer: String?) {
        guard let item = cachedItems[Identifier.playerLabel.rawValue] as? NSCustomTouchBarItem,
              let label = item.view as? NSTextField else { return }
        label.stringValue = currentPlayer ?? ""
    }

    /// Enables the export and show-in-finder buttons only when an instance is selected.
    func updateGameActionItems(selectedGame: TouchBarInstance?) {
        let enabled = selectedGame != nil
        for key in [Identifier.exportModPack.rawValue, Identifier.showInFinder.rawValue] {
            if let button = cachedItems[key] as? NSButtonTouchBarItem {
                button.isEnabled = enabled
            }
        }
    }

    func updatePlayStopItem(selectedGame: TouchBarInstance?, hasCurrentPlayer: Bool) {
        let item = mainItem(Identifier.playStop) {
            NSButtonTouchBarItem(
                identifier: Identifier.playStop,
                title: "play.fill",
                target: self,
                action: #selector(toggleSelectedGame),
            )
        }
        guard let button = item as? NSButtonTouchBarItem else { return }

        let isRunning = selectedGame.map { configuration?.isRunning($0.id) ?? false } ?? false
        let isLaunching = selectedGame.map { configuration?.isLaunching($0.id) ?? false } ?? false
        let title = isRunning ? (configuration?.strings.stop ?? "") : (configuration?.strings.play ?? "")

        button.title = title
        button.image = symbolImage(isRunning ? "stop.fill" : "play.fill", accessibilityDescription: title)
        button.isEnabled = selectedGame != nil && hasCurrentPlayer && !isLaunching
    }

    func makeMainItem(for identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case Identifier.playerLabel:
            let label = NSTextField(labelWithString: configuration?.currentPlayerName() ?? "")
            label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
            label.textColor = .secondaryLabelColor
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = label
            cachedItems[identifier.rawValue] = item
            return item
        case Identifier.playStop:
            let button = NSButtonTouchBarItem(
                identifier: identifier,
                title: configuration?.strings.play ?? "",
                target: self,
                action: #selector(toggleSelectedGame),
            )
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.gamePicker:
            let picker = NSPopoverTouchBarItem(identifier: identifier)
            picker.showsCloseButton = true
            picker.collapsedRepresentationLabel = configuration?.strings.selectGame ?? ""
            cachedItems[identifier.rawValue] = picker
            return picker
        case Identifier.openSettings:
            let button = NSButtonTouchBarItem(
                identifier: identifier,
                title: configuration?.strings.instanceSettings ?? "",
                image: symbolImage("gearshape"),
                target: self,
                action: #selector(openInstanceSettingsFromTouchBar),
            )
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.exportModPack:
            let button = NSButtonTouchBarItem(
                identifier: identifier,
                title: configuration?.strings.exportModPack ?? "",
                image: symbolImage("square.and.arrow.up"),
                target: self,
                action: #selector(exportModPackFromTouchBar),
            )
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.showInFinder:
            let button = NSButtonTouchBarItem(
                identifier: identifier,
                title: configuration?.strings.showInFinder ?? "",
                image: symbolImage("folder"),
                target: self,
                action: #selector(showInFinderFromTouchBar),
            )
            cachedItems[identifier.rawValue] = button
            return button
        default:
            return nil
        }
    }

    func mainItem(_ identifier: NSTouchBarItem.Identifier, factory: () -> NSTouchBarItem) -> NSTouchBarItem {
        if let item = cachedItems[identifier.rawValue] {
            return item
        }
        let item = factory()
        cachedItems[identifier.rawValue] = item
        return item
    }

    func resolveSelectedGame(in instances: [TouchBarInstance]) -> TouchBarInstance? {
        guard let selectedId = configuration?.currentInstanceID() else {
            return nil
        }
        return instances.first { $0.id == selectedId }
    }

    @objc func toggleSelectedGame() {
        guard let configuration,
              resolveSelectedGame(in: gamePickerInstances) != nil,
              configuration.currentPlayerName() != nil else {
            return
        }
        configuration.onPlayStop()
    }

    @objc func selectGame(_ sender: NSButton) {
        guard let rawIdentifier = sender.identifier?.rawValue,
              let gameId = Identifier.id(afterPrefix: Identifier.gamePrefix, in: rawIdentifier) else {
            return
        }
        TouchBarLog.log.debug("Touch Bar instance tapped: \(gameId)")
        configuration?.onSelectInstance(gameId)
        (cachedItems[Identifier.gamePicker.rawValue] as? NSPopoverTouchBarItem)?.dismissPopover(nil)
        refresh()
    }

    /// Opens the settings via the app-provided action.
    @objc func openInstanceSettingsFromTouchBar() {
        configuration?.onOpenSettings()
    }

    /// Requests a mod-pack export for the selected instance.
    @objc func exportModPackFromTouchBar() {
        configuration?.onExportModPack()
    }

    /// Reveals the selected instance's directory in Finder.
    @objc func showInFinderFromTouchBar() {
        configuration?.onShowInFinder()
    }
}
