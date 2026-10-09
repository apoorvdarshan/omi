import XCTest

/// A calm, human-paced tour of the demo mode (PreviewApp's "demo" launch argument) for a screen recording:
/// one test per scene, each starting and ending on Home so the recorded scenes join smoothly.
///
/// Opt-in: a scene runs only when the test runner's DEMO_TOUR_DIR names a directory (pass
/// TEST_RUNNER_DEMO_TOUR_DIR to xcodebuild); otherwise it is skipped, so the regular suite never waits on
/// it. In that directory each scene hands off to the recorder: it writes `<scene>.ready` once its first
/// screen is up and waits for `<scene>.recording`; when it is done it writes `<scene>.done` and waits for
/// `<scene>.stopped`.
final class PreviewDemoTourTests: XCTestCase {
    private var handoff: URL!

    override func setUpWithError() throws {
        guard let path = ProcessInfo.processInfo.environment["DEMO_TOUR_DIR"], !path.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_DEMO_TOUR_DIR to record the demo tour")
        }
        handoff = URL(fileURLWithPath: path, isDirectory: true)
        continueAfterFailure = false
    }

    func testDemoTour01HomeAndConversation() {
        let app = launch()
        let conversation = app.buttons["native-conversation-conv-product-sync"]
        XCTAssertTrue(conversation.waitForExistence(timeout: 20))
        record("01-home") {
            pause(1.4)
            // The recap carousel pages card by card, then returns to the first.
            for id in ["recap-1", "recap-2"] { swipe(app.buttons["native-recap-\(id)"], left: true); pause(0.5) }
            for id in ["recap-3", "recap-2"] { swipe(app.buttons["native-recap-\(id)"], left: false) }
            pause(0.4)
            for _ in 0..<3 { scroll(app, by: 320); pause(0.7) }
            // Back up to Today without overshooting the top, whose bounce would stall the next tap.
            for _ in 0..<2 { scroll(app, by: -330, speed: 600) }
            pause(0.5)
            conversation.tap()
            XCTAssertTrue(app.staticTexts["Weekly product sync"].waitForExistence(timeout: 10))
            pause(1.6)
            scroll(app, by: 300)
            pause(1.0)
            app.segmentedControls.buttons["Transcript"].tap()
            pause(1.2)
            for _ in 0..<2 { scroll(app, by: 320); pause(0.6) }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(conversation.waitForExistence(timeout: 10))
            pause(0.6)
            scroll(app, by: -500, speed: 700)
            pause(1.2)
        }
    }

    func testDemoTour02AskOmi() {
        let app = launch()
        XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 20))
        record("02-chat") {
            pause(0.8)
            app.buttons["native-chat"].tap()
            let followup = app.buttons["What should I prepare for Thursday?"]
            XCTAssertTrue(followup.waitForExistence(timeout: 10))
            pause(1.4)
            // Back through the conversation to the rich reply's table, then down again.
            for _ in 0..<3 { scroll(app, by: -260, speed: 380); pause(0.6) }
            for _ in 0..<2 { scroll(app, by: 420, speed: 650) }
            scroll(app, by: 400, speed: 650)
            pause(0.4)
            followup.tap()
            XCTAssertTrue(app.staticTexts["Check that all 500 invites are queued"].waitForExistence(timeout: 15))
            pause(2.2)
            app.buttons["back"].tap()
            XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour03SelectDeleteAndUndo() {
        let app = launch()
        XCTAssertTrue(app.buttons["native-browse-all"].waitForExistence(timeout: 20))
        record("03-selection") {
            pause(1.0)
            app.buttons["native-browse-all"].tap()
            XCTAssertTrue(app.buttons["select"].waitForExistence(timeout: 10))
            pause(1.2)
            app.buttons["select"].tap()
            XCTAssertTrue(app.buttons["bulk_delete"].waitForExistence(timeout: 10))
            pause(0.2)
            cell(app, "conv-morning-run").tap()
            pause(0.3)
            cell(app, "conv-groceries").tap()
            XCTAssertTrue(app.staticTexts["2 selected"].waitForExistence(timeout: 10))
            pause(1.0)
            app.buttons["bulk_delete"].tap()
            let undo = app.buttons["native-toast-action"]
            XCTAssertTrue(undo.waitForExistence(timeout: 10))
            pause(1.6)
            undo.tap()
            XCTAssertTrue(cell(app, "conv-groceries").waitForExistence(timeout: 10))
            pause(1.4)
            app.buttons["back"].tap()
            XCTAssertTrue(app.buttons["native-browse-all"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour04TasksAndSheet() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Tasks"].waitForExistence(timeout: 20))
        record("04-tasks") {
            pause(1.0)
            app.tabBars.buttons["Tasks"].tap()
            let task = app.buttons["task-mocks"]
            XCTAssertTrue(task.waitForExistence(timeout: 10))
            pause(1.2)
            task.tap()
            XCTAssertTrue(app.staticTexts["native-toast-message"].waitForExistence(timeout: 10))
            pause(1.0)
            scroll(app, by: 300)
            pause(0.6)
            scroll(app, by: -340, speed: 600)
            pause(0.4)
            app.buttons["task_add"].tap()
            let field = app.textFields["draft"].exists ? app.textFields["draft"] : app.textViews["draft"]
            XCTAssertTrue(field.waitForExistence(timeout: 10))
            pause(0.8)
            field.tap()
            typeSlowly("Call Sarah", into: field)
            pause(0.8)
            app.buttons["cancel"].tap()
            let discard = app.alerts["Discard Changes?"]
            XCTAssertTrue(discard.waitForExistence(timeout: 10))
            pause(1.2)
            discard.buttons["Discard"].tap()
            XCTAssertTrue(waitForDisappearance(field))
            pause(0.8)
            app.tabBars.buttons["Home"].tap()
            XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour05MemoriesAndGraph() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Memories"].waitForExistence(timeout: 20))
        record("05-memories") {
            pause(1.0)
            app.tabBars.buttons["Memories"].tap()
            let card = app.buttons["graph_card"]
            XCTAssertTrue(card.waitForExistence(timeout: 15))
            pause(1.2)
            scroll(app, by: 320)
            pause(0.6)
            scroll(app, by: -380, speed: 600)
            pause(0.4)
            card.tap()
            let graph = app.otherElements["graph_canvas"]
            XCTAssertTrue(graph.waitForExistence(timeout: 15))
            pause(1.2)
            // One finger turns the graph in 3D, a pinch zooms, and a tap highlights a person.
            let centre = graph.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            centre.withOffset(CGVector(dx: -110, dy: -20)).press(forDuration: 0.05,
                thenDragTo: centre.withOffset(CGVector(dx: 110, dy: 30)), withVelocity: XCUIGestureVelocity(rawValue: 130),
                thenHoldForDuration: 0.2)
            pause(0.6)
            graph.pinch(withScale: 1.5, velocity: 0.5)
            pause(0.6)
            let sarah = app.buttons["graph_canvas_node_sarah"]
            if sarah.exists && sarah.isHittable { sarah.tap() } else { app.buttons["graph_canvas_node_me"].tap() }
            pause(1.6)
            // A tap on the background clears the selection.
            graph.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.08)).tap()
            pause(1.0)
            app.buttons["back"].tap()
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            pause(0.6)
            app.tabBars.buttons["Home"].tap()
            XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour06Settings() {
        let app = launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 20))
        record("06-settings") {
            pause(1.0)
            app.tabBars.buttons["Settings"].tap()
            XCTAssertTrue(app.buttons["account"].waitForExistence(timeout: 10))
            pause(0.8)
            scroll(app, by: 320)
            pause(0.8)
            scroll(app, by: 220)
            pause(0.8)
            scroll(app, by: -600, speed: 800)
            pause(0.6)
            app.tabBars.buttons["Home"].tap()
            XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour07SearchAndEmptyState() {
        let app = launch()
        XCTAssertTrue(app.buttons["native-search"].waitForExistence(timeout: 20))
        record("07-search") {
            pause(1.0)
            app.buttons["native-search"].tap()
            let field = app.searchFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 10))
            pause(1.2)
            field.tap()
            typeSlowly("Sarah", into: field)
            XCTAssertTrue(app.buttons["conv-coffee-sarah"].waitForExistence(timeout: 10))
            pause(1.6)
            for _ in 0..<5 { field.typeText(XCUIKeyboardKey.delete.rawValue) }
            typeSlowly("tax return", into: field)
            XCTAssertTrue(app.staticTexts["No results for “tax return”"].waitForExistence(timeout: 10))
            pause(2.0)
            // The active search field replaces the navigation bar until it closes.
            app.buttons["close"].tap()
            XCTAssertTrue(app.buttons["back"].waitForExistence(timeout: 10))
            pause(0.8)
            app.buttons["back"].tap()
            XCTAssertTrue(app.buttons["native-search"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    func testDemoTour08LightHomeAndChat() {
        let app = launch(light: true)
        XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 20))
        record("08-light") {
            pause(1.4)
            scroll(app, by: 360)
            pause(0.6)
            scroll(app, by: -440, speed: 650)
            pause(0.4)
            app.buttons["native-chat"].tap()
            let field = app.textFields["chat_draft"].exists ? app.textFields["chat_draft"] : app.textViews["chat_draft"]
            XCTAssertTrue(field.waitForExistence(timeout: 10))
            pause(1.0)
            field.tap()
            typeSlowly("When is book club?", into: field)
            pause(0.4)
            app.buttons["chat_send"].tap()
            XCTAssertTrue(app.staticTexts["You're reading chapters 12–15, and it's your turn to bring snacks."]
                .waitForExistence(timeout: 15))
            pause(2.2)
            app.buttons["back"].tap()
            XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
            pause(1.2)
        }
    }

    // MARK: Helpers

    /// Launches the demo with animations, as a person sees it.
    private func launch(light: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = light ? ["demo", "light"] : ["demo"]
        app.launch()
        return app
    }

    /// Hands the scene to the recorder once its first screen settled, then runs the tour while it records.
    private func record(_ scene: String, _ tour: () -> Void) {
        pause(1.0)
        signal("\(scene).ready")
        waitFor("\(scene).recording")
        tour()
        signal("\(scene).done")
        waitFor("\(scene).stopped")
    }

    private func signal(_ name: String) {
        XCTAssertTrue(FileManager.default.createFile(atPath: handoff.appendingPathComponent(name).path, contents: Data()),
                      "Could not write \(name)")
    }

    private func waitFor(_ name: String, timeout: TimeInterval = 90) {
        let path = handoff.appendingPathComponent(name).path
        let deadline = Date().addingTimeInterval(timeout)
        while !FileManager.default.fileExists(atPath: path) {
            XCTAssertLessThan(Date(), deadline, "The recorder never wrote \(name)")
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func pause(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    /// Drags the page by [distance] points (positive moves further down) at a reading pace, holding before
    /// lifting so the list stops with the finger rather than flinging.
    private func scroll(_ app: XCUIApplication, by distance: CGFloat, speed: CGFloat = 420) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: distance > 0 ? 0.68 : 0.3))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)),
                    withVelocity: XCUIGestureVelocity(rawValue: speed), thenHoldForDuration: 0.12)
    }

    /// Pages a carousel card with a deliberate horizontal drag.
    private func swipe(_ element: XCUIElement, left: Bool) {
        let from = element.coordinate(withNormalizedOffset: CGVector(dx: left ? 0.85 : 0.15, dy: 0.5))
        let to = element.coordinate(withNormalizedOffset: CGVector(dx: left ? 0.05 : 0.95, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: XCUIGestureVelocity(rawValue: 700), thenHoldForDuration: 0)
    }

    /// Types one character at a time, at about a person's pace.
    private func typeSlowly(_ text: String, into element: XCUIElement) {
        for character in text {
            element.typeText(String(character))
            pause(0.08)
        }
    }

    /// The list cell that holds the row [id].
    private func cell(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.cells.containing(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter.wait(for: [gone], timeout: timeout) == .completed
    }
}
