import StoreDesignSystem
import SwiftUI

@MainActor
final class StoreOrderListTableViewCell: UITableViewCell {
    private var viewModel: OrderListCellViewModel?
    private var isPlaceholder = false
    private(set) var usesSelectedAppearance = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundConfiguration = .clear()
        focusEffect = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: OrderListCellViewModel?) {
        self.viewModel = viewModel
        isPlaceholder = false
        isUserInteractionEnabled = true
        accessibilityElementsHidden = false
        accessibilityIdentifier = viewModel?.title
        setNeedsUpdateConfiguration()
    }

    func configurePlaceholder() {
        viewModel = nil
        isPlaceholder = true
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        accessibilityIdentifier = nil
        setNeedsUpdateConfiguration()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        isPlaceholder = false
        isUserInteractionEnabled = true
        accessibilityElementsHidden = false
        accessibilityIdentifier = nil
        usesSelectedAppearance = false
        contentConfiguration = nil
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard viewModel != nil || isPlaceholder else { return }

        usesSelectedAppearance = !isPlaceholder && (state.isSelected || state.isHighlighted)
        contentConfiguration = UIHostingConfiguration { [viewModel, usesSelectedAppearance] in
            if let viewModel {
                StoreOrderListRow(viewModel: viewModel, isSelected: usesSelectedAppearance)
            } else {
                StoreOrderListPlaceholderContent()
            }
        }
        .margins(.all, 0)
    }
}

private struct StoreOrderListPlaceholderContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                bar.frame(width: StoreSpacing.s12 + StoreSpacing.s8, height: StoreSpacing.s4)

                HStack(spacing: StoreSpacing.s3) {
                    bar.frame(maxWidth: .infinity)
                    bar.frame(width: StoreSpacing.s12 + StoreSpacing.s8)
                }
                .frame(height: StoreSpacing.s6)

                Capsule().fill(.storeSurfaceContainerHighest)
                    .frame(width: StoreSpacing.s12 + StoreSpacing.s4, height: StoreSize.badgeHeight)
            }
            .padding(.horizontal, StorePadding.p5).padding(.top, StorePadding.p4)
            .padding(.bottom, StorePadding.p5)
            .frame(maxWidth: .infinity, minHeight: StoreSize.minimumTapTarget * 2 + StoreSpacing.s3, alignment: .leading)

            StoreDivider(variant: .inset)
        }
        .background(.storeSurfaceBright).shimmering(active: !reduceMotion).accessibilityHidden(true)
    }

    private var bar: some View {
        RoundedRectangle(cornerRadius: StoreRadius.small).fill(.storeSurfaceContainerHighest)
    }
}
