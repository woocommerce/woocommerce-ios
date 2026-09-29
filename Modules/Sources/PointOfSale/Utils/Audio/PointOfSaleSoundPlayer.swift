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

actor PointOfSaleSoundPlayer: PointOfSaleSoundPlayerProtocol {
    private var playerCache: [PointOfSaleSound: AVAudioPlayer] = [:]

    /// Keyed by the player's identity, which is stable because every player stays in `playerCache`.
    private var completionHandlers: [ObjectIdentifier: () -> Void] = [:]

    /// `AVAudioPlayer` holds its delegate weakly, so it is retained here for the players' lifetime.
    // swiftlint:disable:next weak_delegate
    private lazy var playbackDelegate = PointOfSaleSoundPlaybackDelegate { [weak self] playerID in
        Task {
            await self?.handlePlayerFinished(playerID)
        }
    }

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
        completionHandlers[ObjectIdentifier(player)] = completion
        player.delegate = playbackDelegate
        player.currentTime = 0
        player.play()
    }

    private func handlePlayerFinished(_ playerID: ObjectIdentifier) {
        if let completion = completionHandlers.removeValue(forKey: playerID) {
            completion()
        }
    }
}

/// Receives `AVAudioPlayerDelegate` callbacks on behalf of `PointOfSaleSoundPlayer`, which as an actor cannot
/// conform to the main actor isolated delegate protocol itself. Only the player's identity is forwarded, so no
/// `AVAudioPlayer` crosses into the actor.
private final class PointOfSaleSoundPlaybackDelegate: NSObject {
    private let onFinish: @Sendable (ObjectIdentifier) -> Void

    init(onFinish: @escaping @Sendable (ObjectIdentifier) -> Void) {
        self.onFinish = onFinish
    }
}

extension PointOfSaleSoundPlaybackDelegate: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish(ObjectIdentifier(player))
    }
}
