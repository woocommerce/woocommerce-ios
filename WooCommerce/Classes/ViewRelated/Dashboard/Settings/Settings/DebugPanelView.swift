import SwiftUI

struct DebugPanelView: View {

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

            DebugSheetPresenter("Present WPComConnectionSetupView") { dismiss in
                let handler = PreviewConnectionSetupHandler()
                let viewModel = WPComConnectionSetupViewModel(
                    storeName: "nicestore.com",
                    handler: handler,
                    onDismiss: dismiss,
                    onGoToStore: dismiss,
                    onUpdatePlugin: {}
                )
                WPComConnectionSetupView(viewModel: viewModel)
            }
        }
        .contentMargins(20)
        .navigationTitle("Debug Panel")
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

/// A preview handler that simulates the connection setup flow
private final class PreviewConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    func start() {
        // Simulate a successful flow with delays
        Task { @MainActor in
            delegate?.stepDidUpdate(.connect, status: .running)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            delegate?.stepDidUpdate(.connect, status: .success)

            delegate?.stepDidUpdate(.checkPlugin, status: .running)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            delegate?.stepDidUpdate(.checkPlugin, status: .success)

            delegate?.setupDidComplete()
        }
    }

    func retry() {
        start()
    }

    func cancel() {}
}
