import XCTest
import Combine
@testable import WooCommerce

@MainActor
final class ProductImageCollectionViewCellTests: XCTestCase {

    private lazy var cell: ProductImageCollectionViewCell? = {
        let nib = Bundle.main.loadNibNamed("ProductImageCollectionViewCell", owner: self, options: nil)
        let cell = nib?.first as? ProductImageCollectionViewCell
        cell?.imageView.image = UIImage.wooLogoImage()
        return cell
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
        let borderColor = UIColor.border.cgColor
        let maskToBounds = true
        XCTAssertEqual(cell?.contentView.layer.cornerRadius, cornerRadius)
        XCTAssertEqual(cell?.contentView.layer.borderWidth, borderWidth)
        XCTAssertEqual(cell?.contentView.layer.borderColor, borderColor)
        XCTAssertEqual(cell?.contentView.layer.masksToBounds, maskToBounds)
    }

    func test_prepare_for_reuse_when_image_request_exists_then_cancels_request() throws {
        // Given
        let cell = try XCTUnwrap(cell)
        var cancellationCount = 0
        let request = AnyCancellable { cancellationCount += 1 }
        cell.cancellable = request

        withExtendedLifetime(request) {
            // When
            cell.prepareForReuse()

            // Then
            XCTAssertEqual(cancellationCount, 1)
            XCTAssertNil(cell.cancellable)
            XCTAssertNil(cell.imageView.image)
        }
    }

    func test_deinit_when_image_request_exists_then_cancels_request() {
        // Given
        var cancellationCount = 0
        let request = AnyCancellable { cancellationCount += 1 }
        weak var releasedCell: ProductImageCollectionViewCell?
        withExtendedLifetime(request) {
            autoreleasepool {
                var cell: ProductImageCollectionViewCell? = ProductImageCollectionViewCell(frame: .zero)
                releasedCell = cell
                cell?.cancellable = request

                // When
                cell = nil
            }

            // Then
            XCTAssertNil(releasedCell)
            XCTAssertEqual(cancellationCount, 1)
        }
    }
}
