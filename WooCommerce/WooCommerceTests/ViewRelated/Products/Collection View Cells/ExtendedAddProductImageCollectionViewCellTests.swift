import XCTest
@testable import WooCommerce

@MainActor
final class ExtendedAddProductImageCollectionViewCellTests: XCTestCase {

    private lazy var cell: ExtendedAddProductImageCollectionViewCell? = {
        let nib = Bundle.main.loadNibNamed("ExtendedAddProductImageCollectionViewCell", owner: self, options: nil)
        return nib?.first as? ExtendedAddProductImageCollectionViewCell
    }()

    func testImageViewIsNotEmpty() {
        XCTAssertNotNil(cell?.imageView.image)
    }

    func testImageViewConfiguration() {
        XCTAssertEqual(cell?.imageView.contentMode, .center)
        XCTAssertEqual(cell?.imageView.clipsToBounds, true)
    }

    func testTextLabelStyleIsSetToBody() {
        let mockLabel = UILabel()
        mockLabel.applyEmptyStateTitleStyle()

        XCTAssertEqual(cell?.title?.font, mockLabel.font)
        XCTAssertEqual(cell?.title?.textColor, mockLabel.textColor)
    }

    func testVariationAndProductProductImageLabelsDiffer() {
        cell?.configurePlaceholderLabelForProductImages(isVariation: true)
        let variationLabel = cell?.title?.text

        cell?.configurePlaceholderLabelForProductImages(isVariation: false)
        let productLabel = cell?.title?.text

        XCTAssertNotEqual(variationLabel, productLabel)
    }
}
