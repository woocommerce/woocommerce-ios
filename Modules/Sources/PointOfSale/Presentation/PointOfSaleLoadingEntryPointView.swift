import SwiftUI

/// Public entry point for the POS loading screen so the app target can present
/// POS immediately while app-target dependencies finish resolving.
public struct PointOfSaleLoadingEntryPointView: View {
    public init() {}

    public var body: some View {
        PointOfSaleLoadingView()
            .ignoresSafeArea()
    }
}
