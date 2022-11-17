import Foundation

/// View model for `SiteCredentialLoginView`.
///
final class SiteCredentialLoginViewModel: ObservableObject {
    let siteURL: String

    @Published var username: String = ""
    @Published var password: String = ""
    @Published private(set) var primaryButtonDisabled = true

    init(siteURL: String) {
        self.siteURL = siteURL
        configurePrimaryButton()
    }
}

private extension SiteCredentialLoginViewModel {
    func configurePrimaryButton() {
        $username.combineLatest($password)
            .map { $0.isEmpty || $1.isEmpty }
            .assign(to: &$primaryButtonDisabled)
    }
}
