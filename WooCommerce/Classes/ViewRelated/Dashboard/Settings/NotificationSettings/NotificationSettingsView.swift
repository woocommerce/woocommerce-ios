import SwiftUI
import struct Yosemite.Site

final class NotificationSettingsHostingController: UIHostingController<NotificationSettingsView> {
    init() {
        super.init(rootView: NotificationSettingsView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NotificationSettingsView.Localization.title
    }
}

struct NotificationSettingsView: View {
    @StateObject private var viewModel: NotificationSettingsViewModel
    @State private var selectedSite: Site?

    init() {
        self._viewModel = StateObject(wrappedValue: NotificationSettingsViewModel())
    }

    var body: some View {
        Group {
            if viewModel.notificationsEnabled {
                notificationSettings
            } else {
                notificationsDisabledView
            }
        }
        .navigationTitle(Localization.title)
        .task {
            await viewModel.synchronizeSites()
        }
        .sheet(item: $selectedSite) { site in
            SiteNotificationSettingsView(siteTitle: site.name)
        }
    }
}

private extension NotificationSettingsView {
    var notificationsDisabledView: some View {
        VStack(spacing: Layout.contentSpacing) {
            Spacer()

            Image(uiImage: .bellIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.emptyStateImageWidth)

            Text(Localization.notificationsDisabled)

            Button(Localization.enableNotificationsCTA) {
                Task {
                    await openSettingsApp()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .scrollVerticallyIfNeeded()
        .padding(.horizontal)
    }

    var notificationSettings: some View {
        List {
            Section {
                HStack {
                    Text(Localization.notificationsEnabled)
                    Spacer()
                    Button(Localization.settingsAppCTA) {
                        Task {
                            await openSettingsApp()
                        }
                    }
                }
            } footer: {
                Text(Localization.notificationsFooter)
            }

            Section {
                ForEach(viewModel.sites) { site in
                    siteRow(for: site)
                }
            } header: {
                Text(Localization.siteListSectionHeader)
            } footer: {
                Text(Localization.siteListSectionFooter)
            }
        }
    }

    func siteRow(for site: Site) -> some View {
        Button(action: {
            selectedSite = site
        }) {
            HStack(spacing: Layout.contentSpacing) {
                VStack(alignment: .leading) {
                    Text(site.name)
                        .bodyStyle()
                    Text(site.url)
                        .foregroundStyle(Color.secondary)
                        .captionStyle()
                }
                .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.forward")
                    .secondaryBodyStyle()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func openSettingsApp() async {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        // Ask the system to open that URL.
        await UIApplication.shared.open(url)
    }
}

extension NotificationSettingsView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
        static let emptyStateImageWidth: CGFloat = 120
    }

    enum Localization {
        static let title = NSLocalizedString(
            "notificationSettingsView.title",
            value: "Notification Settings",
            comment: "Title of the notification settings view"
        )
        static let notificationsDisabled = NSLocalizedString(
            "notificationSettingsView.notificationsDisabled",
            value: "Notifications are disabled for Woo",
            comment: "Label indicating notifications are disabled on the notification settings view"
        )
        static let enableNotificationsCTA = NSLocalizedString(
            "notificationSettingsView.enableNotificationsCTA",
            value: "Enable notifications",
            comment: "Button to enable notifications on the notification settings view"
        )
        static let notificationsEnabled = NSLocalizedString(
            "notificationSettingsView.notificationsEnabled",
            value: "Notifications enabled",
            comment: "Label indicating notifications are enabled on the notification settings view"
        )
        static let settingsAppCTA = NSLocalizedString(
            "notificationSettingsView.settingsAppCTA",
            value: "Change",
            comment: "Button to open the app's notification settings in the Settings app"
        )
        static let notificationsFooter = NSLocalizedString(
            "notificationSettingsView.notificationsFooter",
            value: "Including reminders and remote push notifications.",
            comment: "Footer of the notifications section on the notification settings view"
        )
        static let siteListSectionHeader = NSLocalizedString(
            "notificationSettingsView.siteListSectionHeader",
            value: "Your sites",
            comment: "Header of the site list section on the notification settings view"
        )
        static let siteListSectionFooter = NSLocalizedString(
            "notificationSettingsView.siteListSectionFooter",
            value: "Customize your notification preferences for new orders and product reviews.",
            comment: "Footer of the site list section on the notification settings view"
        )
    }
}

#Preview {
    NotificationSettingsView()
}
