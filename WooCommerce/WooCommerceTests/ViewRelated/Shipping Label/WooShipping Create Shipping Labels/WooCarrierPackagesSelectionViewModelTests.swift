import XCTest
@testable import WooCommerce
import Yosemite
import SwiftUI

final class WooCarrierPackagesSelectionViewModelTests: XCTestCase {
    func test_it_inits_tabs() {
        // Given/When
        let carrierTabs = testingCarrierTabs()
        let tabs = carrierTabs.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }
        let viewModel = WooCarrierPackagesSelectionViewModel(carrierTabs: carrierTabs, tabs: tabs)

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 2)
        XCTAssertEqual(viewModel.tabs.count, 2)
        XCTAssertEqual(viewModel.selectedTabIndex, 0)
        XCTAssertEqual(viewModel.selectedPackageId, nil)
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_inits_with_zero_tabs() {
        // Given/When
        let viewModel = WooCarrierPackagesSelectionViewModel(carrierTabs: [], tabs: [])

        // Then
        XCTAssertEqual(viewModel.carrierTabs.count, 0)
        XCTAssertEqual(viewModel.tabs.count, 0)
        XCTAssertEqual(viewModel.selectedTabIndex, nil)
        XCTAssertEqual(viewModel.selectedPackageId, nil)
        XCTAssertNil(viewModel.selectedCarrierTab)
        XCTAssertNil(viewModel.selectedPackage)
    }

    func test_it_changes_selected_tab() {
        // Given/When
        let carrierTabs = testingCarrierTabs()
        let tabs = carrierTabs.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }
        let viewModel = WooCarrierPackagesSelectionViewModel(carrierTabs: carrierTabs, tabs: tabs)

        // Then
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.first?.carrier.name)
        // "select" second tab
        viewModel.selectedTabIndex = 1
        XCTAssertNotNil(viewModel.selectedCarrierTab)
        XCTAssertEqual(viewModel.selectedCarrierTab?.carrier.name, carrierTabs.last?.carrier.name)
    }
}

extension WooCarrierPackagesSelectionViewModelTests {
    private func testingCarrierTabs() -> [WooShippingPackagesCarrierTab] {
        let uspsPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "usps", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ])
        ]
        let dhlPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg"),
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooCarrierPackageData(name: "Small Flat Rate Box", type: "DHL Express", packageType: "box", dimensions: "21.92 × 13.67 × 4.14 cm", weight: "5 kg")
            ])
        ]
        let uspsCarrier: WooShippingPackagesCarrierTab = WooShippingPackagesCarrierTab(carrier: WooShippingCarrier.usps, packageGroups: uspsPackageGroups)
        let dhlCarrier: WooShippingPackagesCarrierTab = WooShippingPackagesCarrierTab(carrier: WooShippingCarrier.dhlExpress, packageGroups: dhlPackageGroups)

        return [uspsCarrier, dhlCarrier]
    }
}
