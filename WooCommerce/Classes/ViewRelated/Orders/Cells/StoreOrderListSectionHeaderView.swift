import StoreDesignSystem
import SwiftUI

@MainActor
final class StoreOrderListSectionHeaderView: UITableViewHeaderFooterView {
    func configure(title: String) {
        contentConfiguration = UIHostingConfiguration {
            Text(title.uppercased())
                .storeTextStyle(.titleSmall)
                .foregroundStyle(.storeOnSurfaceVariantLowest)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top], StorePadding.p5)
                .padding(.bottom, StorePadding.p3)
                .background(.storeSurface)
                .accessibilityAddTraits(.isHeader)
        }
        .margins(.all, 0)
        backgroundConfiguration = .clear()
    }
}
