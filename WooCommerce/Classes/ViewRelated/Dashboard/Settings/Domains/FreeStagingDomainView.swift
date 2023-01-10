import SwiftUI

/// Shows a site's free staging domain, with an optional badge if the domain is the primary domain.
struct FreeStagingDomainView: View {
    let domain: DomainSettingsViewModel.FreeStagingDomain

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.freeDomainTitle)
                Text(domain.name)
                    .bold()
            }
            if domain.isPrimary {
                // TODO: 8558 - refactor to reuse `BadgeView`
                Text(Localization.primaryDomainNotice)
                    .foregroundColor(Color(.textBrand))
                    .padding(.leading, Layout.horizontalPadding)
                    .padding(.trailing, Layout.horizontalPadding)
                    .padding(.top, Layout.verticalPadding)
                    .padding(.bottom, Layout.verticalPadding)
                    .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(Color(.withColorStudio(.wooCommercePurple, shade: .shade0))))
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }
}

private extension FreeStagingDomainView {
    enum Localization {
        static let freeDomainTitle = NSLocalizedString(
            "Your free store address",
            comment: "Title of the free domain view."
        )
        static let primaryDomainNotice = NSLocalizedString(
            "Primary site address",
            comment: "Title for a free domain if the domain is the primary site address."
        )
    }
}

private extension FreeStagingDomainView {
    enum Layout {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 8
        static let contentSpacing: CGFloat = 8
    }
}

struct FreeStagingDomainView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FreeStagingDomainView(domain: .init(isPrimary: true, name: "go.trees"))
            FreeStagingDomainView(domain: .init(isPrimary: false, name: "go.trees"))
        }
    }
}
