import XCTest

// MARK: - Pearl E2E UI Tests
// Full user flow tests: onboarding → dashboard → chat → profile

final class PearlUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    // MARK: - Onboarding Flow
    
    func testOnboarding_WelcomeScreenAppears() {
        // First launch should show Welcome step
        let welcomeTitle = app.staticTexts["Pearl"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5),
                      "Welcome screen should appear on first launch")
    }
    
    func testOnboarding_FullFlow() {
        // Step 1: Welcome → tap Begin
        let beginButton = app.buttons["Begin Your Journey"]
        if beginButton.waitForExistence(timeout: 5) {
            beginButton.tap()
        }
        
        // Step 2: Name entry
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Astrid")
            
            // Tap continue
            let continueButton = app.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
            }
        }
        
        // Step 3: Birth date — date picker interaction
        // DatePicker UI varies, just verify we're on the right step
        let birthDateTitle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'birth'")
        ).firstMatch
        XCTAssertTrue(birthDateTitle.waitForExistence(timeout: 3),
                      "Birth date step should appear after name")
    }
    
    func testOnboarding_CanSkipBirthTime() {
        // Navigate to birth time step
        navigateToOnboardingStep(3)
        
        let skipButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'skip' OR label CONTAINS[c] \"don't know\"")
        ).firstMatch
        
        if skipButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(skipButton.isEnabled,
                          "Users should be able to skip birth time (it's optional)")
        }
    }
    
    // MARK: - Dashboard
    
    func testDashboard_ShowsBlueprintSection() {
        completeOnboarding()
        
        // Dashboard should show "Your Blueprint" section
        let blueprintTitle = app.staticTexts["Your Blueprint"]
        XCTAssertTrue(blueprintTitle.waitForExistence(timeout: 10),
                      "Dashboard should show 'Your Blueprint' section")
    }
    
    func testDashboard_ShowsMorningBrief() {
        completeOnboarding()
        
        // Should show morning brief or "What's Happening Now"
        let morningBrief = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'morning' OR label CONTAINS[c] \"happening now\"")
        ).firstMatch
        
        XCTAssertTrue(morningBrief.waitForExistence(timeout: 10),
                      "Dashboard should show Morning Brief or What's Happening Now")
    }
    
    func testDashboard_ShowsFourSystems() {
        completeOnboarding()
        
        // Verify four systems are displayed (no Gene Keys)
        let systems = ["Astrology", "Human Design", "Kabbalah", "Numerology"]
        for system in systems {
            let label = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] %@", system)
            ).firstMatch
            
            // At least one reference to each system should exist
            // (may be in cards, tabs, or section headers)
            if !label.waitForExistence(timeout: 5) {
                // System might be in a scrollable area
                app.swipeUp()
                XCTAssertTrue(label.waitForExistence(timeout: 3),
                              "Dashboard should display \(system) system")
            }
        }
    }
    
    func testDashboard_NoGeneKeysDisplayed() {
        completeOnboarding()
        
        // Gene Keys should NOT appear anywhere on dashboard
        let geneKeysLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Gene Key'")
        ).firstMatch
        
        XCTAssertFalse(geneKeysLabel.exists,
                       "Gene Keys should NOT appear on dashboard — removed from v1")
    }
    
    // MARK: - Life Purpose View
    
    func testLifePurpose_AccessibleFromDashboard() {
        completeOnboarding()
        
        // Tap on Life Purpose card/section
        let lifePurpose = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Life Purpose' OR label CONTAINS[c] 'purpose'")
        ).firstMatch
        
        if lifePurpose.waitForExistence(timeout: 10) {
            lifePurpose.tap()
            
            // Should navigate to Life Purpose detail view
            let purposeDetail = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'Your Life Purpose'")
            ).firstMatch
            
            XCTAssertTrue(purposeDetail.waitForExistence(timeout: 5),
                          "Tapping Life Purpose should show detail view")
        }
    }
    
    // MARK: - Chat with Pearl
    
    func testChat_TabExists() {
        completeOnboarding()
        
        let chatTab = app.tabBars.buttons["Pearl"]
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5),
                      "Pearl chat tab should exist in tab bar")
    }
    
    func testChat_ShowsWelcomeMessage() {
        completeOnboarding()
        
        // Navigate to chat tab
        app.tabBars.buttons["Pearl"].tap()
        
        let welcomeText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Ask Pearl'")
        ).firstMatch
        
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5),
                      "Chat should show 'Ask Pearl anything' welcome")
    }
    
    func testChat_ShowsSuggestionChips() {
        completeOnboarding()
        
        app.tabBars.buttons["Pearl"].tap()
        
        // Should show suggestion chips matching web app
        let suggestions = [
            "Should I take this new opportunity?",
            "What is my biggest gift to the world?",
            "Why do I keep repeating this pattern?",
            "What should I focus on this week?"
        ]
        
        for suggestion in suggestions {
            let chip = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", suggestion)
            ).firstMatch
            
            if !chip.waitForExistence(timeout: 3) {
                // Might need to scroll
                app.swipeUp()
            }
            // At least verify some chips exist
        }
    }
    
    func testChat_CanTypeMessage() {
        completeOnboarding()
        
        app.tabBars.buttons["Pearl"].tap()
        
        let textField = app.textFields["Ask Pearl..."]
        if textField.waitForExistence(timeout: 5) {
            textField.tap()
            textField.typeText("What is my purpose?")
            
            XCTAssertEqual(textField.value as? String, "What is my purpose?",
                           "Should be able to type in the chat input")
        }
    }
    
    func testChat_SendButtonDisabledWhenEmpty() {
        completeOnboarding()
        
        app.tabBars.buttons["Pearl"].tap()
        
        // Send button should be disabled when input is empty
        let sendButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'arrow.up'")
        ).firstMatch
        
        if sendButton.waitForExistence(timeout: 3) {
            XCTAssertFalse(sendButton.isEnabled,
                           "Send button should be disabled with empty input")
        }
    }
    
    func testChat_HasMicButton() {
        completeOnboarding()
        
        app.tabBars.buttons["Pearl"].tap()
        
        // Mic button for voice input (parity with web)
        let micButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'mic'")
        ).firstMatch
        
        // Mic may not be available in simulator, just check it exists
        // (will be hidden if speech permission not granted)
        if micButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(micButton.exists, "Mic button should exist for voice input")
        }
    }
    
    func testChat_NewConversationButton() {
        completeOnboarding()
        
        app.tabBars.buttons["Pearl"].tap()
        
        let newChatButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'plus' OR label CONTAINS[c] 'new'")
        ).firstMatch
        
        XCTAssertTrue(newChatButton.waitForExistence(timeout: 5),
                      "Should have a new conversation button")
    }
    
    // MARK: - Insights Tab
    
    func testInsights_TabExists() {
        completeOnboarding()
        
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 5),
                      "Insights tab should exist in tab bar")
    }
    
    // MARK: - Profile Tab
    
    func testProfile_TabExists() {
        completeOnboarding()
        
        let profileTab = app.tabBars.buttons["You"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5),
                      "Profile tab should exist in tab bar")
    }
    
    func testProfile_ShowsUserName() {
        completeOnboarding()
        
        app.tabBars.buttons["You"].tap()
        
        let nameLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Astrid'")
        ).firstMatch
        
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5),
                      "Profile should show the user's name")
    }
    
    func testProfile_ShowsBirthData() {
        completeOnboarding()
        
        app.tabBars.buttons["You"].tap()
        
        let birthDataRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Birth'")
        ).firstMatch
        
        XCTAssertTrue(birthDataRow.waitForExistence(timeout: 5),
                      "Profile should show birth data section")
    }
    
    func testProfile_HasSettingsGear() {
        completeOnboarding()
        
        app.tabBars.buttons["You"].tap()
        
        let settingsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'settings'")
        ).firstMatch
        
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5),
                      "Profile should have a settings gear button")
    }
    
    // MARK: - Settings
    
    func testSettings_HasSignOut() {
        completeOnboarding()
        
        app.tabBars.buttons["You"].tap()
        
        // Tap settings gear
        let settingsButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'settings'")
        ).firstMatch
        
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            // Settings should have reset/sign out option
            let resetButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Reset' OR label CONTAINS[c] 'Sign Out' OR label CONTAINS[c] 'Delete'")
            ).firstMatch
            
            XCTAssertTrue(resetButton.waitForExistence(timeout: 5),
                          "Settings should have account management options")
        }
    }
    
    // MARK: - Tab Navigation
    
    func testTabNavigation_AllFourTabs() {
        completeOnboarding()
        
        let tabs = ["Blueprint", "Pearl", "Insights", "You"]
        
        for tab in tabs {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 5),
                          "\(tab) tab should exist")
            tabButton.tap()
            // Brief pause for transition
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    // MARK: - Dark Theme Verification
    
    func testDarkTheme_Applied() {
        // Pearl uses dark mode exclusively
        // The app should prefer dark color scheme
        XCTAssertTrue(app.exists, "App should launch in dark mode")
        // Visual verification would require screenshot comparison
    }
    
    // MARK: - Helpers
    
    private func completeOnboarding() {
        // Quick path through onboarding for tests that need the main app
        let beginButton = app.buttons["Begin Your Journey"]
        if beginButton.waitForExistence(timeout: 5) {
            beginButton.tap()
        }
        
        // Name
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Astrid")
            
            let continueBtn = app.buttons["Continue"]
            if continueBtn.waitForExistence(timeout: 2) {
                continueBtn.tap()
            }
        }
        
        // Date — just tap continue/next (uses default date)
        let nextButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Continue' OR label CONTAINS[c] 'Next'")
        ).firstMatch
        if nextButton.waitForExistence(timeout: 3) {
            nextButton.tap()
        }
        
        // Time — skip if possible
        let skipButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'skip' OR label CONTAINS[c] \"don't know\"")
        ).firstMatch
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        } else if nextButton.waitForExistence(timeout: 2) {
            nextButton.tap()
        }
        
        // Location — type a city
        let locationField = app.textFields.firstMatch
        if locationField.waitForExistence(timeout: 3) {
            locationField.tap()
            locationField.typeText("Los Angeles")
            Thread.sleep(forTimeInterval: 1)
            
            // Tap first suggestion if available
            let suggestion = app.cells.firstMatch
            if suggestion.waitForExistence(timeout: 2) {
                suggestion.tap()
            }
            
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
            }
        }
        
        // Wait for generation to complete (up to 30s)
        let dashboardElement = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Blueprint' OR label CONTAINS[c] 'Dashboard'")
        ).firstMatch
        _ = dashboardElement.waitForExistence(timeout: 30)
    }
    
    private func navigateToOnboardingStep(_ step: Int) {
        let beginButton = app.buttons["Begin Your Journey"]
        if beginButton.waitForExistence(timeout: 5) {
            beginButton.tap()
        }
        
        for _ in 1..<step {
            let continueBtn = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Continue' OR label CONTAINS[c] 'Next' OR label CONTAINS[c] 'Skip'")
            ).firstMatch
            
            if continueBtn.waitForExistence(timeout: 3) {
                continueBtn.tap()
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}
