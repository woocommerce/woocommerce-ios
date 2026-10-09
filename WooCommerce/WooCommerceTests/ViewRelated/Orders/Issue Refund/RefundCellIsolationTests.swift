import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct RefundCellIsolationTests {
    @Test(arguments: [
        "RefundConfirmationCardDetailsCell",
        "RefundCustomAmountsDetailsTableViewCell",
        "RefundItemTableViewCell",
        "RefundProductsTotalTableViewCell",
        "RefundShippingDetailsTableViewCell",
        "IssueRefundTableViewCell"
    ])
    func test_awakeFromNib_when_loaded_on_main_actor_then_configures_cell(nibName: String) throws {
        // Given
        let nib = UINib(nibName: nibName, bundle: Bundle(for: RefundItemTableViewCell.self))

        // When
        let cell = try #require(nib.instantiate(withOwner: nil).first as? UITableViewCell)

        // Then
        #expect(String(describing: type(of: cell)) == nibName)
        #expect(cell.backgroundConfiguration != nil)
    }
}
