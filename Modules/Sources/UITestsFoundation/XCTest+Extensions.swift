import XCTest

public let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

extension XCUIElement {
    /**
     Removes any current text in the field
     */
    func clearTextIfNeeded() -> Void {
        let app = XCUIApplication()

        self.press(forDuration: 1.2)
        app.keys["delete"].tap()
    }

    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        clearTextIfNeeded()
        enterText(text: text)
    }

    func enterText(text: String) -> Void {
        self.tap()

        if self.buttons["AutoFill"].exists {
            self.buttons["AutoFill"].tap()
        }

        self.typeText(text)
    }
}

extension XCTestCase {

    public func takeScreenshotOfFailedTest() {
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            XCTContext.runActivity(named: "Take a screenshot at the end of a failed test") { _ in
                add(XCTAttachment(screenshot: XCUIApplication().windows.firstMatch.screenshot()))
            }
        }
    }

    public func systemAlertHandler(alertTitle: String, alertButton: String) {
        addUIInterruptionMonitor(withDescription: alertTitle) { alert -> Bool in
            let alertButtonElement = alert.buttons[alertButton]
            XCTAssert(alertButtonElement.waitForExistence(timeout: 5))
            alertButtonElement.tap()
            return true
        }
    }

    public func getRandomPhrase() -> String {
        var wordArray: [String] = []
        let phraseLength = Int.random(in: 3...6)
        for _ in 1...phraseLength {
            wordArray.append(DataHelper.words.randomElement()!)
        }
        let phrase = wordArray.joined(separator: " ")

        return phrase
    }

    public func getRandomContent() -> String {
        var sentenceArray: [String] = []
        let paraLength = Int.random(in: 1...DataHelper.sentences.count)
        for _ in 1...paraLength {
            sentenceArray.append(DataHelper.sentences.randomElement()!)
        }
        let paragraph = sentenceArray.joined(separator: " ")

        return paragraph
    }

    public func getCategory() -> String {
        return "Wedding"
    }

    public func getTag() -> String {
        return "tag"
    }

    public struct DataHelper {
        static let words = ["Lorem", "Ipsum", "Dolor", "Sit", "Amet", "Consectetur", "Adipiscing", "Elit"]
        static let sentences = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec.",
            "Nam congue efficitur leo eget porta.",
            "Proin dictum non ligula aliquam varius.",
            "Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
        ]
        static let category = "iOS Test"
        static let tag = "tag"
    }

    public func elementIsFullyVisibleOnScreen(element: XCUIElement) -> Bool {
        guard element.exists && !element.frame.isEmpty && element.isHittable else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(element.frame)
    }
}

extension XCUIElement {

    public func waitForElementToNotExist(element: XCUIElement, timeout: TimeInterval? = nil) {
        let notExistsPredicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate,
                                                    object: element)

        let timeoutValue = timeout ?? 30
        guard XCTWaiter().wait(for: [expectation], timeout: timeoutValue) == .completed else {
            XCTFail("\(element) still exists after \(timeoutValue) seconds.")
            return
        }
    }

    public func scroll(byDeltaX deltaX: CGFloat, deltaY: CGFloat) {

        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector.zero)
        let destination = startCoordinate.withOffset(CGVector(dx: deltaX, dy: deltaY * -1))

        startCoordinate.press(forDuration: 0.01, thenDragTo: destination)
    }

    func getStaticTextVisibilityCount(textToFind: String) throws -> Int {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", textToFind)
        return staticTexts.containing(predicate).count
    }

    public func assertTextVisibilityCount(textToFind: String, expectedCount: Int) {
        XCTAssertEqual(try! getStaticTextVisibilityCount(textToFind: textToFind), expectedCount)
    }

    /// Looks for a `staticText` child of the cell with the given accessibility identifier, whose label satisfies `labelPredicate`.
    /// Note: the lookup always starts from the application, not from the receiver.
    func verifyStaticTextOnCell(cellIdentifier: String, labelPredicate: NSPredicate) -> Bool {
        let cellPredicate = NSPredicate(format: "identifier == %@", cellIdentifier)

        return XCUIApplication().tables.cells.matching(cellPredicate)
            .children(matching: .staticText)
            .element(matching: labelPredicate)
            .firstMatch
            .exists
    }

    /// Asserts that a cell identified by `cellIdentifier` has a `staticText` child whose label is exactly `label`.
    public func assertStaticText(withLabel label: String, existsOnCellWithIdentifier cellIdentifier: String) {
        let labelPredicate = NSPredicate(format: "label ==[c] %@", label)

        XCTAssertTrue(verifyStaticTextOnCell(cellIdentifier: cellIdentifier, labelPredicate: labelPredicate),
                      "No static text labeled '\(label)' found on cell '\(cellIdentifier)'!")
    }

    /// Asserts that a cell identified by `cellIdentifier` has a `staticText` child whose label contains `substring`.
    /// Use this when the label is a composed detail line (e.g. "On back order • $150.00") and only one part of it is under test.
    public func assertStaticText(containing substring: String, existsOnCellWithIdentifier cellIdentifier: String) {
        let labelPredicate = NSPredicate(format: "label CONTAINS[c] %@", substring)

        XCTAssertTrue(verifyStaticTextOnCell(cellIdentifier: cellIdentifier, labelPredicate: labelPredicate),
                      "No static text containing '\(substring)' found on cell '\(cellIdentifier)'!")
    }

    func verifyLabelContains(substring firstSubstring: String, and secondSubstring: String) throws -> Bool {
        let firstPredicate = NSPredicate(format: "label CONTAINS[c] %@", firstSubstring)
        let secondPredicate = NSPredicate(format: "label CONTAINS[c] %@", secondSubstring)
        let predicateCompound = NSCompoundPredicate(type: .and, subpredicates: [firstPredicate, secondPredicate])

        return XCUIApplication().staticTexts.containing(predicateCompound).count == 1
    }

    public func assertLabelContains(firstSubstring: String, secondSubstring: String) {
        XCTAssertTrue(try verifyLabelContains(substring: firstSubstring, and: secondSubstring),
        """
        '\(firstSubstring)' and '\(secondSubstring)' does not appear on label!
        """)
    }

    /**
     Waits the specified amount of time for the element's isHittable property to be true, and then taps it.
     - Parameter timeout: timeout value, if not specified defaults to 10
     */
    public func waitAndTap(timeout: Double = 10) {
        self.waitForIsHittable(timeout: timeout)
        self.tap()
    }

    public func scrollIntoView(app: XCUIApplication = XCUIApplication()) {
        var iteration = 0
        let maxIteration = 10

        while isFullyVisibleOnScreen() == false && iteration < maxIteration {
            app.swipeUp()
            iteration += 1
        }

        if isFullyVisibleOnScreen() == false {
            XCTFail("Unable to scroll element into view")
        }
    }
}

extension XCUIApplication {
    @discardableResult
    public func dismissSavePasswordPromptIfNeeded(timeout: TimeInterval = 15,
                                                until element: XCUIElement? = nil,
                                                stableFor: TimeInterval = 0.5,
                                                elementDescription: String = "expected element") -> Bool {
        var didDismissPromptAndReachTarget = false
        XCTContext.runActivity(named: "Dismiss Save Password prompt if needed") { _ in
            didDismissPromptAndReachTarget = dismissSavePasswordPromptIfNeededWithoutActivity(
                timeout: timeout,
                until: element,
                stableFor: stableFor,
                elementDescription: elementDescription
            )
        }
        return didDismissPromptAndReachTarget
    }

    private func dismissSavePasswordPromptIfNeededWithoutActivity(timeout: TimeInterval,
                                                                 until element: XCUIElement?,
                                                                 stableFor: TimeInterval,
                                                                 elementDescription: String) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(timeout)
        var elementVisibleWithoutPromptSince: Date?
        var promptAbsentSince: Date?

        while Date() < deadline {
            let promptVisible = isSavePasswordPromptVisible(in: self) || isSavePasswordPromptVisible(in: springboard)
            if tapSavePasswordDismissButtonIfNeeded(in: self) || tapSavePasswordDismissButtonIfNeeded(in: springboard) {
                elementVisibleWithoutPromptSince = nil
                promptAbsentSince = nil
                continue
            }

            guard let element else {
                if !promptVisible {
                    if promptAbsentSince == nil {
                        promptAbsentSince = Date()
                    }
                    if let absentSince = promptAbsentSince,
                       Date().timeIntervalSince(absentSince) >= stableFor {
                        return true
                    }
                } else {
                    promptAbsentSince = nil
                }

                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
                continue
            }

            if element.exists, element.isHittable, !promptVisible {
                if elementVisibleWithoutPromptSince == nil {
                    elementVisibleWithoutPromptSince = Date()
                }
                if let visibleSince = elementVisibleWithoutPromptSince,
                   Date().timeIntervalSince(visibleSince) >= stableFor {
                    return true
                }
            } else {
                elementVisibleWithoutPromptSince = nil
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        }

        let promptVisible = isSavePasswordPromptVisible(in: self) || isSavePasswordPromptVisible(in: springboard)
        if !promptVisible {
            guard let element else {
                return true
            }

            if element.exists, element.isHittable {
                return true
            }
        }

        XCTFail(
            "Timed out after \(timeout) seconds waiting for the Save Password prompt to clear" +
            (element == nil ? "." : " and \(elementDescription) to become hittable.") +
            " " +
            savePasswordPromptState(app: self, springboard: springboard, element: element, elementDescription: elementDescription)
        )
        return false
    }

    private func tapSavePasswordDismissButtonIfNeeded(in app: XCUIApplication) -> Bool {
        guard isSavePasswordPromptVisible(in: app) else { return false }

        let dismissButton = app.buttons["Not Now"]
        guard dismissButton.waitForExistence(timeout: 0.5) else { return false }

        if dismissButton.isHittable {
            dismissButton.tap()
        } else if !dismissButton.frame.isEmpty {
            dismissButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            return false
        }
        return true
    }

    private func isSavePasswordPromptVisible(in app: XCUIApplication) -> Bool {
        app.staticTexts["Save Password?"].exists ||
            (app.buttons["Not Now"].exists && app.buttons["Save"].exists)
    }

    private func savePasswordPromptState(app: XCUIApplication,
                                         springboard: XCUIApplication,
                                         element: XCUIElement?,
                                         elementDescription: String) -> String {
        let appDismissButton = app.buttons["Not Now"]
        let springboardDismissButton = springboard.buttons["Not Now"]
        let elementState = element.map {
            "\(elementDescription): exists=\($0.exists), hittable=\($0.isHittable)"
        } ?? "No target element provided"

        return [
            "appPromptVisible=\(isSavePasswordPromptVisible(in: app))",
            "springboardPromptVisible=\(isSavePasswordPromptVisible(in: springboard))",
            "appNotNow: exists=\(appDismissButton.exists), hittable=\(appDismissButton.isHittable)",
            "springboardNotNow: exists=\(springboardDismissButton.exists), hittable=\(springboardDismissButton.isHittable)",
            elementState
        ].joined(separator: "; ")
    }
}
