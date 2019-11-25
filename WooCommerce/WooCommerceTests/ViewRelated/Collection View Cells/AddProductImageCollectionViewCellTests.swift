import XCTest
@testable import WooCommerce

class AddProductImageCollectionViewCellTests: XCTestCase {

    private var cell: AddProductImageCollectionViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("AddProductImageCollectionViewCell", owner: self, options: nil)
        cell = nib?.first as? AddProductImageCollectionViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

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
        let borderColor = StyleManager.tableViewCellSelectionStyle.cgColor
        let maskToBounds = true
        XCTAssertEqual(cell?.contentView.layer.cornerRadius, cornerRadius)
        XCTAssertEqual(cell?.contentView.layer.borderWidth, borderWidth)
        XCTAssertEqual(cell?.contentView.layer.borderColor, borderColor)
        XCTAssertEqual(cell?.contentView.layer.masksToBounds, maskToBounds)
    }


}
