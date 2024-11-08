import XCTest
@testable import WooCommerce
import Yosemite
import SwiftUI

final class WooCarrierPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_tabs() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 2)
        XCTAssertEqual(viewModel.tabs.count, 2)
        XCTAssertEqual(viewModel.selectedTabIndex, 0)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_inits_with_zero_tabs() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 0)
        XCTAssertEqual(viewModel.tabs.count, 0)
        XCTAssertNil(viewModel.selectedTabIndex)
        XCTAssertNil(viewModel.selectedPackageId)
        XCTAssertNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_changes_selected_tab() {
        // Given/When
        let packagesRepository = MockWooShippingPackagesRepository()
        packagesRepository.loadPackages()
        let carrierTabs = packagesRepository.carrierPackages
        let viewModel = WooCarrierPackagesSelectionViewModel(packagesRepository: packagesRepository)

        // Then
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.first?.carrier.name)
        // "select" second tab
        viewModel.selectedTabIndex = 1
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.last?.carrier.name)
    }
}
