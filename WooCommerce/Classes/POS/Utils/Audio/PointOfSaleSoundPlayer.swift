import Foundation
import AVFoundation

struct PointOfSaleSound: Equatable, Hashable {
    let name: String
    let type: String

    static var barcodeScanFailure: PointOfSaleSound {
        PointOfSaleSound(name: "pos_scan_failure", type: "mp3")
    }
}

protocol PointOfSaleSoundPlayerProtocol {
    func playSound(_ sound: PointOfSaleSound) async
}

actor PointOfSaleSoundPlayer: PointOfSaleSoundPlayerProtocol {
    private var playerCache: [PointOfSaleSound: AVAudioPlayer] = [:]

    func playSound(_ sound: PointOfSaleSound) async {
        guard let url = Bundle.main.url(forResource: sound.name, withExtension: sound.type) else {
            DDLogError("Sound file not found: \(sound.name).\(sound.type)")
            return
        }

        if let cachedPlayer = playerCache[sound] {
             if !cachedPlayer.isPlaying {
                 cachedPlayer.currentTime = 0
                 cachedPlayer.play()
             }
             return
         }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            playerCache[sound] = audioPlayer
        } catch {
            DDLogError("Failed to play sound: \(error)")
        }
    }
}
