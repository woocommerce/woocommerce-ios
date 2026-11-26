import Observation

@MainActor
@Observable
final class POSGuidedAccessGuide {
    var slide: POSGuidedAccessGuideSlide
    var isVisitingSettings = false

    init(slide: POSGuidedAccessGuideSlide = .openSettings) {
        self.slide = slide
    }
}
