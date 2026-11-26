import Observation

@MainActor
@Observable
final class POSGuidedAccessGuide {
    var slide: POSGuidedAccessGuideSlide

    init(slide: POSGuidedAccessGuideSlide = .openSettings) {
        self.slide = slide
    }
}
