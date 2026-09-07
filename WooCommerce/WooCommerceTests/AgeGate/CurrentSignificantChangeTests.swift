import Foundation
import Testing
@testable import WooCommerce

private let declaration = SignificantChangeDeclaration(
    id: "2026-terms-of-service",
    parentDescription: "The app's Terms of Service have changed.",
    blockerMessage: "We've updated the Terms of Service. Your parent or guardian needs to approve your continued use."
)
private let declaredIdentifier = SignificantChangeIdentifier.manual(id: declaration.id)
private let debugOverride = SignificantChangeIdentifier.manual(id: "debug-test-1")

struct CurrentSignificantChangeTests {
    @Test(arguments: [
        (debugOverride, declaration, debugOverride),
        (nil, declaration, declaredIdentifier),
        (nil, nil, nil)
    ] as [(SignificantChangeIdentifier?, SignificantChangeDeclaration?, SignificantChangeIdentifier?)])
    func activeManualChangeIdentifier_when_resolved_then_debug_override_wins_over_declaration(
        debugOverride: SignificantChangeIdentifier?,
        declaration: SignificantChangeDeclaration?,
        expected: SignificantChangeIdentifier?
    ) {
        #expect(CurrentSignificantChange.activeManualChangeIdentifier(debugOverride: debugOverride, declaration: declaration) == expected)
    }

    @Test(arguments: [
        (declaredIdentifier, declaration, declaration),
        (debugOverride, declaration, nil),
        (.ageRatingChange(ratingCode: 13), declaration, nil),
        (declaredIdentifier, nil, nil)
    ] as [(SignificantChangeIdentifier, SignificantChangeDeclaration?, SignificantChangeDeclaration?)])
    func declaration_matching_when_resolved_then_returns_declaration_only_for_its_own_manual_id(
        identifier: SignificantChangeIdentifier,
        declaration: SignificantChangeDeclaration?,
        expected: SignificantChangeDeclaration?
    ) {
        #expect(CurrentSignificantChange.declaration(matching: identifier, declaration: declaration) == expected)
    }

    @Test(arguments: [
        (nil, declaration, declaration),
        (debugOverride, declaration, nil),
        (nil, nil, nil)
    ] as [(SignificantChangeIdentifier?, SignificantChangeDeclaration?, SignificantChangeDeclaration?)])
    func activeDeclaration_when_resolved_then_is_hidden_by_a_debug_override(
        debugOverride: SignificantChangeIdentifier?,
        declaration: SignificantChangeDeclaration?,
        expected: SignificantChangeDeclaration?
    ) {
        #expect(CurrentSignificantChange.activeDeclaration(debugOverride: debugOverride, declaration: declaration) == expected)
    }
}
