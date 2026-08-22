# TouchBarSupport

A standalone Swift Package that brings a configurable, app-agnostic Touch Bar
to macOS apps (macOS 14+). Originally extracted from
[Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher).

## Features

- Current-player label (read-only, no player switching)
- Play/stop button
- Instance picker: collapsed shows the current instance; expanding lists all
  instances with equal-width auto-distributed buttons, tail-truncated titles,
  and a check mark on the current selection; tapping one selects and collapses
- Instance-settings button

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
    instances: { gameStore.games.map { TouchBarInstance(id: $0.id, name: $0.name) } },
    currentInstanceID: { gameStore.selectedID },
    isRunning: { gameID in gameStore.isRunning(gameID) },
    isLaunching: { gameID in gameStore.isLaunching(gameID) },
    onSelectInstance: { gameStore.select($0) },
    onPlayStop: { gameStore.togglePlayStop() },
    onOpenSettings: { openSettings() },
    strings: TouchBarStrings(
        selectGame: "Select a game",
        instanceSettings: "Instance Settings"
    )
)
```

## License

See [LICENSE](LICENSE) — AGPL-3.0, matching Swift Craft Launcher.

