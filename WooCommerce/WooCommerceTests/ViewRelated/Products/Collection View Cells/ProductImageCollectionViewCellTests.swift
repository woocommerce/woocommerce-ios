import XCTest
@testable import WooCommerce

final class ProductImageCollectionViewCellTests: XCTestCase {

    private var cell: ProductImageCollectionViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("ProductImageCollectionViewCell", owner: self, options: nil)
        cell = nib?.first as? ProductImageCollectionViewCell
        cell?.imageView.image = UIImage.wooLogoImage()
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testImageViewIsNotEmpty() {
        XCTAssertNotNil(cell?.imageView.image)
    }

    func testImageViewConfiguration() {
        XCTAssertEqual(cell?.imageView.contentMode, .scaleAspectFit)
        XCTAssertEqual(cell?.imageView.clipsToBounds, true)
    }

    func testCellAppearance() {
        let cornerRadius = CGFloat(2.0)
        let borderWidth = CGFloat(0.5)
        let borderColor = UIColor.border.cgColor
        let maskToBounds = true
        XCTAssertEqual(cell?.contentView.layer.cornerRadius, cornerRadius)
        XCTAssertEqual(cell?.contentView.layer.borderWidth, borderWidth)
        XCTAssertEqual(cell?.contentView.layer.borderColor, borderColor)
        XCTAssertEqual(cell?.contentView.layer.masksToBounds, maskToBounds)
    }

}
