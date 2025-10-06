import CocoaLumberjackSwift
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

actor PointOfSaleSoundPlayer: NSObject, PointOfSaleSoundPlayerProtocol {
    private var playerCache: [PointOfSaleSound: AVAudioPlayer] = [:]
    private var completionHandlers: [AVAudioPlayer: () -> Void] = [:]

    func playSound(_ sound: PointOfSaleSound) async {
        await playSound(sound, completion: {})
    }

    func playSound(_ sound: PointOfSaleSound, completion: @escaping (() -> Void)) async {
        guard let url = Bundle.module.url(forResource: sound.name, withExtension: sound.type) else {
            DDLogError("Sound file not found: \(sound.name).\(sound.type)")
            completion()
            return
        }

        if let cachedPlayer = playerCache[sound] {
             if !cachedPlayer.isPlaying {
                 play(cachedPlayer, completion: completion)
             } else {
                 completion()
             }
             return
         }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            play(audioPlayer, completion: completion)
            playerCache[sound] = audioPlayer
        } catch {
            DDLogError("Failed to play sound: \(error)")
            completion()
        }
    }

    private func play(_ player: AVAudioPlayer, completion: @escaping (() -> Void)) {
        completionHandlers[player] = completion
        player.delegate = self
        player.currentTime = 0
        player.play()
    }
}

extension PointOfSaleSoundPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            await handlePlayerFinished(player)
        }
    }

    private func handlePlayerFinished(_ player: AVAudioPlayer) {
        if let completion = completionHandlers[player] {
            completionHandlers.removeValue(forKey: player)
            completion()
        }
    }
}
