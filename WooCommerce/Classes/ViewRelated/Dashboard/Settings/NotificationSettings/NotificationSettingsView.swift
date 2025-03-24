import SwiftUI
import struct Yosemite.Site
import struct Yosemite.NotificationSettings

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
            switch viewModel.notificationsEnabled {
            case .none:
                ProgressView().progressViewStyle(.circular)
            case .some(true):
                notificationSettings
            case .some(false):
                notificationsDisabledView
            }
        }
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    saveSettings()
                } label: {
                    if viewModel.isSavingSettings {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text(Localization.save)
                    }
                }
                .disabled(viewModel.hasSiteSettingsChanges == false)
            }
        }
        .task {
            await viewModel.checkNotificationPermission()
            if viewModel.currentDeviceID != nil {
                await viewModel.retrieveNotificationSettings()
                await viewModel.synchronizeSites()
            }
        }
        .sheet(item: $selectedSite) { site in
            if let settings = viewModel.loadSettings(for: site) {
                SiteNotificationSettingsView(siteTitle: site.name,
                                             ordersNotificationsEnabled: settings.storeOrder,
                                             productReviewsNotificationsEnabled: settings.newComment,
                                             completionHandler: { newOrder, productReviews in
                    viewModel.updateSettings(siteID: site.siteID,
                                             ordersNotificationsEnabled: newOrder,
                                             productReviewsNotificationsEnabled: productReviews)
                })
            }
        }
        .alert(Localization.errorSavingSiteSettings, isPresented: $viewModel.savingSiteSettingsFailed) {
            Button(Localization.cancel, role: .cancel) {}
            Button(Localization.retry) {
                saveSettings()
            }
        }
        .alert(Localization.errorLoadingSiteSettings, isPresented: $viewModel.loadingSiteSettingsFailed) {
            Button(Localization.cancel, role: .cancel) {}
            Button(Localization.retry) {
                Task {
                    await viewModel.retrieveNotificationSettings()
                }
            }
        }
        .notice($viewModel.notice)
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
                if viewModel.isLoadingSiteSettings {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        .frame(maxWidth: .infinity)
                } else if viewModel.siteSettings != nil {
                    ForEach(viewModel.sites) { site in
                        detailRow(for: site)
                    }
                }
            } header: {
                Text(Localization.storeListSectionHeader)
            } footer: {
                Text(Localization.storeListSectionFooter)
            }
            .renderedIf(viewModel.shouldShowSiteList)
        }
    }

    func detailRow(for site: Site) -> some View {
        Button(action: {
            selectedSite = site
        }) {
            HStack(spacing: Layout.contentSpacing) {
                VStack(alignment: .leading) {
                    Text(site.name)
                        .bodyStyle()
                    if let settings = viewModel.loadSettings(for: site) {
                        Text(description(for: settings))
                            .foregroundStyle(Color.secondary)
                            .captionStyle()
                    }
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

    func saveSettings() {
        Task {
            await viewModel.saveSettings()
        }
    }

    func description(for settings: NotificationSettings.Device) -> String {
        switch (settings.storeOrder, settings.newComment) {
        case (true, true):
            [Localization.newOrders, Localization.productReviews].joined(separator: ", ")
        case (true, false):
            Localization.newOrders
        case (false, true):
            Localization.productReviews
        case (false, false):
            Localization.off
        }
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
        static let storeListSectionHeader = NSLocalizedString(
            "notificationSettingsView.storeListSectionHeader",
            value: "Your stores",
            comment: "Header of the store list section on the notification settings view"
        )
        static let storeListSectionFooter = NSLocalizedString(
            "notificationSettingsView.storeListSectionFooter",
            value: "Customize your notification preferences for each store.",
            comment: "Footer of the store list section on the notification settings view"
        )
        static let errorLoadingSiteSettings = NSLocalizedString(
            "notificationSettingsView.errorLoadingSiteSettings",
            value: "Unable to load notification settings for your stores.",
            comment: "Error message when loading site settings fails on the notification settings view"
        )
        static let retry = NSLocalizedString(
            "notificationSettingsView.retry",
            value: "Try again",
            comment: "Button to reload site settings on the notification settings view"
        )
        static let save = NSLocalizedString(
            "notificationSettingsView.save",
            value: "Save",
            comment: "Button to save site settings on the notification settings view"
        )
        static let cancel = NSLocalizedString(
            "notificationSettingsView.cancel",
            value: "Cancel",
            comment: "Button to cancel saving site settings on the notification settings view"
        )
        static let errorSavingSiteSettings = NSLocalizedString(
            "notificationSettingsView.errorSavingSiteSettings",
            value: "Unable to save notification settings",
            comment: "Error message when saving site settings fails on the notification settings view"
        )
        static let newOrders = NSLocalizedString(
            "notificationSettingsView.newOrders",
            value: "New orders",
            comment: "Label indicating that new orders notifications are enabled for a site on the notification settings view"
        )
        static let productReviews = NSLocalizedString(
            "notificationSettingsView.productReviews",
            value: "Product reviews",
            comment: "Label indicating that product reviews notifications are enabled for a site on the notification settings view"
        )
        static let off = NSLocalizedString(
            "notificationSettingsView.off",
            value: "Off",
            comment: "Label indicating that notifications are disabled for a site on the notification settings view"
        )
    }
}

#Preview {
    NotificationSettingsView()
}
