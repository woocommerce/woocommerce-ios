import SwiftUI
import Yosemite

struct DebugPanelView: View {
    @State private var announcementToPresent: Announcement?
    @State private var announcementError: String?

    @State private var minimumWooVersionOverride: String = UserDefaults.standard[.debugMinWooVersionForSelfDrivenPushNotifications] ?? ""

    var body: some View {
        List {
            Button {
                UserDefaults.standard[.hasSavedPrivacyBannerSettings] = false
            } label: {
                Text("Reset Privacy Choice Banner State")
            }

            Button {
                ServiceLocator.storageManager.reset {
                    ServiceLocator.noticePresenter.enqueue(notice: Notice(title: "CoreData storage cleared"))
                }
            } label: {
                Text("Clear CoreData Storage")
            }

            Button {
                ServiceLocator.crashLogging.crash()
            } label: {
                Text("Crash Immediately")
            }

            NavigationLink(destination: OverrideFeatureFlagsView()) {
                Text("Override Feature Flags")
            }

            Section("Announcements") {
                Button("Fetch Test Announcement (v999.0)") {
                    fetchTestAnnouncement()
                }

                Button("Reset Announcement State") {
                    resetAnnouncementState()
                }
            }

            if let error = announcementError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading) {
                Text("Minimum Woo Version for self-driven push notifications")
                    .frame(maxWidth: .infinity)
                TextField("e.g. 10.5.3", text: $minimumWooVersionOverride)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: minimumWooVersionOverride) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        UserDefaults.standard[.debugMinWooVersionForSelfDrivenPushNotifications] = trimmed.isEmpty ? nil : trimmed
                    }
            }

            if let site = ServiceLocator.stores.sessionManager.defaultSite {
                DebugSheetPresenter("Present WPComConnectionSetupView") { dismiss in
                    let viewModel = WPComConnectionSetupViewModel(
                        storeName: "nicestore.com",
                        handler: WPComConnectionSetupHandler(
                            siteID: site.siteID,
                            siteURL: site.url,
                            siteAlreadyConnected: false
                        ),
                        onDismiss: dismiss,
                        onGoToStore: dismiss,
                        onUpdatePlugin: { _ in }
                    )
                    WPComConnectionSetupView(viewModel: viewModel)
                }
            }
        }
        .contentMargins(20)
        .navigationTitle("Debug Panel")
        .sheet(item: $announcementToPresent) { announcement in
            ViewControllerContainer(WhatsNewFactory.whatsNew(announcement) {
                announcementToPresent = nil
            })
            .ignoresSafeArea()
        }
    }

    private func fetchTestAnnouncement() {
        announcementError = nil
        let action = AnnouncementsAction.synchronizeAnnouncementsForDebug(appVersion: "999.0") { result in
            switch result {
            case .success(let announcement):
                announcementToPresent = announcement
            case .failure:
                announcementError = "Failed to fetch announcement"
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    private func resetAnnouncementState() {
        announcementError = nil
        let action = AnnouncementsAction.deleteSavedAnnouncement { _ in }
        ServiceLocator.stores.dispatch(action)
    }
}

fileprivate struct DebugSheetPresenter<Content: View>: View {
    private let content: (@escaping () -> Void) -> Content
    private let label: String
    @State private var isPresented = false

    init(_ label: String,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
    ) {
        self.label = label
        self.content = content
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Text(label)
        }
        .sheet(isPresented: $isPresented) {
            content { isPresented = false }
        }
    }
}
