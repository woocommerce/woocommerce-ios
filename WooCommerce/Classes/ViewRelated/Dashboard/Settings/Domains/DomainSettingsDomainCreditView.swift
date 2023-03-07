import SwiftUI

/// Shows a banner that explains what domain credit is and a CTA to redeem it.
struct DomainSettingsDomainCreditView: View {
    let redeemDomainCreditTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .dividerStyle()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(Localization.title)
                        .bold()
                    Spacer()
                        .frame(height: Layout.spacingBetweenTitleAndSubtitle)
                    Text(Localization.subtitle)
                        .bodyStyle()
                    Spacer()
                        .frame(height: Layout.spacingBetweenSubtitleAndButton)
                    Button(Localization.buttonTitle) {
                        redeemDomainCreditTapped()
                    }
                    .buttonStyle(TextButtonStyle())
                }
                .padding(Layout.textContainerInsets)

                Spacer()

                Image(uiImage: .domainCreditImage)
            }

            Divider()
                .dividerStyle()

            Text(Localization.footnote)
                .footnoteStyle()
                .padding(Layout.footnoteInsets)
        }
    }
}

private extension DomainSettingsDomainCreditView {
    enum Localization {
        static let title = NSLocalizedString(
            "Claim your free domain",
            comment: "Title of the domain credit banner in domain settings."
        )
        static let subtitle = NSLocalizedString(
            "You have a free one-year domain registration included with your plan.",
            comment: "Subtitle of the domain credit banner in domain settings."
        )
        static let buttonTitle = NSLocalizedString(
            "Claim Domain",
            comment: "Title of button to redeem domain credit in the domain credit banner in domain settings."
        )
        static let footnote = NSLocalizedString(
            "The domain purchased will redirect users to your primary address.",
            comment: "Footnote about the domain credit banner in domain settings."
        )
    }

    enum Layout {
        static let textContainerInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let footnoteInsets: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        static let spacingBetweenTitleAndSubtitle: CGFloat = 8
        static let spacingBetweenSubtitleAndButton: CGFloat = 16
    }
}

struct DomainSettingsDomainCreditView_Previews: PreviewProvider {
    static var previews: some View {
        DomainSettingsDomainCreditView {}
    }
}
