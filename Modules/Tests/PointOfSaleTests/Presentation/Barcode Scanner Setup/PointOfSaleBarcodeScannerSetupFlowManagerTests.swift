import Testing
import Foundation
import SwiftUI
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

    @Test func test_goBack_when_on_scanner_selection_then_closes_the_setup() {
        // Given a flow manager on scanner selection
        var isPresented = true
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            analytics: MockPOSAnalytics()
        )

        // When going back
        sut.goBack()

        // Then the setup is closed
        #expect(isPresented == false)
    }

    @Test func test_goBack_when_on_first_setup_step_then_returns_to_scanner_selection() {
        // Given a flow manager on the first step of a scanner setup
        var isPresented = true
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            analytics: MockPOSAnalytics()
        )
        sut.selectScanner(.starBSH20B)

        // When going back
        sut.goBack()

        // Then it returns to scanner selection and keeps the setup open
        if case .scannerSelection = sut.currentState {
        } else {
            #expect(Bool(false), "Expected scannerSelection state")
        }
        #expect(isPresented == true)
    }

    @Test func test_goBack_when_on_later_setup_step_then_goes_one_step_back() {
        // Given a flow manager on the pairing step
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: .constant(true), analytics: MockPOSAnalytics())
        sut.selectScanner(.starBSH20B)
        sut.buttonConfiguration.primaryButton?.action()
        #expect(sut.currentStepKey == PointOfSaleBarcodeScannerStepID.pairing.rawValue)

        // When going back
        sut.goBack()

        // Then it shows the previous step
        #expect(sut.currentStepKey == PointOfSaleBarcodeScannerStepID.setupBarcodeHID.rawValue)
    }

    @Test func test_buttonConfiguration_removingBackButtons_when_step_has_back_then_keeps_only_next() {
        // Given a flow manager on a step with Next and Back
        let sut = PointOfSaleBarcodeScannerSetupFlowManager(isPresented: .constant(true), analytics: MockPOSAnalytics())
        sut.selectScanner(.starBSH20B)

        // When removing the back buttons
        let configuration = sut.buttonConfiguration.removingBackButtons()

        // Then only Next is left
        #expect(sut.buttonConfiguration.secondaryButton?.isBack == true)
        #expect(configuration.primaryButton != nil)
        #expect(configuration.secondaryButton == nil)
    }

    @Test func test_previousStep_when_on_complete_step_then_returns_to_test_step() {
        // Given a setup flow on the complete step
        let sut = PointOfSaleBarcodeScannerSetupFlow(scannerType: .starBSH20B,
                                                     analytics: MockPOSAnalytics(),
                                                     onBackToSelection: {},
                                                     onDismiss: {})
        sut.transition(to: .complete)

        // When going back
        sut.previousStep()

        // Then it shows the test step
        #expect(sut.currentStepKey == .test)
    }
}
