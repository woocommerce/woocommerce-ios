import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct ReusableViewNibIsolationTests {
    @Test(arguments: [
        "BadgedLeftImageTableViewCell",
        "BasicTableViewCell",
        "ButtonTableViewCell",
        "DatePickerTableViewCell",
        "EmptyListMessageWithActionView",
        "ErrorSectionHeaderView",
        "HeadlineLabelTableViewCell",
        "HeadlineTableViewCell",
        "ImageTableViewCell",
        "LabelAndButtonTableViewCell",
        "LabeledTextViewTableViewCell",
        "LargeImageTableViewCell",
        "LearnMoreTableViewCell",
        "LedgerTableViewCell",
        "LeftImageTableViewCell",
        "LeftImageTitleSubtitleTableViewCell",
        "LeftImageTitleSubtitleToggleTableViewCell",
        "OverlayMessageView",
        "ReadMoreTableViewCell",
        "PrimarySectionHeaderView",
        "SpacerTableViewCell",
        "StatusListTableViewCell",
        "SwitchTableViewCell",
        "TableFooterView",
        "TextFieldTableViewCell",
        "TextViewTableViewCell",
        "TitleAndEditableValueTableViewCell",
        "TitleAndSubtitleAndStatusTableViewCell",
        "TitleAndTextFieldTableViewCell",
        "TitleAndTextFieldWithImageTableViewCell",
        "TitleAndValueTableViewCell",
        "TopLoaderView",
        "TwoColumnHeadlineFootnoteTableViewCell",
        "TwoColumnSectionHeaderView",
        "TwoColumnTableViewCell",
        "UnderlineableTitleAndSubtitleAndDetailTableViewCell",
        "UnitInputTableViewCell",
        "ValueOneTableViewCell",
        "WooBasicTableViewCell"
    ])
    func test_nib_loading_when_on_main_actor_then_finishes_synchronous_setup(nibName: String) throws {
        // Given
        let nib = UINib(nibName: nibName, bundle: Bundle(for: BasicTableViewCell.self))

        // When
        let view = try #require(nib.instantiate(withOwner: nil).first as? UIView)

        // Then
        #expect(String(describing: type(of: view)) == nibName)
    }

    @Test
    func test_nib_loading_when_basic_cell_returns_then_body_style_is_ready() throws {
        // Given
        let nib = UINib(nibName: "BasicTableViewCell", bundle: Bundle(for: BasicTableViewCell.self))

        // When
        let cell = try #require(nib.instantiate(withOwner: nil).first as? BasicTableViewCell)
        let label = try #require(cell.textLabel)

        // Then
        #expect(label.adjustsFontForContentSizeCategory)
    }
}
