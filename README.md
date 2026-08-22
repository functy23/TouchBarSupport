# TouchBarSupport

A standalone Swift Package that brings a configurable, app-agnostic Touch Bar
to macOS apps (macOS 14+). Originally extracted from
[Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher).

## Features

- Current-player label (read-only, no player switching)
- Selected-instance icon + label (read-only; the selection is made in the app)
- Play/stop button
- Instance-settings button
- Export-mod-pack button (hidden for instances that cannot export, e.g. vanilla)
- Show-in-Finder button
- Delete-instance button (the app owns the confirmation/deletion flow)

The package owns zero application state: everything is injected through
closures, so the Touch Bar stays in sync with any `Observation`-backed state
your app reads inside them.

## Usage

```swift
import SwiftUI
import TouchBarSupport

var body: some View {
    content
        .touchBarSupport(configuration)
}

let configuration = TouchBarSupportConfiguration(
    currentPlayerName: { playerStore.currentPlayer?.name },
    playerAvatarView: { playerStore.currentPlayer?.avatarView },
    currentGameName: { playerStore.selectedGame?.name },
    gameIconImage: { playerStore.selectedGame?.icon },
    isRunning: { playerStore.isSelectedRunning },
    isLaunching: { playerStore.isSelectedLaunching },
    canExportModPack: { playerStore.selectedGame?.hasModLoader ?? false },
    onPlayStop: { playerStore.togglePlayStop() },
    onOpenSettings: { openSettings() },
    onExportModPack: { exportSelectedModPack() },
    onShowInFinder: { revealSelectedInFinder() },
    onDeleteInstance: { confirmDeleteSelected() }
)
```

## License

See [LICENSE](LICENSE) — AGPL-3.0, matching Swift Craft Launcher.

