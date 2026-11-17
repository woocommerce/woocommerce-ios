import StoreDesignSystem
import SwiftUI

@MainActor
final class StoreOrderListSectionHeaderView: UITableViewHeaderFooterView {
    func configure(title: String) {
        contentConfiguration = UIHostingConfiguration {
            Text(title)
                .storeTextStyle(.titleSmall.emphasized)
                .foregroundStyle(.storeOnSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, StorePadding.p5)
                .padding(.vertical, StorePadding.p4)
                .background(.storeSurface)
                .accessibilityAddTraits(.isHeader)
        }
        .margins(.all, 0)
        backgroundConfiguration = .clear()
    }
}
