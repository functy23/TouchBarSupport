//
//  TouchBarController+Actions.swift
//  TouchBarSupport
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit
import SwiftUI

/// An image view that upscales its image with nearest-neighbor interpolation,
/// so small (e.g. 16×16 pixel-art) game icons stay crisp when enlarged.
final class TouchBarGameIconView: NSImageView {
    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current
        let previousInterpolation = context?.imageInterpolation
        context?.imageInterpolation = .none
        super.draw(dirtyRect)
        if let previousInterpolation {
            context?.imageInterpolation = previousInterpolation
        }
    }
}

extension TouchBarController {
    func symbolImage(_ name: String, accessibilityDescription: String? = nil) -> NSImage {
        NSImage(systemSymbolName: name, accessibilityDescription: accessibilityDescription) ?? NSImage()
    }

    /// Keeps the read-only current-player label in sync with the active player.
    func updatePlayerLabelItem(currentPlayer: String?) {
        guard let item = cachedItems[Identifier.playerLabel.rawValue] as? NSCustomTouchBarItem,
              let container = item.view as? NSStackView,
              let label = container.arrangedSubviews.last as? NSTextField,
              let hosting = container.arrangedSubviews.first as? NSHostingView<AnyView> else { return }

        label.stringValue = currentPlayer ?? ""
        let hasGame = configuration?.currentGameName() != nil
        label.lineBreakMode = hasGame ? .byTruncatingTail : .byClipping
        playerLabelWidthConstraint?.isActive = hasGame
        if let avatarView = configuration?.playerAvatarView() {
            hosting.rootView = avatarView
        }
    }

    /// Keeps the read-only selected-instance label and its icon in sync with the selection.
    func updateSelectedGameItem(currentGameName: String?) {
        guard let item = cachedItems[Identifier.selectedGame.rawValue] as? NSCustomTouchBarItem,
              let container = item.view as? NSStackView,
              let imageView = container.arrangedSubviews.first as? NSImageView,
              let label = container.arrangedSubviews.last as? NSTextField else { return }

        label.stringValue = currentGameName ?? ""
        label.toolTip = currentGameName
        if currentGameName != lastRenderedGameName {
            lastRenderedGameName = currentGameName
            imageView.image = gameIconImageOrSymbol()
        }
    }

    func updatePlayStopItem(hasCurrentPlayer: Bool) {
        let isRunning = configuration?.isRunning() ?? false
        let isLaunching = configuration?.isLaunching() ?? false

        guard let button = itemOrMake(for: Identifier.playStop) as? NSButtonTouchBarItem else { return }
        button.image = symbolImage(isRunning ? "stop.fill" : "play.fill", accessibilityDescription: isRunning ? "Stop" : "Play")
        button.isEnabled = hasCurrentPlayer && !isLaunching
    }

    func makeMainItem(for identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case Identifier.playerLabel:
            let hosting = NSHostingView(rootView: configuration?.playerAvatarView() ?? AnyView(EmptyView()))
            hosting.sizingOptions = [.intrinsicContentSize]
            hosting.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            let label = NSTextField(labelWithString: configuration?.currentPlayerName() ?? "")
            label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraint = label.widthAnchor.constraint(lessThanOrEqualToConstant: 90)
            widthConstraint.isActive = true
            playerLabelWidthConstraint = widthConstraint

            let stack = NSStackView(views: [hosting, label])
            stack.orientation = .horizontal
            stack.spacing = 4
            stack.alignment = .centerY

            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = stack
            return item
        case Identifier.playStop:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(toggleSelectedGame))
            button.image = symbolImage("play.fill", accessibilityDescription: "Play")
            return button
        case Identifier.selectedGame:
            let imageView = TouchBarGameIconView()
            imageView.image = gameIconImageOrSymbol()
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = 6
            imageView.layer?.masksToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 28).isActive = true

            let label = NSTextField(labelWithString: configuration?.currentGameName() ?? "")
            label.font = NSFont.systemFont(ofSize: 15, weight: .medium)
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 100).isActive = true

            let stack = NSStackView(views: [imageView, label])
            stack.orientation = .horizontal
            stack.spacing = 4
            stack.alignment = .centerY

            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = stack
            return item
        case Identifier.openSettings:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(openInstanceSettingsFromTouchBar))
            button.image = symbolImage("gearshape", accessibilityDescription: "Settings")
            return button
        case Identifier.exportModPack:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(exportModPackFromTouchBar))
            button.image = symbolImage("square.and.arrow.up", accessibilityDescription: "Export Mod Pack")
            return button
        case Identifier.showInFinder:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(showInFinderFromTouchBar))
            button.image = symbolImage("folder", accessibilityDescription: "Show in Finder")
            return button
        case Identifier.deleteInstance:
            let button = NSButtonTouchBarItem(identifier: identifier, title: "", target: self, action: #selector(deleteInstanceFromTouchBar))
            button.image = symbolImage("trash", accessibilityDescription: "Delete Instance")
            button.bezelColor = NSColor.systemRed
            return button
        default:
            return nil
        }
    }

    /// The NSImage shown for the selected-instance icon: the app-provided game
    /// icon image when available, otherwise the built-in game symbol.
    func gameIconImageOrSymbol() -> NSImage {
        if let image = configuration?.gameIconImage() {
            return image
        }
        return symbolImage("gamecontroller.fill", accessibilityDescription: configuration?.currentGameName())
    }

    @objc func toggleSelectedGame() {
        guard let configuration,
              configuration.currentGameName() != nil,
              configuration.currentPlayerName() != nil else {
            return
        }
        configuration.onPlayStop()
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

    /// Requests deletion of the selected instance via the app-provided action.
    @objc func deleteInstanceFromTouchBar() {
        configuration?.onDeleteInstance()
    }
}
