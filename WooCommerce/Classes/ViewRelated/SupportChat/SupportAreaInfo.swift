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

    /// The support topic returned by the bot for ticket tagging.
    let topic: String?

    /// Full chat transcript.
    let transcript: String

    /// Pre-fetched system status report, if available.
    let systemStatusReport: String?

    /// Chat entry point used for analytics.
    let entryPoint: String?

    var isHighConfidence: Bool {
        confidence == .high
    }

    init(areaType: SupportAreaType,
         area: SupportFormViewModel.Area,
         confidence: SupportAreaConfidence,
         topic: String? = nil,
         transcript: String,
         systemStatusReport: String? = nil,
         entryPoint: String? = nil) {
        self.areaType = areaType
        self.area = area
        self.confidence = confidence
        self.topic = topic
        self.transcript = transcript
        self.systemStatusReport = systemStatusReport
        self.entryPoint = entryPoint
    }
}
