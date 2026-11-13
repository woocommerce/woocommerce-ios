import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct TotalsViewBottomControlsLayoutTests {
    private let paneSize = CGSize(width: 400, height: 600)
    private let maxHeight: CGFloat = 300

    @Test func test_scrollVerticallyWhenTaller_when_controls_are_hidden_then_takes_no_height() {
        // Given
        let controls = bottomControls(height: nil).scrollVerticallyWhenTaller(than: maxHeight)

        // When
        let height = fittingHeight(of: controls)

        // Then
        #expect(height == 0)
    }

    @Test func test_scrollVerticallyWhenTaller_when_controls_are_shorter_than_maxHeight_then_keeps_their_height() {
        // Given
        let controls = bottomControls(height: 150).scrollVerticallyWhenTaller(than: maxHeight)

        // When
        let height = fittingHeight(of: controls)

        // Then
        #expect(height == 150)
    }

    @Test func test_scrollVerticallyWhenTaller_when_controls_are_taller_than_maxHeight_then_scrolls_inside_maxHeight() {
        // Given
        let controls = bottomControls(height: 500).scrollVerticallyWhenTaller(than: maxHeight)

        // When
        let height = fittingHeight(of: controls)

        // Then: the scrolling candidate takes the cap. Without it the controls would keep their 500 points.
        #expect(height == maxHeight)
    }
}

private extension TotalsViewBottomControlsLayoutTests {
    /// Same shape as `TotalsView.bottomControls`: a view builder that has no views when the controls are hidden.
    @ViewBuilder
    func bottomControls(height: CGFloat?) -> some View {
        if let height {
            Color.clear.frame(height: height)
        } else {
            EmptyView()
        }
    }

    func fittingHeight(of view: some View) -> CGFloat {
        UIHostingController(rootView: view).sizeThatFits(in: paneSize).height
    }
}
