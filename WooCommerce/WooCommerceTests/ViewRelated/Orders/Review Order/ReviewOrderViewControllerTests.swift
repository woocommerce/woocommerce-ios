import Foundation
import Testing
import UIKit
import Yosemite
import Fakes
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
struct ReviewOrderViewControllerTests {
    private let productID: Int64 = 100

    @Test func shippingAddressCell_when_address_has_phone_then_address_ends_with_phone() throws {
        // Given
        let shippingAddress = Address.fake().copy(firstName: "Skylar",
                                                  lastName: "Ferry",
                                                  address1: "60 29th Street",
                                                  city: "San Francisco",
                                                  state: "CA",
                                                  postcode: "94110",
                                                  country: "US",
                                                  phone: "2125550199")
        let postalAddress = try #require(shippingAddress.formattedPostalAddress)

        // When
        let cell = try makeShippingAddressCell(shippingAddress: shippingAddress)

        // Then
        #expect(cell.address == postalAddress + "\n2125550199")
    }

    @Test func shippingAddressCell_when_address_has_only_phone_then_address_is_phone() throws {
        // Given
        let shippingAddress = Address.empty.copy(phone: "2125550199")

        // When
        let cell = try makeShippingAddressCell(shippingAddress: shippingAddress)

        // Then
        #expect(cell.address == "2125550199")
    }

    @Test func shippingAddressCell_when_address_has_no_phone_then_address_is_postal_address() throws {
        // Given
        let shippingAddress = Address.fake().copy(address1: "60 29th Street",
                                                  city: "San Francisco",
                                                  state: "CA",
                                                  postcode: "94110",
                                                  country: "US",
                                                  phone: "  ")
        let postalAddress = try #require(shippingAddress.formattedPostalAddress)

        // When
        let cell = try makeShippingAddressCell(shippingAddress: shippingAddress)

        // Then
        #expect(cell.address == postalAddress)
    }

    @Test func shippingAddressCell_when_address_is_empty_then_shows_no_address_title() throws {
        // When
        let cell = try makeShippingAddressCell(shippingAddress: Address.empty)

        // Then
        #expect(cell.address == "No address specified.")
    }
}

private extension ReviewOrderViewControllerTests {
    /// Builds the view controller with a non-virtual product, so the shipping address row is present, and returns that row's cell.
    ///
    func makeShippingAddressCell(shippingAddress: Address) throws -> CustomerInfoTableViewCell {
        let item = OrderItem.fake().copy(productID: productID, quantity: 1)
        let order = Order.fake().copy(status: .processing, items: [item], shippingAddress: shippingAddress)
        let product = Product.fake().copy(productID: productID, virtual: false).toOrderDetailsProduct()
        let viewModel = ReviewOrderViewModel(order: order,
                                             products: [product],
                                             showAddOns: false,
                                             stores: MockStoresManager(sessionManager: .makeForTesting()),
                                             storageManager: MockStorageManager())
        let viewController = ReviewOrderViewController(viewModel: viewModel, markOrderCompleteHandler: {})

        let tableView = UITableView()
        tableView.registerNib(for: CustomerInfoTableViewCell.self)

        var shippingIndexPath: IndexPath?
        for (sectionIndex, section) in viewModel.sections.enumerated() {
            for (rowIndex, row) in section.rows.enumerated() {
                if case .shippingAddress = row {
                    shippingIndexPath = IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        let indexPath = try #require(shippingIndexPath)

        return try #require(viewController.tableView(tableView, cellForRowAt: indexPath) as? CustomerInfoTableViewCell)
    }
}
