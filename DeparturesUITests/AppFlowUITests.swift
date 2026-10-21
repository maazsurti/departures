import XCTest

/// End-to-end walk through the shipped app. The same suite runs on iPhone and
/// iPad so the compact stack and the regular-width split view are both checked.
///
/// The test methods are main-actor isolated instead of the whole class: XCTest's
/// `setUpWithError` is nonisolated on older toolchains, and overriding it from a
/// `@MainActor` class fails to compile under Swift 6.
final class AppFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Main flow

    @MainActor
    func testTodayToDetailSavedChangesAndOffline() throws {
        continueAfterFailure = false
        launch()

        XCTAssertTrue(app.staticTexts["Auckland"].waitForExistence(timeout: 15))
        capture("today")

        // Airport picker: switch away and back.
        tapTab("Board")
        let picker = app.buttons["airport-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()

        let wellington = app.buttons["airport-WLG"]
        XCTAssertTrue(wellington.waitForExistence(timeout: 5))
        wellington.tap()
        XCTAssertTrue(app.staticTexts["Wellington"].waitForExistence(timeout: 5))

        app.buttons["airport-picker"].tap()
        let auckland = app.buttons["airport-AKL"]
        XCTAssertTrue(auckland.waitForExistence(timeout: 5))
        auckland.tap()
        capture("board")

        // Open a flight.
        let row = app.descendants(matching: .any).matching(identifier: "flight-row-NZ 612").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()

        XCTAssertTrue(app.navigationBars["NZ 612"].waitForExistence(timeout: 10))
        if isPad, app.windows.firstMatch.frame.width >= 820 {
            let list = app.descendants(matching: .any).matching(identifier: "board-list").firstMatch
            XCTAssertTrue(list.exists, "Wide iPad should keep the board visible beside the detail")
        }
        capture("detail")

        // Star it.
        let star = app.buttons["save-flight"].firstMatch
        if star.waitForExistence(timeout: 3) {
            star.tap()
        } else {
            app.buttons["Save flight"].firstMatch.tap()
        }

        // Saved list picks it up.
        tapTab("Saved")
        let savedRow = app.descendants(matching: .any).matching(identifier: "saved-row-NZ 612").firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10), "Starred flight should appear in Saved")
        capture("saved")

        // Changes feed has content and a summary.
        tapTab("Changes")
        let summary = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'need attention'")
        ).firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Gate changed"].firstMatch.exists)
        capture("changes")

        // Settings is reachable and exposes the demo controls.
        tapTab("Today")
        openSettings()
        XCTAssertTrue(app.switches["offline-toggle"].waitForExistence(timeout: 10))
        capture("settings")
        app.buttons["settings-done"].tap()

        // Offline path. Relaunch with the documented override rather than
        // switching a Form toggle, which is timing-sensitive on CI simulators.
        app.terminate()
        app.launchEnvironment = ["OPEN_TAB": "board", "SIMULATE_OFFLINE": "1"]
        app.launch()

        let banner = app.staticTexts["Could not reach the board. Showing the last saved update."]
        XCTAssertTrue(banner.waitForExistence(timeout: 15), "Offline should surface the cached-data message")
        let cached = app.descendants(matching: .any).matching(identifier: "cached-badge").firstMatch
        XCTAssertTrue(cached.waitForExistence(timeout: 5), "Board should label stale data as cached")
        capture("offline")

        // Back to a live board.
        app.terminate()
        app.launchEnvironment = ["OPEN_TAB": "board"]
        app.launch()
        XCTAssertTrue(app.buttons["airport-picker"].waitForExistence(timeout: 15))
        XCTAssertTrue(banner.waitForNonExistence(timeout: 5))

        // Cross-airport search.
        tapTab("Changes")
        let find = app.buttons["Find a flight"].firstMatch
        if find.waitForExistence(timeout: 5) {
            find.tap()
        } else {
            app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1).tap()
        }
        let field = app.textFields["search-field"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("WLG")
        XCTAssertTrue(app.staticTexts["Wellington · WLG"].waitForExistence(timeout: 5))
        capture("search")
    }

    // MARK: - Deep link

    @MainActor
    func testDeepLinkOpensFlight() throws {
        continueAfterFailure = false
        launch()

        XCTAssertTrue(app.staticTexts["Auckland"].waitForExistence(timeout: 15))

        XCUIDevice.shared.system.open(URL(string: "departures://flight/NZ%20612")!)

        // iOS may ask for confirmation before handing the URL to the app.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for candidate in [app.buttons["Open"], springboard.buttons["Open"]] where candidate.waitForExistence(timeout: 2) {
            candidate.tap()
            break
        }

        XCTAssertTrue(app.navigationBars["NZ 612"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Queenstown"].firstMatch.exists)
        capture("deep-link")
    }

    // MARK: - Rotation

    @MainActor
    func testRotationKeepsContent() throws {
        continueAfterFailure = false
        launch()

        XCTAssertTrue(app.staticTexts["Auckland"].waitForExistence(timeout: 15))
        tapTab("Board")
        XCTAssertTrue(app.buttons["airport-picker"].waitForExistence(timeout: 10))

        for orientation in [UIDeviceOrientation.landscapeLeft, .portraitUpsideDown, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(
                app.buttons["airport-picker"].waitForExistence(timeout: 10),
                "Board should survive \(orientation.rawValue)"
            )
            if orientation == .landscapeLeft {
                capture("landscape")
            }
        }
    }

    // MARK: - Helpers

    @MainActor
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-resetDemoState"]
        app.launchEnvironment = ["OPEN_TAB": "today"]
        app.launch()
    }

    @MainActor
    private func tapTab(_ label: String) {
        let buttons = app.buttons.matching(NSPredicate(format: "label == %@", label))
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 10), "Missing tab \(label)")

        for _ in 0..<3 {
            if buttons.firstMatch.isSelected { return }
            buttons.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            Thread.sleep(forTimeInterval: 0.5)
            if buttons.firstMatch.isSelected { return }
        }
    }

    @MainActor
    private func openSettings() {
        let gear = app.buttons["open-settings"].firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), "Settings gear should be on Today")
        gear.tap()
        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 10),
            "Settings sheet should present"
        )
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
