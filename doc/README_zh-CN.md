<div align="center">

# 🎛️ TouchBarSupport

**一个独立的 Swift Package，为 macOS 应用（macOS 14+）带来可配置、与应用无关的 Touch Bar。**

[![TouchBarSupport](https://img.shields.io/badge/TouchBarSupport-TBS-orange.svg)](https://github.com/functy23/TouchBarSupport)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-red.svg?logo=swift&logoColor=white)](https://swift.org/)
[![Top Language](https://img.shields.io/github/languages/top/functy23/TouchBarSupport?style=flat)](https://github.com/functy23/TouchBarSupport)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg?logo=apple&logoColor=white)](https://github.com/functy23/TouchBarSupport)

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg?logo=opensourceinitiative&logoColor=white)](https://opensource.org/licenses/AGPL-3.0)

[![Stars](https://img.shields.io/github/stars/functy23/TouchBarSupport?style=flat&logo=github)](https://github.com/functy23/TouchBarSupport/stargazers)
[![Repo Size](https://img.shields.io/github/repo-size/functy23/TouchBarSupport?style=flat&logo=github)](https://github.com/functy23/TouchBarSupport)
[![Contributors](https://img.shields.io/github/contributors/functy23/TouchBarSupport?color=ee8449&logo=githubsponsors)](https://github.com/functy23/TouchBarSupport/graphs/contributors)

[Issues](https://github.com/functy23/TouchBarSupport/issues)

[English](../README.md) | **简体中文**
</div>

---

一个独立的 Swift Package，为 macOS 应用（macOS 14+）带来可配置、与具体应用无关的
Touch Bar。最初从
[Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher) 中提取而来。

## 功能特性

- 当前玩家标签（只读，不支持切换玩家）
- 已选实例的图标 + 标签（只读；选择操作在应用内完成）
- 播放/停止按钮
- 实例设置按钮
- 导出整合包按钮（对无法导出的实例隐藏，例如原版）
- 在 Finder 中显示按钮
- 删除实例按钮（确认与删除流程由应用负责）

本包不持有任何应用状态：所有内容都通过闭包注入，因此 Touch Bar 会与你应用在这些
闭包中读取的任何由 `Observation` 支撑的状态保持同步。

## 用法

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

## 许可证

见 [LICENSE](LICENSE) — AGPL-3.0，与 Swift Craft Launcher 保持一致。
