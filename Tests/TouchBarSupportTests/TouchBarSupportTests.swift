//
//  TouchBarSupportTests.swift
//  TouchBarSupportTests
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import XCTest
@testable import TouchBarSupport

@MainActor
final class TouchBarSupportTests: XCTestCase {
    func testTouchBarTitleKeepsShortNames() {
        let controller = TouchBarController()
        XCTAssertEqual(controller.touchBarTitle(for: "A"), "A")
        XCTAssertEqual(controller.touchBarTitle(for: "12345678901234"), "12345678901234")
    }

    func testTouchBarTitleTruncatesLongNames() {
        let controller = TouchBarController()
        XCTAssertEqual(controller.touchBarTitle(for: "123456789012345"), "12345678901234…")
        XCTAssertEqual(controller.touchBarTitle(for: "这个实例名字特别长需要截断显示"), "这个实例名字特别长需要截断显…")
    }

    func testIdentifierRoundTrip() {
        let id = TouchBarController.Identifier.game("ABC-123")
        let parsed = TouchBarController.Identifier.id(
            afterPrefix: TouchBarController.Identifier.gamePrefix,
            in: id.rawValue
        )
        XCTAssertEqual(parsed, "ABC-123")
    }

    func testIdentifierRejectsForeignPrefix() {
        let id = TouchBarController.Identifier.game("ABC")
        XCTAssertNil(TouchBarController.Identifier.id(afterPrefix: "com.example.other.", in: id.rawValue))
    }

    func testInstanceValueSemantics() {
        let a = TouchBarInstance(id: "1", name: "A")
        XCTAssertEqual(a, TouchBarInstance(id: "1", name: "A"))
        XCTAssertNotEqual(a, TouchBarInstance(id: "2", name: "A"))
        XCTAssertEqual(a.id, "1")
        XCTAssertEqual(a.name, "A")
    }

    func testDefaultStringsCarryPlayStopTitles() {
        let strings = TouchBarStrings(
            selectGame: "选择游戏",
            instanceSettings: "实例设置",
            play: "启动",
            stop: "停止",
            exportModPack: "导出整合包",
            showInFinder: "打开目录"
        )
        XCTAssertEqual(strings.play, "启动")
        XCTAssertEqual(strings.stop, "停止")
        XCTAssertEqual(strings.exportModPack, "导出整合包")
        XCTAssertEqual(strings.showInFinder, "打开目录")
    }
}
