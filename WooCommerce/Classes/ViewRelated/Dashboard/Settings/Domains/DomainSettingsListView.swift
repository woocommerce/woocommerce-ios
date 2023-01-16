import SwiftUI

/// Shows a list of domains in domain settings with a CTA to add a domain.
struct DomainSettingsListView: View {
    let domains: [DomainSettingsViewModel.Domain]
    let addDomain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.header.uppercased())
                .padding(Layout.headerPadding)
                .foregroundColor(Color(.secondaryLabel))
                .captionStyle()

            ForEach(domains, id: \.name) { domain in
                VStack(alignment: .leading) {
                    Text(domain.name)
                    if let renewalDate = domain.autoRenewalDate {
                        Text(String(format: Localization.renewalDateFormat, renewalDate.toString(dateStyle: .medium, timeStyle: .none)))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(Layout.domainPadding)
                Divider()
                    .dividerStyle()
                    .padding(Layout.dividerPadding)
            }

            Button(Localization.addDomain) {
                addDomain()
            }
            .padding(Layout.actionButtonPadding)
            .buttonStyle(PlusButtonStyle())

            Divider()
                .dividerStyle()
                .padding(Layout.dividerPadding)
        }
    }
}

private extension DomainSettingsListView {
    enum Localization {
        static let header = NSLocalizedString(
            "Your site domains",
            comment: "Header text of the site's domain list in domain settings."
        )
        static let renewalDateFormat = NSLocalizedString(
            "Renews on %1$@",
            comment: "Renewal date of a site's domain in domain settings. " +
            "Reads like `Renews on October 11, 2023`."
        )
        static let addDomain = NSLocalizedString(
            "Add a domain",
            comment: "Title of button to add a domain in domain settings."
        )
    }

    enum Layout {
        static let headerPadding: EdgeInsets = .init(top: 18, leading: 16, bottom: 6, trailing: 16)
        static let domainPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let actionButtonPadding: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 23)
        static let dividerPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 0)
    }
}

struct DomainSettingsListView_Previews: PreviewProvider {
    static var previews: some View {
        DomainSettingsListView(domains: [
            .init(isPrimary: true, name: "play.store", autoRenewalDate: .distantFuture),
            .init(isPrimary: false, name: "app.store", autoRenewalDate: nil),
            .init(isPrimary: false, name: "woo.store", autoRenewalDate: .now)
        ], addDomain: {})
    }
}
