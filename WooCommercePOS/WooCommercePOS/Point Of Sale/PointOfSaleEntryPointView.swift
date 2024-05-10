import SwiftUI

public struct PointOfSaleEntryPointView: View {
    @State private var showFullScreen = true

    @Environment(\.presentationMode) var presentationMode

    private let dependencies: PointOfSaleDependencies

    public init(showFullScreen: Bool = true,
                dependencies: PointOfSaleDependencies) {
        self.dependencies = dependencies
        self.showFullScreen = showFullScreen
    }

    public var body: some View {
        VStack {}
        .fullScreenCover(isPresented: $showFullScreen) {
            NavigationStack {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Please use iPad")
                    })
                }
                PointOfSaleDashboard(viewModel: .init(dependencies: dependencies))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Dismiss") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
            }
        }
        .onAppear {
            showFullScreen = true
            dependencies.analytics.track(.notificationReviewApprovedTapped)
        }
    }
}
