import Yosemite

/// Encapsulates support area information from AI chat for ticket creation.
///
struct SupportAreaInfo {
    /// The original support area type from the API.
    let areaType: SupportAreaType

    /// The mapped support form area.
    let area: SupportFormViewModel.Area

    /// The confidence level of the area classification.
    let confidence: SupportAreaConfidence

    /// Full chat transcript.
    let transcript: String

    var isHighConfidence: Bool {
        confidence == .high
    }
}
