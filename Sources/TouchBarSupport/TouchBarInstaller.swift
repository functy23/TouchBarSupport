//
//  TouchBarInstaller.swift
//  TouchBarSupport
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import AppKit
import SwiftUI

/// A zero-size AppKit view that reports when it moves into a window.
final class TouchBarAttachmentView: NSView {
    var onWindowChanged: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            onWindowChanged?(window)
        }
    }
}

/// Installs and keeps the launcher Touch Bar in sync with the app-provided configuration.
struct TouchBarInstaller: NSViewRepresentable {
    let configuration: TouchBarSupportConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = TouchBarAttachmentView()
        view.onWindowChanged = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(configuration: configuration)
        if let window = nsView.window {
            context.coordinator.controller.install(on: window)
        }
    }
}

extension TouchBarInstaller {
    @MainActor
    final class Coordinator {
        let controller = TouchBarController()
        private var latestConfiguration: TouchBarSupportConfiguration?

        func attach(to window: NSWindow) {
            controller.install(on: window)
            if let latestConfiguration {
                controller.update(with: latestConfiguration)
            }
        }

        func update(configuration: TouchBarSupportConfiguration) {
            latestConfiguration = configuration
            controller.update(with: configuration)
        }
    }
}
