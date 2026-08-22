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
              let container = item.view as? NSStackView,
              let label = container.arrangedSubviews.last as? NSTextField,
              let avatar = container.arrangedSubviews.first as? NSImageView else { return }

        label.stringValue = currentPlayer ?? ""
        if let image = configuration?.playerAvatarImage() {
            avatar.image = image
        }
    }

    /// Enables the export and show-in-finder buttons only when an instance is selected.
    func updateGameActionItems(selectedGame: TouchBarInstance?) {
        let enabled = selectedGame != nil
        for key in [
            Identifier.showInFinder.rawValue,
            Identifier.exportModPack.rawValue,
            Identifier.deleteInstance.rawValue,
        ] {
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

        button.title = ""
        button.image = symbolImage(isRunning ? "stop.fill" : "play.fill", accessibilityDescription: isRunning ? "Stop" : "Play")
        button.isEnabled = selectedGame != nil && hasCurrentPlayer && !isLaunching
    }

    func makeMainItem(for identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case Identifier.playerLabel:
            let avatar = NSImageView()
            avatar.image = configuration?.playerAvatarImage()
            avatar.imageScaling = .scaleProportionallyDown
            avatar.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            let label = NSTextField(labelWithString: configuration?.currentPlayerName() ?? "")
            label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
            label.textColor = .secondaryLabelColor
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail

            let stack = NSStackView(views: [avatar, label])
            stack.orientation = .horizontal
            stack.spacing = 4
            stack.alignment = .centerY

            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = stack
            cachedItems[identifier.rawValue] = item
            return item
        case Identifier.playStop:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(toggleSelectedGame))
            button.image = symbolImage("play.fill", accessibilityDescription: "Play")
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.gamePicker:
            let picker = NSPopoverTouchBarItem(identifier: identifier)
            picker.showsCloseButton = true
            picker.collapsedRepresentationLabel = configuration?.strings.selectGame ?? ""
            cachedItems[identifier.rawValue] = picker
            return picker
        case Identifier.openSettings:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(openInstanceSettingsFromTouchBar))
            button.image = symbolImage("gearshape", accessibilityDescription: "Settings")
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.exportModPack:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(exportModPackFromTouchBar))
            button.image = symbolImage("square.and.arrow.up", accessibilityDescription: "Export Mod Pack")
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.showInFinder:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(showInFinderFromTouchBar))
            button.image = symbolImage("folder", accessibilityDescription: "Show in Finder")
            cachedItems[identifier.rawValue] = button
            return button
        case Identifier.deleteInstance:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(deleteInstanceFromTouchBar))
            button.image = symbolImage("trash", accessibilityDescription: "Delete Instance")
            button.bezelColor = NSColor.systemRed
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

    /// Requests deletion of the selected instance.
    @objc func deleteInstanceFromTouchBar() {
        configuration?.onDeleteInstance()
    }
}
