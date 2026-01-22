import SwiftUI

struct DebugPanelView: View {
    @State private var showUnlockPushNotificationsModal: Bool = false

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

            DebugSheetPresenter("Force show \"Unlock push notifications WP.com modal\"") {
                WPComPushNotificationsBenefitsView()
            }
        }
        .contentMargins(20)
        .navigationTitle("Debug Panel")
    }
}

fileprivate struct DebugSheetPresenter<Content: View>: View {
    private let content: () -> Content
    private let label: String
    @State private var isPresented = false

    init(_ label: String,
        @ViewBuilder content: @escaping () -> Content,
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
            content()
        }
    }
}
