import SwiftUI
import Yosemite

struct DebugPanelView: View {
    @State private var announcementToPresent: Announcement?
    @State private var announcementError: String?

    var body: some View {
        List {
            Button {
                UserDefaults.standard[.hasSavedPrivacyBannerSettings] = false
            } label: {
                Text("Reset Privacy Choice Banner State")
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
            case .failure(let error):
                announcementError = "Failed to fetch announcement: \(error.localizedDescription)"
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    private func resetAnnouncementState() {
        announcementError = nil
        let action = AnnouncementsAction.deleteSavedAnnouncement { result in
            switch result {
            case .success:
                announcementError = nil
            case .failure(let error):
                announcementError = "Failed to reset: \(error.localizedDescription)"
            }
        }
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
