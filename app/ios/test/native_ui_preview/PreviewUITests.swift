import XCTest

final class PreviewUITests: XCTestCase {
    func testMainTabsUseSystemGlassAndAcknowledgeEveryDestination() {
        let app = start(["navigation", "chrome"])
        for title in ["Tasks", "Memories", "Apps", "Settings", "Home"] {
            let tab = app.tabBars.buttons[title]
            XCTAssertTrue(tab.waitForExistence(timeout: 10))
            XCTAssertTrue(tab.isHittable)
            XCTAssertGreaterThanOrEqual(tab.frame.height, 44)
            tab.tap()
            let acknowledged = NSPredicate { _, _ in
                app.staticTexts["preview-last-action"].label == "main_destination:\(title.lowercased())" && tab.isSelected
            }
            expectation(for: acknowledged, evaluatedWith: nil)
            waitForExpectations(timeout: 5)
        }
        capture(app, "native-liquid-glass-main-tabs")
    }

    func testPasswordInputIsSecureAndClearsWhenTheOwnerWithdrawsIt() {
        let app = start(["surface", "secure-input"])
        let input = app.secureTextFields["draft"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("fixture-key")
        let typed = NSPredicate { _, _ in app.staticTexts["preview-last-action"].label == "draft:fixture-key" }
        expectation(for: typed, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        app.buttons["reset_key"].tap()
        let replacement = app.secureTextFields["replacement_key"]
        XCTAssertTrue(replacement.waitForExistence(timeout: 5))
        XCTAssertEqual(replacement.value as? String, "API key")
        XCTAssertFalse(input.exists)
        app.buttons["save"].tap()
        XCTAssertTrue(app.staticTexts["saved:"].waitForExistence(timeout: 5))
        capture(app, "native-secure-transcription-input")
    }

    func testPhotoSupportsDoubleTapPinchPanAndReset() {
        let app = start(["surface", "photo"])
        let photo = app.scrollViews["photo"]
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        XCTAssertEqual(photo.value as? String, "100%")
        photo.doubleTap()
        let zoomed = NSPredicate { _, _ in (photo.value as? String) == "200%" }
        expectation(for: zoomed, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        photo.swipeLeft()
        capture(app, "native-photo-zoom-pan")
        photo.doubleTap()
        let reset = NSPredicate { _, _ in (photo.value as? String) == "100%" }
        expectation(for: reset, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        photo.pinch(withScale: 1.5, velocity: 1)
        XCTAssertNotEqual(photo.value as? String, "100%")
        photo.doubleTap()
        expectation(for: reset, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.buttons["save"].isHittable)
    }

    func testReaderPlaybackScrubAndTranscriptContextMenu() {
        let app = start(["surface", "reader"])
        let slider = app.sliders["position"]
        XCTAssertTrue(slider.waitForExistence(timeout: 10))
        slider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertTrue(app.staticTexts["preview-last-action"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["preview-last-action"].label.hasPrefix("position:"))
        app.buttons["play"].tap()
        XCTAssertTrue(app.staticTexts["play:"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["play"].label, "Pause")
        let line = app.buttons["segment:0"]
        XCTAssertTrue(line.isHittable)
        line.press(forDuration: 0.8)
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.staticTexts["segment:0:edit"].waitForExistence(timeout: 5))
        capture(app, "native-conversation-reader-player")
    }

    func testReaderLargeTextKeepsFooterAndBackReachable() {
        let app = start(["surface", "reader", "large"])
        XCTAssertTrue(app.buttons["play"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["play"].isHittable)
        XCTAssertTrue(app.buttons["ask"].isHittable)
        XCTAssertTrue(app.buttons["back"].isHittable)
        app.buttons["ask"].tap()
        XCTAssertTrue(app.staticTexts["ask:"].waitForExistence(timeout: 5))
        capture(app, "native-conversation-reader-large-text")
    }

    func testDialerHoldPlusAndClearDoNotAlsoTap() {
        let app = start(["surface", "keypad"])
        let zero = app.buttons["keypad_key_0"]
        XCTAssertTrue(zero.waitForExistence(timeout: 10))
        zero.press(forDuration: 0.8)
        XCTAssertTrue(app.staticTexts["keypad:+"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["keypad"].label, "+")
        app.buttons["keypad_key_1"].tap()
        XCTAssertTrue(app.staticTexts["keypad:1"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["keypad"].label, "+1")
        app.buttons["keypad"].press(forDuration: 0.8)
        XCTAssertTrue(app.staticTexts["keypad:clear"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["keypad"].label, "Enter number")
        capture(app, "native-phone-keypad")
    }

    func testDtmfKeepsEveryRapidDigitInOrderBeforeAction() {
        let app = start(["surface", "keypad", "dtmf"])
        app.buttons["preview-burst-keys"].tap()
        XCTAssertTrue(app.staticTexts["keys:1,2,3,*,#,"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["keypad"].label, "123*#")
        XCTAssertFalse(app.buttons["keypad"].exists)
        app.buttons["keypad_key_0"].press(forDuration: 0.8)
        XCTAssertTrue(app.staticTexts["keypad:0"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["keypad"].label, "123*#0")
        capture(app, "native-dtmf-ordered-keys")
    }

    func testFailedKeypadStopsQueuedCommandsAndPreventsFollowingAction() {
        let app = start(["surface", "keypad", "dtmf", "failed-key"])
        app.buttons["preview-burst-keys"].tap()
        XCTAssertTrue(app.staticTexts["native-surface-error"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["keys:1,2,3,*,#,"].exists)
        XCTAssertEqual(app.staticTexts["keypad"].label, "Enter number")
    }

    func testCallTranscriptIsPlainTextRatherThanMarkdown() {
        let app = start(["surface", "plain-transcript"])
        XCTAssertTrue(app.staticTexts["Say **two stars** and [a link](https://example.com)"].waitForExistence(timeout: 10))
    }

    func testLargeTextKeypadKeepsLastRowAndNavigationReachable() {
        let app = start(["surface", "keypad", "large"])
        XCTAssertTrue(app.buttons["keypad_key_1"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["keypad_key_1"].isHittable)
        for _ in 0..<4 where !app.buttons["keypad_key_#"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["keypad_key_#"].isHittable)
        app.buttons["keypad_key_#"].tap()
        XCTAssertTrue(app.staticTexts["keypad:#"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["save"].isHittable)
        capture(app, "native-keypad-large-text")
    }

    func testCountryChoiceFitsAbovePhoneAndPreservesSearch() {
        let app = start(["surface", "country"])
        let country = app.buttons["country"]
        let phone = app.textFields["phone"]
        XCTAssertTrue(country.waitForExistence(timeout: 10))
        XCTAssertTrue(country.isHittable)
        XCTAssertLessThanOrEqual(country.frame.maxY, phone.frame.minY)
        capture(app, "native-country-choice")
        country.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("372")
        XCTAssertFalse(app.buttons["country_option_US"].exists)
        app.buttons["country_option_EE"].tap()
        XCTAssertTrue(app.staticTexts["country:EE"].waitForExistence(timeout: 5))
        XCTAssertFalse(search.exists)
    }

    func testOnboardingBackAppearsWhenNavigationChromeArrivesAfterMount() {
        let app = start(["surface", "late-toolbar"])
        let back = app.buttons["onboarding_back"]
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        XCTAssertTrue(back.isHittable)
        capture(app, "native-onboarding-late-back")
        back.tap()
        XCTAssertTrue(app.staticTexts["onboarding_back:"].waitForExistence(timeout: 5))
    }

    func testNativeModalReturnsOnlyExplicitSaveAndLatestText() {
        let app = start(["modal"])
        app.buttons["modal-open"].tap()
        let field = app.textFields["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Avery final edit")
        app.buttons["save"].tap()
        XCTAssertTrue(app.staticTexts["saved:Avery final edit:false"].waitForExistence(timeout: 10))
        XCTAssertFalse(field.exists)
        capture(app, "native-modal-explicit-save")
    }

    func testNativeModalCancelGuardsDirtyInput() {
        let app = start(["modal"])
        app.buttons["modal-open"].tap()
        let field = app.textFields["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Unsaved person")
        app.buttons["cancel"].tap()
        XCTAssertTrue(app.alerts["Discard Changes?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Keep Editing"].tap()
        XCTAssertEqual(field.value as? String, "Unsaved person")
        app.buttons["cancel"].tap()
        app.alerts.buttons["Discard"].tap()
        XCTAssertTrue(app.staticTexts["Cancelled without saving"].waitForExistence(timeout: 10))
        XCTAssertFalse(field.exists)
        capture(app, "native-modal-discard")
    }

    func testNativeModalSessionEndDismissesPrivateInput() {
        let app = start(["modal", "expire"])
        app.buttons["modal-open"].tap()
        XCTAssertTrue(app.textFields["draft"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cancelled without saving"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["draft"].exists)
        XCTAssertFalse(app.buttons["save"].exists)
    }

    func testNativeConfirmationUsesSystemAlertAndCancels() {
        let app = start(["modal", "alert"])
        app.buttons["modal-open"].tap()
        XCTAssertTrue(app.alerts["Edit Person"].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Cancelled without saving"].waitForExistence(timeout: 10))
    }

    func testNativeModalSaveIncludesLatestSwitchChoice() {
        let app = start(["modal"])
        app.buttons["modal-open"].tap()
        let toggle = app.switches["opt_out"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        toggle.switches.firstMatch.tap()
        app.buttons["save"].tap()
        XCTAssertTrue(app.staticTexts["saved::true"].waitForExistence(timeout: 10))
    }
    func testLabelRowRendersSymbol() {
        let app = start(["surface", "rows"])
        let symbol = app.images.matching(identifier: "label_symbol").firstMatch
        XCTAssertTrue(symbol.waitForExistence(timeout: 10))
        let row = app.staticTexts["label_symbol"]
        XCTAssertEqual(row.label, "Bluetooth connected")
        // The symbol leads the title inside its own row; a label without a symbol draws none.
        XCTAssertTrue(row.frame.contains(CGPoint(x: symbol.frame.midX, y: symbol.frame.midY)))
        XCTAssertLessThan(symbol.frame.minX - row.frame.minX, 40)
        XCTAssertEqual(app.images.matching(identifier: "label_plain").count, 0)
        let warning = app.images.matching(identifier: "label_warning").firstMatch
        XCTAssertTrue(warning.exists)
        let screenshot = app.screenshot().image
        XCTAssertTrue(containsRed(screenshot, in: warning.frame), "A destructive label's symbol is red")
        XCTAssertFalse(containsRed(screenshot, in: symbol.frame))
        capture(app, "native-label-symbols")
    }

    func testTaskTitleWithoutOpenOptionSendsNothing() {
        let app = start(["surface", "rows"])
        let title = app.staticTexts["task_static"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        // Only the checkbox is a button when the owner offers no 'open'; an 'open' task's title is one too.
        XCTAssertEqual(app.buttons.matching(identifier: "task_static").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "task_open").count, 2)
        title.tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(app.staticTexts["preview-last-action"].label, "Preview fixture")
        app.buttons["task_static"].tap()
        XCTAssertTrue(app.staticTexts["task_static:true"].waitForExistence(timeout: 5))
        title.press(forDuration: 0.8)
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["task_static:delete"].waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "task_open").element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["task_open:open"].waitForExistence(timeout: 5))
    }

    func testSelectionTogglesOptimisticallyAndSendsTheSortedSet() {
        let app = start(["surface", "selection", "slow-selection"])
        let row = app.staticTexts["conv_3"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let cell = listCell(app, "conv_3")
        XCTAssertFalse(cell.isSelected)
        XCTAssertTrue(listCell(app, "conv_1").isSelected)
        row.tap()
        // The circle fills at once, before the owner answers the slow command.
        expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: cell)
        waitForExpectations(timeout: 2)
        XCTAssertFalse(app.staticTexts["_selection:conv_1,conv_3"].exists)
        XCTAssertTrue(app.staticTexts["_selection:conv_1,conv_3"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["2 selected"].waitForExistence(timeout: 5))
        XCTAssertTrue(cell.isSelected)
        capture(app, "native-list-selection")
    }

    func testBottomBarDeleteWaitsForThePendingSelection() {
        let app = start(["surface", "selection", "slow-selection"])
        XCTAssertTrue(app.staticTexts["conv_2"].waitForExistence(timeout: 10))
        app.staticTexts["conv_2"].tap()
        // Delete is tapped while the selection command is still pending; it acts on the new set.
        XCTAssertFalse(app.staticTexts["_selection:conv_1,conv_2"].exists)
        app.buttons["bulk_delete"].tap()
        XCTAssertTrue(app.staticTexts["bulk_delete:conv_1,conv_2"].waitForExistence(timeout: 15))
    }

    func testBottomBarDeleteStopsWhenThePendingSelectionFails() {
        let app = start(["surface", "selection", "slow-selection", "failed-selection"])
        XCTAssertTrue(app.staticTexts["conv_2"].waitForExistence(timeout: 10))
        app.staticTexts["conv_2"].tap()
        app.buttons["bulk_delete"].tap()
        // The refused selection reverts, so Delete must not act on a set the user never saw.
        XCTAssertTrue(app.staticTexts["native-surface-error"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["bulk_delete:conv_1"].waitForExistence(timeout: 3))
        XCTAssertFalse(listCell(app, "conv_2").isSelected)
    }

    func testSelectionKeepsOtherRowsUsableAndSuppressesSwipes() {
        let app = start(["surface", "selection"])
        let more = app.buttons["more"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        XCTAssertFalse(listCell(app, "more").isSelected)
        // iOS 16 has no selectionDisabled, so a non-selectable row is disabled while selecting there.
        if #available(iOS 17.0, *) {
            more.tap()
            XCTAssertTrue(app.staticTexts["more:"].waitForExistence(timeout: 5))
            XCTAssertFalse(listCell(app, "more").isSelected)
        }
        listCell(app, "conv_2").swipeLeft()
        listCell(app, "conv_locked").swipeLeft()
        // Only the bottom bar's Delete exists: no row offers its swipe action while selecting.
        let deletes = app.buttons.matching(NSPredicate(format: "label == %@", "Delete"))
        XCTAssertFalse(app.buttons["conv_locked_swipe_delete"].waitForExistence(timeout: 2), "No swipe action while selecting")
        XCTAssertEqual(deletes.count, 1)
        XCTAssertFalse(app.staticTexts["conv_locked:delete"].exists, "A full swipe sends nothing while selecting")
        XCTAssertFalse(app.staticTexts["_selection:conv_1,conv_2"].exists)
    }

    func testSelectionLargeTextKeepsTheBottomBarReachable() {
        let app = start(["surface", "selection", "large"])
        let delete = app.buttons["bulk_delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        XCTAssertTrue(delete.isHittable)
        XCTAssertTrue(app.buttons["bulk_move"].isHittable)
        XCTAssertTrue(app.staticTexts["1 selected"].exists)
        capture(app, "native-list-selection-large-text")
        delete.tap()
        XCTAssertTrue(app.staticTexts["bulk_delete:conv_1"].waitForExistence(timeout: 5))
    }

    func testQueuedSelectionSurvivesANewerSnapshot() {
        let app = start(["surface", "selection"])
        XCTAssertTrue(app.buttons["preview-burst-list"].waitForExistence(timeout: 10))
        app.buttons["preview-burst-list"].tap()
        XCTAssertTrue(app.staticTexts["list:conv_1,conv_2|conv_1,conv_2,conv_3|"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["3 selected"].waitForExistence(timeout: 5))
    }

    func testQueuedSelectionDropsRowsNoLongerSelectable() {
        let app = start(["surface", "selection", "stale-selection"])
        XCTAssertTrue(app.buttons["preview-burst-list"].waitForExistence(timeout: 10))
        app.buttons["preview-burst-list"].tap()
        // conv_3 stopped being selectable while the second selection was queued.
        XCTAssertTrue(app.staticTexts["list:conv_1,conv_2|conv_1,conv_2|"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["native-surface-error"].exists)
    }

    func testReorderSendsTheFullPermutation() {
        let app = start(["surface", "reorder"])
        XCTAssertTrue(app.staticTexts["task_c"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons.matching(identifier: "task_a").firstMatch.exists, "Reordered rows are static")
        drag(app, "task_c", to: "task_a")
        XCTAssertTrue(app.staticTexts["_reorder:tasks:task_c,task_a,task_b"].waitForExistence(timeout: 10))
        XCTAssertLessThan(app.staticTexts["task_c"].frame.minY, app.staticTexts["task_a"].frame.minY)
        capture(app, "native-list-reorder")
    }

    func testFailedReorderRevertsToTheSnapshotOrder() {
        let app = start(["surface", "reorder", "failed-reorder"])
        XCTAssertTrue(app.staticTexts["task_c"].waitForExistence(timeout: 10))
        drag(app, "task_c", to: "task_a")
        XCTAssertTrue(app.staticTexts["native-surface-error"].waitForExistence(timeout: 10))
        let reverted = NSPredicate { _, _ in
            app.staticTexts["task_a"].frame.minY < app.staticTexts["task_c"].frame.minY
        }
        expectation(for: reverted, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        // The refused order is not a pending draft: leaving reorder mode still reaches the owner.
        app.buttons["reorder_done"].tap()
        XCTAssertTrue(app.staticTexts["reorder_done:"].waitForExistence(timeout: 5))
    }

    func testQueuedReorderSurvivesANewerSnapshot() {
        let app = start(["surface", "reorder"])
        XCTAssertTrue(app.buttons["preview-burst-list"].waitForExistence(timeout: 10))
        app.buttons["preview-burst-list"].tap()
        XCTAssertTrue(app.staticTexts["list:task_b,task_a,task_c|task_c,task_b,task_a|"].waitForExistence(timeout: 10))
        let ordered = NSPredicate { _, _ in
            app.staticTexts["task_c"].frame.minY < app.staticTexts["task_b"].frame.minY
                && app.staticTexts["task_b"].frame.minY < app.staticTexts["task_a"].frame.minY
        }
        expectation(for: ordered, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
    }

    func testCollapsibleSectionHidesRowsAndExplainsTheToggle() {
        let app = start(["surface", "collapsible"])
        // XCUITest cannot read accessibility hints; the Expand/Collapse hint needs a VoiceOver check.
        let header = app.descendants(matching: .any)["overdue_header"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["late_1"].exists)
        header.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.staticTexts["late_1"])
        waitForExpectations(timeout: 5)
        XCTAssertFalse(app.staticTexts["late_2"].exists)
        XCTAssertTrue(app.staticTexts["today_1"].exists)
        capture(app, "native-list-collapsed")
        header.tap()
        XCTAssertTrue(app.staticTexts["late_1"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["preview-last-action"].label, "Preview fixture", "Collapsing sends nothing")
    }

    func testSwipeSendsTheOptionId() {
        let app = start(["surface", "swipe"])
        let task = listCell(app, "swipe_task")
        XCTAssertTrue(task.waitForExistence(timeout: 10))
        reveal(task, leading: false)
        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        capture(app, "native-list-swipe")
        delete.tap()
        XCTAssertTrue(app.staticTexts["swipe_task:delete"].waitForExistence(timeout: 5))
        reveal(task, leading: true)
        XCTAssertTrue(app.buttons["Complete"].waitForExistence(timeout: 5))
        app.buttons["Complete"].tap()
        XCTAssertTrue(app.staticTexts["swipe_task:complete"].waitForExistence(timeout: 5))
        reveal(listCell(app, "swipe_person"), leading: false)
        XCTAssertTrue(app.buttons["Pin"].waitForExistence(timeout: 5))
        app.buttons["Rename"].tap()
        XCTAssertTrue(app.staticTexts["swipe_person:rename"].waitForExistence(timeout: 5))
    }

    func testIndentDrawsARuleWithoutChangingRowHeight() {
        let app = start(["surface", "indent"])
        let root = app.staticTexts["indent_0"]
        XCTAssertTrue(root.waitForExistence(timeout: 10))
        let child = app.staticTexts["indent_1"], grandchild = app.staticTexts["indent_2"]
        XCTAssertEqual(child.frame.minX - root.frame.minX, 20, accuracy: 1)
        XCTAssertEqual(grandchild.frame.minX - root.frame.minX, 40, accuracy: 1)
        let rootCell = listCell(app, "indent_0"), grandchildCell = listCell(app, "indent_2")
        XCTAssertEqual(rootCell.frame.height, grandchildCell.frame.height, accuracy: 0.5)
        let screenshot = app.screenshot().image
        func gutter(_ cell: XCUIElement, _ label: XCUIElement) -> CGRect {
            CGRect(x: cell.frame.minX + 4, y: label.frame.midY - 4, width: label.frame.minX - cell.frame.minX - 8, height: 8)
        }
        XCTAssertFalse(varies(screenshot, in: gutter(rootCell, root)), "An unindented row draws no rule")
        XCTAssertTrue(varies(screenshot, in: gutter(listCell(app, "indent_1"), child)), "The indent rule is visible")
        XCTAssertTrue(varies(screenshot, in: gutter(grandchildCell, grandchild)))
        capture(app, "native-list-indent")
    }

    /// The list cell that holds the element [id].
    func listCell(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.cells.containing(NSPredicate(format: "identifier == %@", id)).firstMatch
    }

    /// Drags the system reorder control of [source]'s row onto [target]'s row.
    func drag(_ app: XCUIApplication, _ source: String, to target: String) {
        let from = listCell(app, source), to = listCell(app, target)
        let handle = from.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'reorder'")).firstMatch
        let start = handle.exists ? handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            : from.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        start.press(forDuration: 0.6, thenDragTo: to.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.2)))
    }

    /// Reveals a row's swipe actions with a slow partial drag; a fast full swipe would run the first action.
    func reveal(_ cell: XCUIElement, leading: Bool) {
        let start = cell.coordinate(withNormalizedOffset: CGVector(dx: leading ? 0.1 : 0.9, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
    }

    /// Whether the brightness inside [frame] (screen points) varies, so something is drawn there.
    func varies(_ image: UIImage, in frame: CGRect) -> Bool {
        guard let cgImage = image.cgImage, frame.width > 0 else { return false }
        let scale = CGFloat(cgImage.width) / image.size.width
        let pixels = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale,
                            height: frame.height * scale).integral
        guard let crop = cgImage.cropping(to: pixels) else { return false }
        let width = crop.width, height = crop.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
        let brightness = stride(from: 0, to: data.count, by: 4).map { Int(data[$0]) + Int(data[$0 + 1]) + Int(data[$0 + 2]) }
        return (brightness.max() ?? 0) - (brightness.min() ?? 0) > 45
    }

    /// Whether any pixel inside [frame] (screen points) is a saturated red.
    func containsRed(_ image: UIImage, in frame: CGRect) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let scale = CGFloat(cgImage.width) / image.size.width
        let pixels = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale,
                            height: frame.height * scale).integral
        guard let crop = cgImage.cropping(to: pixels) else { return false }
        let width = crop.width, height = crop.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: data.count, by: 4).contains { index in
            data[index] > 170 && data[index + 1] < 110 && data[index + 2] < 110
        }
    }

    func start(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }
    func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testReadTranscriptAndNativeBack() {
        let app = start()
        let row = app.buttons["native-conversation-conversation-1"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        capture(app, "native-home-dark")
        row.tap()
        XCTAssertTrue(app.buttons["native-conversation-actions"].waitForExistence(timeout: 5))
        capture(app, "native-summary")
        app.segmentedControls.buttons["Transcript"].tap()
        XCTAssertTrue(app.staticTexts["Let us start with native conversation browsing."].waitForExistence(timeout: 5))
        capture(app, "native-transcript")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }
    func testLockedRowRoutesToExistingAction() {
        let app = start()
        app.buttons["native-conversation-locked-1"].tap()
        XCTAssertTrue(app.staticTexts["open:locked-1"].waitForExistence(timeout: 5))
    }
    func testFailedReadCanRetry() {
        let app = start(["error"])
        XCTAssertTrue(app.buttons["native-retry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No conversations yet"].exists)
        app.buttons["native-retry"].tap()
        XCTAssertTrue(app.buttons["native-conversation-conversation-1"].waitForExistence(timeout: 5))
    }
    func testEmptyReadIsNotError() {
        let app = start(["empty"])
        XCTAssertTrue(app.staticTexts["No conversations yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["native-retry"].exists)
        capture(app, "native-empty")
    }
    func testSessionInvalidationHidesNativeTranscript() {
        let app = start()
        app.buttons["native-conversation-conversation-1"].tap()
        app.segmentedControls.buttons["Transcript"].tap()
        XCTAssertTrue(app.staticTexts["Let us start with native conversation browsing."].waitForExistence(timeout: 5))
        app.buttons["preview-end-session"].tap()
        XCTAssertFalse(app.staticTexts["Let us start with native conversation browsing."].exists)
        XCTAssertFalse(app.staticTexts["Design catch-up"].exists)
    }
    func testLargeTextLightAppearance() {
        let app = start(["large", "light"])
        XCTAssertTrue(app.buttons["native-conversation-conversation-1"].waitForExistence(timeout: 5))
        capture(app, "native-home-large-text-light")
        app.buttons["native-conversation-conversation-1"].tap()
        XCTAssertTrue(app.buttons["native-conversation-actions"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Transcript"].tap()
        XCTAssertTrue(app.staticTexts["Let us start with native conversation browsing."].waitForExistence(timeout: 5))
        capture(app, "native-transcript-large-text")
    }
    func testCompleteHomeChromeScrollAndActions() {
        let app = start(["chrome"])
        XCTAssertTrue(app.buttons["native-settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["native-device"].label.contains("53%"))
        XCTAssertTrue(app.buttons["native-recap-recap-1"].isHittable)
        let chat = app.buttons["native-chat"]
        // The system glass footer can finish its initial layout after the header is ready.
        // Wait for the actual tap target, then assert the dispatched owner action too.
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: chat)
        XCTAssertEqual(XCTWaiter.wait(for: [hittable], timeout: 10), .completed)
        chat.tap()
        XCTAssertTrue(app.staticTexts["chat:"].waitForExistence(timeout: 5))
        capture(app, "native-home-liquid-glass")
        app.buttons["native-tasks"].tap()
        capture(app, "native-home-after-tasks-action")
        XCTAssertTrue(app.staticTexts["tasks:"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.buttons["native-conversation-conversation-1"].isHittable)
    }
    func testHomeChromeLargeTextKeepsControlsReachable() {
        let app = start(["chrome", "large", "light"])
        XCTAssertTrue(app.buttons["native-chat"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["native-chat"].isHittable)
        XCTAssertLessThan(app.buttons["native-chat"].frame.height, 100)
        XCTAssertLessThan(app.buttons["native-tasks"].frame.height, 100)
        capture(app, "native-home-liquid-glass-large-text")
        app.swipeUp()
        XCTAssertTrue(app.buttons["native-recap-recap-1"].exists)
    }
    func testNativeTextKeepsLastRapidEdit() {
        let app = start(["surface"])
        let field = app.textFields["draft"].exists ? app.textFields["draft"] : app.textViews["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("rapid final edit")
        XCTAssertTrue(app.staticTexts["draft:rapid final edit"].waitForExistence(timeout: 10))
        capture(app, "native-settings-edit")
    }

    func testSettingsNavigationTagsAndSafeHeader() {
        let app = start(["settings-menu"])
        let close = app.buttons["settings_close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertTrue(close.isHittable)
        if app.statusBars.firstMatch.exists {
            XCTAssertGreaterThanOrEqual(close.frame.minY, app.statusBars.firstMatch.frame.maxY)
        }
        XCTAssertTrue(app.buttons["account"].isHittable)
        XCTAssertTrue(app.staticTexts["NEW"].exists)
        XCTAssertTrue(app.staticTexts["BETA"].exists)
        capture(app, "native-settings-menu-dark")
        app.buttons["account"].tap()
        XCTAssertTrue(app.staticTexts["account:"].waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.staticTexts["settings_close:"].waitForExistence(timeout: 5))
    }

    func testSaveWaitsForLastQueuedEdit() {
        let app = start(["surface"])
        let field = app.textFields["draft"].exists ? app.textFields["draft"] : app.textViews["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("do not save old text")
        app.buttons["save"].tap()
        XCTAssertTrue(app.staticTexts["preview-last-saved"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["preview-last-saved"].label, "saved:do not save old text")
    }
    func testNativeChatSendPreservesFinalDraftAndClearsIt() {
        let app = start(["chat"])
        let field = app.textFields["chat_draft"].exists ? app.textFields["chat_draft"] : app.textViews["chat_draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("native final draft")
        app.buttons["chat_send"].tap()
        XCTAssertTrue(app.staticTexts["preview-last-saved"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["preview-last-saved"].label, "saved:native final draft")
        XCTAssertEqual(field.value as? String, "Ask Omi")
        capture(app, "native-chat-liquid-glass")
    }

    func testNativeSwitchCallsOriginalMutation() {
        let app = start(["surface"])
        XCTAssertTrue(app.switches["enabled"].waitForExistence(timeout: 10))
        app.switches["enabled"].switches.firstMatch.tap()
        let updated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '0'"), object: app.switches["enabled"])
        XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 5), .completed)
    }
    func testNativePickerKeepsChoice() {
        let app = start(["surface"])
        app.buttons["mode"].tap()
        app.buttons["Dark"].tap()
        XCTAssertTrue(app.staticTexts["mode:dark"].waitForExistence(timeout: 5))
    }
    func testFailedEditCannotSaveStaleContent() {
        let app = start(["surface", "failed-edit"])
        let field = app.textFields["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        // The first rejected edit removes focus. Do not type into an invalidated field.
        field.typeText("x")
        app.buttons["save"].tap()
        XCTAssertTrue(app.staticTexts["native-surface-error"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["saved:"].exists)
    }
    func testNativeSurfaceSessionInvalidationRemovesDraft() {
        let app = start(["surface"])
        let field = app.textFields["draft"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("private text")
        app.buttons["preview-end-session"].tap()
        XCTAssertFalse(field.exists)
        XCTAssertFalse(app.staticTexts["Appearance"].exists)
    }

    func testNativeAttachmentMenuForwardsSelectedPayload() {
        // Keep the fixture receipt away from the system menu/composer hit targets.
        let app = start(["chat", "attachments", "chrome"])
        XCTAssertTrue(app.buttons["chat_attach"].waitForExistence(timeout: 10))
        app.buttons["chat_attach"].tap()
        app.buttons["Choose File"].tap()
        XCTAssertTrue(app.staticTexts["chat_attach:file"].waitForExistence(timeout: 5))
        capture(app, "native-chat-attachment-menu")
    }
    func testNativeVoiceWaveformKeepsControlsReachableAtLargeText() {
        let app = start(["chat", "voice", "large"])
        XCTAssertTrue(app.buttons["chat_voice_stop"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["chat_voice_stop"].isHittable)
        XCTAssertTrue(app.buttons["chat_voice_discard"].isHittable)
        capture(app, "native-chat-voice-large-text")
        app.buttons["chat_voice_stop"].tap()
        XCTAssertTrue(app.staticTexts["chat_voice_stop:"].waitForExistence(timeout: 5))
        app.buttons["preview-end-session"].tap()
        XCTAssertFalse(app.buttons["chat_voice_stop"].exists)
    }

}
