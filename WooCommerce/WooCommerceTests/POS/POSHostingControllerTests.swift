import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct POSHostingControllerTests {
    @Test func test_payment_cover_when_presented_and_dismissed_then_preserves_session() async {
        // Given
        let session = POSPresentationSession()
        var cleanupCount = 0
        session.onEnd = { cleanupCount += 1 }
        let presenter = UIViewController()
        let window = makeWindow(root: presenter)
        defer { window.isHidden = true }
        let pos = POSHostingController(rootView: Text("POS"), session: session)
        await present(pos, from: presenter)
        let payment = UIViewController()
        payment.modalPresentationStyle = .fullScreen

        // When
        await present(payment, from: pos)

        // Then
        #expect(!session.isEnded)
        #expect(cleanupCount == 0)
        await dismiss(payment)
        #expect(!session.isEnded)
        #expect(cleanupCount == 0)
        await dismiss(pos)
        #expect(session.isEnded)
        #expect(cleanupCount == 1)
    }

    @Test func test_pos_exit_when_payment_covers_pos_then_ends_session_once() async {
        // Given
        let session = POSPresentationSession()
        var cleanupCount = 0
        session.onEnd = { cleanupCount += 1 }
        let presenter = UIViewController()
        let window = makeWindow(root: presenter)
        defer { window.isHidden = true }
        let pos = POSHostingController(rootView: Text("POS"), session: session)
        await present(pos, from: presenter)
        let payment = UIViewController()
        payment.modalPresentationStyle = .fullScreen
        await present(payment, from: pos)

        // When
        await dismiss(presenter)

        // Then
        #expect(session.isEnded)
        #expect(cleanupCount == 1)
        #expect(session.onEnd == nil)
    }

    private func makeWindow(root: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = root
        window.makeKeyAndVisible()
        return window
    }

    private func present(_ controller: UIViewController, from presenter: UIViewController) async {
        await withCheckedContinuation { continuation in
            presenter.present(controller, animated: false) { continuation.resume() }
        }
    }

    private func dismiss(_ controller: UIViewController) async {
        await withCheckedContinuation { continuation in
            controller.dismiss(animated: false) { continuation.resume() }
        }
    }
}
