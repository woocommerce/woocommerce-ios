import SwiftUI

/// Owns the local access session and keeps the native PIN host mounted while the app prepares POS.
public struct POSLaunchView<Content: View>: View {
    @State private var session: POSAccessSession?
    @State private var lockSettings: POSLockSettings

    private let siteID: Int64
    private let featureFlags: POSFeatureFlagProviding
    private let isReopening: Bool
    private let registerSession: (POSExternalViewContext, @escaping () -> Void) -> Bool
    private let content: () -> Content

    public init(siteID: Int64,
                featureFlags: POSFeatureFlagProviding,
                isReopening: Bool,
                registerSession: @escaping (POSExternalViewContext, @escaping () -> Void) -> Bool,
                @ViewBuilder content: @escaping () -> Content) {
        self.siteID = siteID
        self.featureFlags = featureFlags
        self.isReopening = isReopening
        self.registerSession = registerSession
        self.content = content
        _lockSettings = State(initialValue: POSLockSettings(siteID: siteID))
    }

    public var body: some View {
        Group {
            if let session {
                POSLockScreenOverlay(session: session, locksInBackground: { lockSettings.preferences.locksInBackground }, content: content)
                    .environment(\.posAccessSession, session)
                    .environment(\.posLaunchLockSettings, lockSettings)
            } else if isReopening {
                Color.posSurfaceContainerLow.ignoresSafeArea()
            } else {
                PointOfSaleLoadingEntryPointView()
            }
        }
        .task {
            guard session == nil,
                  let created = try? await POSAccessSessionFactory.make(siteID: siteID, featureFlags: featureFlags, shouldCreate: { session == nil })
            else { return }

            let context = POSExternalViewContext(session: created)
            guard !Task.isCancelled, registerSession(context, { created.endSession() }) else {
                created.endSession()
                return
            }
            session = created
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            let activeSession = session
            Task { await activeSession?.saveElapsedTime() }
        }
    }
}

extension EnvironmentValues {
    @Entry var posLaunchLockSettings: POSLockSettings?
}
