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
    func testGraphFillTapsSelectNodesWhileCameraGesturesSendNothing() {
        let app = start(["surface", "graph-fill"])
        let graph = app.otherElements["graph_canvas"]
        XCTAssertTrue(graph.waitForExistence(timeout: 30))
        let receipt = app.staticTexts["preview-last-action"]
        // The fixed user node sits at the origin, the centre of the stage.
        graph.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["graph_canvas:'me'"].waitForExistence(timeout: 15))
        let ada = app.buttons["graph_canvas_node_ada"]
        XCTAssertTrue(ada.waitForExistence(timeout: 10))
        ada.tap()
        XCTAssertTrue(app.staticTexts["graph_canvas:'ada'"].waitForExistence(timeout: 15))
        wait(until: ada.isSelected, "The owner's selection reaches the node element")
        capture(app, "native-graph-fill-selected")
        graph.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).withOffset(CGVector(dx: -170, dy: 0)).tap()
        XCTAssertTrue(app.staticTexts["graph_canvas:''"].waitForExistence(timeout: 15))
        wait(until: !ada.isSelected, "A background tap clears the selection")

        let zoomElement = app.descendants(matching: .any)["graph_canvas_zoom"]
        let zoom = zoomElement.value as? String
        let position = ada.frame
        graph.pinch(withScale: 1.8, velocity: 1)
        graph.swipeLeft()
        graph.rotate(0.5, withVelocity: 1)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(receipt.label, "graph_canvas:''", "Pinch, rotation and pan stay native")
        XCTAssertNotEqual(zoomElement.value as? String, zoom)
        XCTAssertNotEqual(ada.frame, position)
        capture(app, "native-graph-fill-camera")
    }

    func testGraphFillKeepsLabelsAboveAndButtonsBelowAtLargeText() {
        let app = start(["surface", "graph-fill", "large"])
        let graph = app.otherElements["graph_canvas"]
        XCTAssertTrue(graph.waitForExistence(timeout: 30))
        let hint = app.staticTexts["graph_hint"]
        let proceed = app.buttons["graph_continue"]
        XCTAssertTrue(hint.exists)
        XCTAssertLessThanOrEqual(hint.frame.maxY, graph.frame.minY + 1)
        XCTAssertGreaterThanOrEqual(proceed.frame.minY, graph.frame.maxY - 1)
        XCTAssertGreaterThan(graph.frame.height, 100)
        XCTAssertTrue(proceed.isHittable)
        XCTAssertTrue(app.buttons["graph_back"].isHittable)
        capture(app, "native-graph-fill-large-text")
        proceed.tap()
        XCTAssertTrue(app.staticTexts["graph_continue:"].waitForExistence(timeout: 15))
    }

    func testGraphFillListsNodesForVoiceOverWithAdjustableZoom() {
        let app = start(["surface", "graph-fill"])
        let graph = app.otherElements["graph_canvas"]
        XCTAssertTrue(graph.waitForExistence(timeout: 30))
        XCTAssertEqual(graph.label, "Memory Graph")
        for (id, label) in [("me", "You"), ("ada", "Ada"), ("paris", "Paris"), ("omi", "Omi"), ("pendant", "Pendant"),
                            ("memory", "Memory")] {
            let node = app.buttons["graph_canvas_node_\(id)"]
            XCTAssertTrue(node.exists, id)
            XCTAssertEqual(node.label, label)
            XCTAssertFalse(node.isSelected)
            XCTAssertTrue(graph.frame.contains(CGPoint(x: node.frame.midX, y: node.frame.midY)), id)
        }
        let zoom = app.descendants(matching: .any)["graph_canvas_zoom"]
        XCTAssertTrue(zoom.exists)
        XCTAssertEqual(zoom.label, "Memory Graph")
        XCTAssertEqual(zoom.value as? String, "100%")
        XCTAssertTrue(adjustable(zoom), "VoiceOver can adjust the graph's zoom")
    }

    func testGraphCardTapSendsNilAndTheListStillScrolls() {
        let app = start(["surface", "graph-card"])
        let card = app.buttons["graph_card"]
        XCTAssertTrue(card.waitForExistence(timeout: 30))
        XCTAssertEqual(card.label, "Memory Graph")
        XCTAssertGreaterThanOrEqual(card.frame.height, 139)
        capture(app, "native-graph-card")
        let top = card.frame.minY
        card.swipeUp()
        wait(until: !card.exists || card.frame.minY < top - 40, "A drag that starts on the card scrolls the list")
        XCTAssertEqual(app.staticTexts["preview-last-action"].label, "Preview fixture")
        app.swipeDown()
        app.swipeDown()
        wait(until: card.isHittable, "The card returns")
        card.tap()
        XCTAssertTrue(app.staticTexts["graph_card:nil"].waitForExistence(timeout: 15))
    }

    func testGraphPlaceholderPulsesThenRests() {
        let app = start(["surface", "graph-placeholder"])
        let graph = app.otherElements["graph_canvas"]
        XCTAssertTrue(graph.waitForExistence(timeout: 30))
        XCTAssertTrue(app.descendants(matching: .any)["native-surface-loading"].waitForExistence(timeout: 10))
        let skeleton = skeletonRegion(graph.frame)
        var pulsed = false
        for _ in 0..<4 where !pulsed {
            let first = app.screenshot().image
            Thread.sleep(forTimeInterval: 0.5)
            pulsed = changedPixels(first, app.screenshot().image, in: skeleton) > 0
        }
        XCTAssertTrue(pulsed, "The skeleton pulses while loading")
        capture(app, "native-graph-placeholder")
        // Six pulses of 2 x 0.6 s (7.2 s), then it rests.
        Thread.sleep(forTimeInterval: 8)
        let rested = app.screenshot().image
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertEqual(changedPixels(rested, app.screenshot().image, in: skeleton), 0)
    }

    func testGraphPlaceholderIsStaticUnderReduceMotion() {
        let app = start(["surface", "graph-placeholder", "reduce-motion"])
        let graph = app.otherElements["graph_canvas"]
        XCTAssertTrue(graph.waitForExistence(timeout: 30))
        let skeleton = skeletonRegion(graph.frame)
        for _ in 0..<3 {
            let first = app.screenshot().image
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertEqual(changedPixels(first, app.screenshot().image, in: skeleton), 0)
        }
    }

    /// The skeleton's left fifth, clear of the centred loading status.
    func skeletonRegion(_ frame: CGRect) -> CGRect {
        CGRect(x: frame.minX, y: frame.minY + frame.height * 0.2, width: frame.width * 0.22, height: frame.height * 0.6)
    }

    /// Pixels in [frame] (screen points) whose colour moved by more than a rounding step.
    func changedPixels(_ first: UIImage, _ second: UIImage, in frame: CGRect) -> Int {
        func pixels(_ image: UIImage) -> [UInt8] {
            guard let cgImage = image.cgImage else { return [] }
            let scale = CGFloat(cgImage.width) / image.size.width
            let crop = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale,
                              height: frame.height * scale).integral
            guard let region = cgImage.cropping(to: crop) else { return [] }
            var data = [UInt8](repeating: 0, count: region.width * region.height * 4)
            guard let context = CGContext(data: &data, width: region.width, height: region.height, bitsPerComponent: 8,
                                          bytesPerRow: region.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return [] }
            context.draw(region, in: CGRect(x: 0, y: 0, width: region.width, height: region.height))
            return data
        }
        let a = pixels(first), b = pixels(second)
        guard !a.isEmpty, a.count == b.count else { return -1 }
        return stride(from: 0, to: a.count, by: 4).filter { index in
            (0..<3).contains { abs(Int(a[index + $0]) - Int(b[index + $0])) > 4 }
        }.count
    }

    /// Whether the element carries UIAccessibilityTraitAdjustable, as VoiceOver's swipe up/down needs.
    func adjustable(_ element: XCUIElement) -> Bool {
        element.elementType == .slider || element.debugDescription.contains("Adjustable")
    }

    func wait(until condition: @escaping @autoclosure () -> Bool, _ message: String, timeout: TimeInterval = 15) {
        let predicate = NSPredicate { _, _ in condition() }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: timeout),
                       .completed, message)
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

/// Runs inside the test bundle, which compiles NativeGraphView.swift with the contract, so the
/// row-scoped ImageRenderer capture is checked without launching the fixture.
final class NativeGraphCaptureTests: XCTestCase {
    private func graph(placeholder: Bool = false) throws -> NativeSurfaceRow.Graph {
        // A hub and 39 spokes, all within the middle of a 390 x 600 frame.
        let nodes: [[String: Any]] = (0..<40).map { index in
            let user = index == 0
            return ["id": "n\(index)", "label": "Node \(index)", "type": user ? "user" : "concept",
                    "x": user ? 0.0 : Double(index * 37 % 200 - 100), "y": user ? 0.0 : Double(index * 53 % 300 - 150),
                    "z": user ? 0.0 : Double(index * 71 % 400 - 200), "fixed": user]
        }
        let edges: [[String: Any]] = (1..<40).map { ["source": "n0", "target": "n\($0)", "label": $0 % 3 == 0 ? "knows" : ""] }
        var row: [String: Any] = ["id": "graph", "title": "Memory Graph", "kind": "graph", "subtitle": "", "options": [],
            "destructive": false, "enabled": true,
            "graph": ["nodes": placeholder ? [] : nodes, "edges": placeholder ? [] : edges,
                      "highlighted": placeholder ? [] : ["n0", "n3"], "zoom": 1.0, "interactive": !placeholder,
                      "layout": "fill", "placeholder": placeholder, "accent": "#1A2B3C"]]
        if !placeholder { row["value"] = "n0" }
        let snapshot = try NativeSurfaceSnapshot.decode(["version": 1, "revision": 0, "title": "Memory Graph",
            "appearance": "dark", "locale": "en", "direction": "ltr", "loading": false, "failed": false, "empty": "",
            "sections": [["id": "graph", "title": "", "footer": "", "rows": [row]]], "toolbar": [],
            "searchEnabled": false, "searchValue": "", "searchPlaceholder": "", "refreshEnabled": false,
            "error": "Error", "retry": "Retry", "loadingLabel": "Loading"])
        return try XCTUnwrap(snapshot.fillGraphRow?.graph)
    }

    @MainActor
    func testRowCaptureIsPNGWithinSixteenMegapixelsAndSixteenMegabytes() throws {
        let graph = try graph()
        let camera = NativeGraphCamera(zoom: graph.zoom)
        let phone = try XCTUnwrap(NativeGraphCapture.png(graph, camera: camera, size: CGSize(width: 390, height: 600),
                                                         colorScheme: .dark))
        XCTAssertEqual(Array(phone.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let image = try XCTUnwrap(UIImage(data: phone)?.cgImage)
        XCTAssertEqual(image.width, 1170, "A phone-sized graph renders at 3x")
        XCTAssertEqual(image.height, 1800)
        XCTAssertGreaterThan(alpha(image, x: image.width / 2, y: image.height / 2), 0, "The user node is drawn at the centre")
        XCTAssertEqual(alpha(image, x: 2, y: 2), 0, "Like the Flutter capture, the background stays transparent")

        for size in [CGSize(width: 4000, height: 9000), CGSize(width: 3333.3, height: 4800.7)] {
            let data = try XCTUnwrap(NativeGraphCapture.png(graph, camera: camera, size: size, colorScheme: .light))
            XCTAssertLessThanOrEqual(data.count, 16 * 1024 * 1024)
            let large = try XCTUnwrap(UIImage(data: data)?.cgImage)
            XCTAssertLessThanOrEqual(large.width * large.height, 16_000_000, "\(size)")
            XCTAssertGreaterThan(large.width * large.height, 15_000_000, "\(size) is scaled down, not dropped")
        }
        XCTAssertNil(NativeGraphCapture.png(try self.graph(placeholder: true), camera: camera,
                                            size: CGSize(width: 390, height: 600), colorScheme: .dark))
        for size in [CGSize.zero, CGSize(width: 390, height: 0), CGSize(width: CGFloat.infinity, height: 10),
                     CGSize(width: CGFloat.nan, height: 10)] {
            XCTAssertNil(NativeGraphCapture.png(graph, camera: camera, size: size, colorScheme: .dark), "\(size)")
        }
    }

    private func alpha(_ image: CGImage, x: Int, y: Int) -> UInt8 {
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
        context.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
        return pixel[3]
    }
}
