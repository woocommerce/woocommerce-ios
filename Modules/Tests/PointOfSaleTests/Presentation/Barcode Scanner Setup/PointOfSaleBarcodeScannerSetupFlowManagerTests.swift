import Testing
import Foundation
import GameController
import enum WooFoundationCore.WooAnalyticsStat
@testable import PointOfSale

@MainActor
struct PointOfSaleBarcodeScannerSetupFlowManagerTests {

    @Test func test_flowManager_tracks_scanner_selected_when_selectScanner_called() {
        // Given a flow manager
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        // When a scanner is selected
        sut.selectScanner(.starBSH20B)

        // Then it tracks the scanner selected event
        let event = mockAnalytics.events.first
        #expect(event?.eventName == WooAnalyticsStat.pointOfSaleBarcodeScannerSetupScannerSelected.rawValue)
        #expect(event?.properties["scanner"] as? String == PointOfSaleBarcodeScannerType.starBSH20B.analyticsName)
    }

    @Test func test_flowManager_tracks_dismissal_when_onDisappear_called_on_non_completion_step() {
        // Given a flow manager with a setup flow in progress
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        // Setup a scanner flow (not on completion step)
        sut.selectScanner(.starBSH20B)
        mockAnalytics.events.removeAll() // Clear the selection event

        // When onDisappear is called (not on completion step)
        sut.onDisappear()

        // Then it tracks the dismissal event
        let event = mockAnalytics.events.first
        #expect(event?.eventName == WooAnalyticsStat.pointOfSaleBarcodeScannerSetupDismissed.rawValue)
        #expect(event?.properties["scanner"] as? String == PointOfSaleBarcodeScannerType.starBSH20B.analyticsName)
        #expect(event?.properties["step"] as? String == "setup_barcode_hid")
    }

    @Test func test_flowManager_tracks_dismissal_when_onDisappear_called_on_scanner_selection() {
        // Given a flow manager on scanner selection screen
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        // When onDisappear is called without selecting a scanner
        sut.onDisappear()

        // Then it tracks the dismissal event without scanner info
        let event = mockAnalytics.events.first
        #expect(event?.eventName == WooAnalyticsStat.pointOfSaleBarcodeScannerSetupDismissed.rawValue)
        #expect(event?.properties["scanner"] == nil)
        #expect(event?.properties["step"] == nil)
    }

    @Test func test_flowManager_tracks_keyboard_connected_when_in_setup_flow() {
        // Given a flow manager with a setup flow
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        // Setup a scanner flow
        sut.selectScanner(.netum1228BC)
        mockAnalytics.events.removeAll() // Clear the selection event

        // When keyboard connected notification is posted
        NotificationCenter.default.post(name: .GCKeyboardDidConnect, object: nil)

        // Then it tracks the scanner connected event
        let event = mockAnalytics.events.first
        #expect(event?.eventName == WooAnalyticsStat.pointOfSaleBarcodeScannerSetupScannerConnected.rawValue)
        #expect(event?.properties["scanner"] as? String == PointOfSaleBarcodeScannerType.netum1228BC.analyticsName)
    }

    @Test func test_flowManager_does_not_track_keyboard_connected_when_on_scanner_selection() {
        // Given a flow manager on scanner selection
        let mockAnalytics = MockPOSAnalytics()

        // When keyboard connected notification is posted
        NotificationCenter.default.post(name: .GCKeyboardDidConnect, object: nil)

        // Then it does not track any scanner connected event
        #expect(mockAnalytics.events.isEmpty)
    }

    @Test func test_flowManager_returns_correct_state_after_scanner_selection() {
        // Given a flow manager
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        // Initially on scanner selection
        if case .scannerSelection = sut.currentState {
        } else {
            #expect(Bool(false), "Expected scannerSelection state")
        }

        // When a scanner is selected
        sut.selectScanner(.tera12002D)

        // Then state changes to setup flow
        if case .setupFlow(let scannerType) = sut.currentState {
            #expect(scannerType == .tera12002D)
        } else {
            #expect(Bool(false), "Expected setupFlow state")
        }
    }

    @Test func test_flowManager_returns_to_scanner_selection_when_goBackToSelection_called() {
        // Given a flow manager in setup flow
        let mockAnalytics = MockPOSAnalytics()
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: .constant(true),
            analytics: mockAnalytics
        )

        sut.selectScanner(.other)
        if case .setupFlow = sut.currentState {
        } else {
            #expect(Bool(false), "Expected setupFlow state after selection")
        }

        // When going back to selection
        sut.goBackToSelection()

        // Then state returns to scanner selection
        if case .scannerSelection = sut.currentState {
        } else {
            #expect(Bool(false), "Expected scannerSelection state after going back")
        }
        #expect(sut.getCurrentStep() == nil)
    }

    @Test func test_navigationDirection_when_next_then_back_then_forward_then_backward() {
        // Given a flow manager on the first setup step
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: .constant(true), analytics: MockPOSAnalytics())
        sut.selectScanner(.starBSH20B)
        #expect(sut.navigationDirection == .forward)

        // When going to the next step
        sut.buttonConfiguration.primaryButton?.action()

        // Then the change goes forward
        #expect(sut.currentPageID == PointOfSaleBarcodeScannerStepID.pairing.rawValue)
        #expect(sut.navigationDirection == .forward)

        // When going back
        sut.buttonConfiguration.backButton?.action()

        // Then the change goes backward
        #expect(sut.currentPageID == PointOfSaleBarcodeScannerStepID.setupBarcodeHID.rawValue)
        #expect(sut.navigationDirection == .backward)
    }

    @Test func test_navigationDirection_when_going_back_to_selection_then_backward_and_forward_on_next_selection() {
        // Given a flow manager on the first setup step
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: .constant(true), analytics: MockPOSAnalytics())
        sut.selectScanner(.starBSH20B)
        let firstStepPageID = sut.currentPageID

        // When going back from the first step
        sut.buttonConfiguration.backButton?.action()

        // Then the selection page comes back from the leading edge
        #expect(sut.currentPageID != firstStepPageID)
        #expect(sut.navigationDirection == .backward)

        // When a scanner is selected again
        sut.selectScanner(.tera12002D)

        // Then the change goes forward
        #expect(sut.navigationDirection == .forward)
    }

    @Test func test_flow_navigationDirection_when_retry_after_failed_scan_then_backward() {
        // Given a flow on the failed test scan step
        let sut = PointOfSaleBarcodeScannerSetupFlow(scannerType: .starBSH20B,
                                                     analytics: MockPOSAnalytics(),
                                                     onBackToSelection: {},
                                                     onDismiss: {})
        sut.transition(to: .testScanFailed)
        #expect(sut.navigationDirection == .forward)

        // When retrying
        sut.transition(to: .retry)

        // Then it goes back to the first step
        #expect(sut.currentStepKey == .setupBarcodeHID)
        #expect(sut.navigationDirection == .backward)
    }

    @Test(arguments: PointOfSaleBarcodeScannerStepID.allCases)
    func test_pageID_when_step_then_only_timeout_shares_the_test_page(step: PointOfSaleBarcodeScannerStepID) {
        // Given / When
        let pageID = step.pageID

        // Then
        #expect(pageID == (step == .testScanTimedOut ? .test : step))
    }
}
