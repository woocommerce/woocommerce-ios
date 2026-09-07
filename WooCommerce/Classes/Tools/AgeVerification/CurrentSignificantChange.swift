import Foundation

/// A developer-declared significant change requiring renewed parental consent, with its user-facing copy.
/// Both texts are required, so a raw id can never reach a parent.
struct SignificantChangeDeclaration: Equatable {
    /// Stable id; consent is persisted per id, so a new change needs a new id.
    let id: String
    /// Short summary Apple shows in the parent/guardian consent request.
    let parentDescription: String
    /// Longer explanation shown on the in-app "Approval Needed" screen.
    let blockerMessage: String
}

/// The single place to declare a real significant change for a release.
///
/// Normally `nil`: age rating increases are detected automatically. Set it when Legal deems a change
/// (e.g. new Terms of Service) significant despite an unchanged rating; allow one release cycle of
/// lead time for copy review and localization, and remove it once consent has been collected.
///
/// Example:
///
///     static let declaration: SignificantChangeDeclaration? = SignificantChangeDeclaration(
///         id: "2026-10-terms-of-service",
///         parentDescription: NSLocalizedString(
///             "significantChange.2026TermsOfService.parentDescription",
///             value: "The app's Terms of Service have changed.",
///             comment: "Description a parent or guardian sees in the system consent request for the updated Terms of Service."
///         ),
///         blockerMessage: NSLocalizedString(
///             "significantChange.2026TermsOfService.blockerMessage",
///             value: "We've updated the Terms of Service for this app. Because of these changes, " +
///                 "your parent or guardian needs to approve your continued use of the app.",
///             comment: "Message on the in-app Approval Needed screen for the updated Terms of Service."
///         )
///     )
enum CurrentSignificantChange {
    static let declaration: SignificantChangeDeclaration? = nil

    /// The manual change in effect: the Debug Panel override wins over the release declaration.
    static func activeManualChangeIdentifier(
        debugOverride: SignificantChangeIdentifier? = DebugAgeVerificationOverrides.manualSignificantChangeIdentifier,
        declaration: SignificantChangeDeclaration? = Self.declaration
    ) -> SignificantChangeIdentifier? {
        if let debugOverride { return debugOverride }
        return declaration.map { .manual(id: $0.id) }
    }

    /// The declaration behind a manual identifier; `nil` for debug-tool ids.
    static func declaration(
        matching identifier: SignificantChangeIdentifier,
        declaration: SignificantChangeDeclaration? = Self.declaration
    ) -> SignificantChangeDeclaration? {
        guard let declaration, case let .manual(id) = identifier, id == declaration.id else {
            return nil
        }
        return declaration
    }

    /// The declaration driving the consent flow, unless a debug override shadows it.
    static func activeDeclaration(
        debugOverride: SignificantChangeIdentifier? = DebugAgeVerificationOverrides.manualSignificantChangeIdentifier,
        declaration: SignificantChangeDeclaration? = Self.declaration
    ) -> SignificantChangeDeclaration? {
        guard let identifier = activeManualChangeIdentifier(debugOverride: debugOverride, declaration: declaration) else {
            return nil
        }
        return Self.declaration(matching: identifier, declaration: declaration)
    }
}
