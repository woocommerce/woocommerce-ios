import Combine
import XCTest
@testable import WooCommerce
import Yosemite

final class ReprintShippingLabelViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()
        super.tearDown()
    }

    func test_paperSizeOptions_contain_all_supported_paper_sizes() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel()
        let viewModel = ReprintShippingLabelViewModel(shippingLabel: shippingLabel)

        // When
        let paperSizeOptions = viewModel.paperSizeOptions

        // Then
        XCTAssertEqual(paperSizeOptions, [.legal, .letter, .label])
    }

    // MARK: `selectedPaperSize`

    func test_selectedPaperSize_starts_with_nil() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel()
        let viewModel = ReprintShippingLabelViewModel(shippingLabel: shippingLabel)

        // When
        var paperSizeValues = [ShippingLabelPaperSize?]()
        viewModel.$selectedPaperSize.sink { paperSize in
            paperSizeValues.append(paperSize)
        }.store(in: &cancellables)

        // Then
        XCTAssertEqual(paperSizeValues, [nil])
    }

    func test_loadShippingLabelSettingsForDefaultPaperSize_sets_selectedPaperSize_to_setting_value_if_supported() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ReprintShippingLabelViewModel(shippingLabel: shippingLabel, stores: stores)
        let shippingLabelSettings = ShippingLabelSettings(siteID: shippingLabel.siteID, orderID: shippingLabel.orderID, paperSize: .letter)
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .loadShippingLabelSettings(_, completion):
                completion(shippingLabelSettings)
            default:
                break
            }
        }

        var paperSizeValues = [ShippingLabelPaperSize?]()
        viewModel.$selectedPaperSize.sink { paperSize in
            paperSizeValues.append(paperSize)
        }.store(in: &cancellables)

        // When
        viewModel.loadShippingLabelSettingsForDefaultPaperSize()

        // Then
        XCTAssertEqual(paperSizeValues, [nil, .letter])
    }
}
