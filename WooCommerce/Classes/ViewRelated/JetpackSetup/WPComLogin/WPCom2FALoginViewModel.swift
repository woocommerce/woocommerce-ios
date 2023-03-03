import Foundation

/// View model for `WPCom2FALoginView`.
final class WPCom2FALoginViewModel: ObservableObject {
    @Published var otp: String

    init(requiresConnectionOnly: Bool) {}
}
