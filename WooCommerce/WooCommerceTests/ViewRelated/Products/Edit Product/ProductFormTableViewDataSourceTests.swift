import Testing
import UIKit
import Photos
import Yosemite

@testable import WooCommerce

@MainActor
struct ProductFormTableViewDataSourceTests {
    @Test func test_status_row_when_switch_tapped_then_delivers_status_change_synchronously() throws {
        // Given
        let row = ProductFormSection.SettingsRow.status(viewModel: .init(viewModel: .init(icon: UIImage(),
                                                                                       title: "Status",
                                                                                       details: "Published"),
                                                                        isSwitchOn: false,
                                                                        isActionable: true),
                                                       isEditable: true)
        let dataSource = makeDataSource(sections: [.settings(rows: [row])])
        var receivedStatus: Bool?
        dataSource.configureActions(onNameChange: nil,
                                    onStatusChange: { receivedStatus = $0 },
                                    onAddImage: {},
                                    onFailedImageUpload: { _, _ in })
        let tableView = UITableView()
        tableView.registerNib(for: ImageAndTitleAndTextTableViewCell.self)
        tableView.dataSource = dataSource
        let callback: any UITableViewDataSource = dataSource

        // When
        let cell = callback.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let toggle = try #require(cell.accessoryView as? UISwitch)
        toggle.isOn = true
        toggle.sendActions(for: .touchUpInside)

        // Then
        #expect(callback.numberOfSections?(in: tableView) == 1)
        #expect(callback.tableView(tableView, numberOfRowsInSection: 0) == 1)
        #expect(receivedStatus == true)
    }

    @Test func test_reviews_row_when_requested_through_data_source_then_loads_review_cell() {
        // Given
        let row = ProductFormSection.SettingsRow.reviews(viewModel: .init(icon: UIImage(), title: "Reviews", details: "3 reviews"),
                                                        ratingCount: 3,
                                                        averageRating: "4.5")
        let dataSource = makeDataSource(sections: [.settings(rows: [row])])
        let tableView = UITableView()
        tableView.registerNib(for: ProductReviewsTableViewCell.self)
        tableView.dataSource = dataSource
        let callback: any UITableViewDataSource = dataSource

        // When
        let cell = callback.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        // Then
        #expect(cell is ProductReviewsTableViewCell)
        #expect(cell.accessibilityIdentifier == "product-review-cell")
        #expect(cell.accessoryType == .disclosureIndicator)
    }

    private func makeDataSource(sections: [ProductFormSection]) -> ProductFormTableViewDataSource {
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: .product(id: 256), imageStatuses: [])
        let imageLoader = DefaultProductUIImageLoader(productImageActionHandler: actionHandler,
                                                      phAssetImageLoaderProvider: { PHImageManager.default() })
        return ProductFormTableViewDataSource(viewModel: TableViewModel(sections: sections),
                                              productImageStatuses: [],
                                              productUIImageLoader: imageLoader)
    }

    private struct TableViewModel: ProductFormTableViewModel {
        let sections: [ProductFormSection]
    }
}
