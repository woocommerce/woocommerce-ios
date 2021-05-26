import AVFoundation
import UIKit

/// Plays a sound and provides taptic feedback when a payment capture has been completed successfully
/// https://www.youtube.com/watch?v=ewRjZoRtu0Y
final class PaymentCaptureCelebration: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private var hapticGenerator: UINotificationFeedbackGenerator? = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        return generator
    }()

    func celebrate() {
        playSound()
        shakeDevice()
    }
}

private extension PaymentCaptureCelebration {
    func playSound() {
        guard let path = Bundle.main.path(forResource: "o.caf", ofType: nil) else {
            return
        }

        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            DDLogError("Error: failed to play sound on payment capture completion")
        }

    }

    func shakeDevice() {
        hapticGenerator?.notificationOccurred(.success)
    }
}


extension PaymentCaptureCelebration: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        hapticGenerator = nil
    }
}
