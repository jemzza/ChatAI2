import XCTest

final class ChatFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }
    
    @MainActor
    func testPremiumUserGetsReply() {
        let app = launch("-mockPremium")
        openNewChat(in: app, typing: "Plan my day")
        app.buttons["Send"].tap()
        
        // Фейковый провайдер отвечает markdown-текстом из FakeChatProvider.sampleReply.
        XCTAssertTrue(app.staticTexts["Welcome to the team!"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Copy"].exists)
    }
    
    @MainActor
    func testFreeUserSeesPaywallAndKeepsText() {
        let app = launch("-mockFree")
        openNewChat(in: app, typing: "Plan my day")
        app.buttons["Send"].tap()
        
        XCTAssertTrue(app.buttons["Unlock now"].waitForExistence(timeout: 5))
        
        // Крестик появляется с задержкой — ждём его, а не жмём сразу.
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "Plan my day")
    }
    
    @MainActor
    private func launch(_ subscription: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-mockData", subscription]
        app.launch()
        return app
    }
    
    @MainActor
    private func openNewChat(in app: XCUIApplication, typing text: String) {
        let ask = app.buttons["Ask anything..."]
        XCTAssertTrue(ask.waitForExistence(timeout: 10))
        ask.tap()
        let field = app.textFields["How can I help you?"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }
}
