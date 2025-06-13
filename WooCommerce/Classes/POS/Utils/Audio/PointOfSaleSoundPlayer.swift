import Foundation
import AVFoundation

struct PointOfSaleSound {
    let name: String
    let type: String

    static var barcodeScanFailure: PointOfSaleSound {
        PointOfSaleSound(name: "pos_scan_failure", type: "mp3")
    }
}

protocol PointOfSaleSoundPlayerProtocol {
    func playSound(_ sound: PointOfSaleSound)
}

final class PointOfSaleSoundPlayer: PointOfSaleSoundPlayerProtocol {
    private var audioPlayer: AVAudioPlayer?

    func playSound(_ sound: PointOfSaleSound) {
        guard let url = Bundle.main.url(forResource: sound.name, withExtension: sound.type) else {
            DDLogError("Sound file not found: \(sound.name).\(sound.type)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            DDLogError("Failed to play sound: \(error)")
        }
    }
}
