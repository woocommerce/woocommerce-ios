import XCTest
@testable import WordPressAuthenticator

class SignInTrackerTests: XCTestCase {
    
    // MARK: - Expectations: Building the properties dictionary
    
    private func expectedProperties(source: SignInTracker.Source, flow: SignInTracker.Flow, step: SignInTracker.Step) -> [String: String] {
        
        return [
            SignInTracker.Property.source.rawValue: source.rawValue,
            SignInTracker.Property.flow.rawValue: flow.rawValue,
            SignInTracker.Property.step.rawValue: step.rawValue
        ]
    }
    
    private func expectedProperties(source: SignInTracker.Source, flow: SignInTracker.Flow, step: SignInTracker.Step, failure: String) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[SignInTracker.Property.failure.rawValue] = failure
        
        return properties
    }
    
    private func expectedProperties(source: SignInTracker.Source, flow: SignInTracker.Flow, step: SignInTracker.Step, click: SignInTracker.ClickTarget) -> [String: String] {
        
        var properties = expectedProperties(source: source, flow: flow, step: step)
        properties[SignInTracker.Property.click.rawValue] = click.rawValue
        
        return properties
    }
    
    /// Test that the no-params constructor for the context initializes it with the properties we expect.
    ///
    func testContextInitializerWithDefaultParams() {
        let context = SignInTracker.Context()
        
        XCTAssertEqual(context.lastFlow, .wpCom)
        XCTAssertEqual(context.lastSource, .default)
        XCTAssertEqual(context.lastStep, .prologue)
    }
    
    /// Test that initializing a context with specific params works.
    ///
    func testContextInitializerWithExplicitParams() {
        let context = SignInTracker.Context(lastFlow: .apple, lastSource: .deeplink, lastStep: .emailOpened)
        
        XCTAssertEqual(context.lastFlow, .apple)
        XCTAssertEqual(context.lastSource, .deeplink)
        XCTAssertEqual(context.lastStep, .emailOpened)
    }
    
    /// Test that when tracking an event through the SignInTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    /// Ref: pbArwn-AP-p2
    ///
    func testEventTracking() {
        let source = SignInTracker.Source.reauthetication
        let flow = SignInTracker.Flow.googleLogin
        let step = SignInTracker.Step.start
        
        let expectedEventName = SignInTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let context = SignInTracker.Context()
        let tracker = SignInTracker(context: context, track: track)
        
        tracker.set(source: source)
        tracker.track(step: step, flow: flow)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that when tracking an event through the SignInTracker, the backing analytics tracker
    /// receives a matching event.
    ///
    func testBackingTracker() {
        let source = SignInTracker.Source.reauthetication
        let flow = SignInTracker.Flow.googleLogin
        let step = SignInTracker.Step.start
        
        let expectedEventName = SignInTracker.EventType.step.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let context = SignInTracker.Context()
        let tracker = SignInTracker(context: context, track: track)
        
        tracker.set(source: source)
        tracker.track(step: step, flow: flow)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that tracking a failure maintains the source, flow and step from the previously recorded step.
    ///
    /// Ref: pbArwn-I6-p2
    ///
    func testFailure() {
        let source = SignInTracker.Source.default
        let flow = SignInTracker.Flow.googleLogin
        let step = SignInTracker.Step.start
        let failure = "some error"
        
        let expectedEventName = SignInTracker.EventType.failure.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, failure: failure)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let context = SignInTracker.Context()
        let tracker = SignInTracker(context: context, track: track)
        
        tracker.set(source: source)
        tracker.track(step: step, flow: flow)
        tracker.track(failure: failure)
        
        waitForExpectations(timeout: 0.1)
    }
    
    /// Test that tracking a click maintains the source, flow and step from the previously recorded step.
    ///
    /// Ref: pbArwn-I6-p2
    ///
    func testClick() {
        let source = SignInTracker.Source.default
        let flow = SignInTracker.Flow.googleLogin
        let step = SignInTracker.Step.start
        let click = SignInTracker.ClickTarget.dismiss
        
        let expectedEventName = SignInTracker.EventType.interaction.rawValue
        let expectedEventProperties = self.expectedProperties(source: source, flow: flow, step: step, click: click)
        let trackingIsOk = expectation(description: "The parameters of the tracking call are as expected")
        
        let track = { (event: AnalyticsEvent) in
            // We'll ignore the first event and only check the properties from the failure.
            if event.name == expectedEventName
                && event.properties == expectedEventProperties {
                
                trackingIsOk.fulfill()
            }
        }
        
        let context = SignInTracker.Context()
        let tracker = SignInTracker(context: context, track: track)
        
        tracker.set(source: source)
        tracker.track(step: step, flow: flow)
        tracker.track(click: click)
        
        waitForExpectations(timeout: 0.1)
    }
}
