import XCTest
@testable import WooCommerce

@MainActor
final class AddProductImageCollectionViewCellTests: XCTestCase {

    private lazy var cell: AddProductImageCollectionViewCell? = {
        let nib = Bundle.main.loadNibNamed("AddProductImageCollectionViewCell", owner: self, options: nil)
        return nib?.first as? AddProductImageCollectionViewCell
    }()

    func testImageViewIsNotEmpty() {
        XCTAssertNotNil(cell?.imageView.image)
    }

    func testImageViewConfiguration() {
        XCTAssertEqual(cell?.imageView.contentMode, .center)
        XCTAssertEqual(cell?.imageView.clipsToBounds, true)
    }

    func testCellAppearance() {
        let cornerRadius = CGFloat(2.0)
        let borderWidth = CGFloat(0.5)
        let borderColor = UIColor.systemColor(.systemGray4).cgColor
        let maskToBounds = true
        XCTAssertEqual(cell?.contentView.layer.cornerRadius, cornerRadius)
        XCTAssertEqual(cell?.contentView.layer.borderWidth, borderWidth)
        XCTAssertEqual(cell?.contentView.layer.borderColor, borderColor)
        XCTAssertEqual(cell?.contentView.layer.masksToBounds, maskToBounds)
    }
}
