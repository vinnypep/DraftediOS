import AVFoundation
import Contacts
import Foundation
import SwiftUI
import UIKit
import UserNotifications

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#if canImport(FirebaseFunctions)
import FirebaseFunctions
#endif

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
}

protocol AuthServicing {
    func signInAnonymously() async throws -> DraftUser
    func signInWithApple() async throws -> DraftUser
}

protocol DraftRepository {
    func save(_ room: DraftRoom) async throws
    func roomStream(roomID: String) -> AsyncStream<DraftRoom>
}

protocol JudgeServicing {
    func judge(room: DraftRoom) async throws -> JudgeResult
}

protocol NotificationServicing {
    func requestAuthorization() async throws -> Bool
}

protocol ContactsServicing {
    func requestAccess() async throws -> Bool
}

@MainActor
protocol MusicServicing {
    func setEnabled(_ enabled: Bool)
}

@MainActor
protocol HapticsServicing {
    func play(_ style: HapticStyle)
}

struct ServiceFactory {
    let auth: any AuthServicing
    let drafts: any DraftRepository
    let judge: any JudgeServicing
    let notifications: any NotificationServicing
    let contacts: any ContactsServicing
    let music: any MusicServicing
    let haptics: any HapticsServicing

    init(firebaseReady: Bool) {
        if firebaseReady {
            auth = FirebaseAuthService()
            drafts = FirebaseDraftRepository()
            judge = FirebaseJudgeService(fallback: MockJudgeService())
            notifications = FirebaseNotificationService()
        } else {
            auth = DemoAuthService()
            drafts = DemoDraftRepository()
            judge = MockJudgeService()
            notifications = LocalNotificationService()
        }
        contacts = SystemContactsService()
        music = AmbientMusicService()
        haptics = UIKitHapticsService()
    }
}

struct DemoAuthService: AuthServicing {
    func signInAnonymously() async throws -> DraftUser {
        DraftFixtures.currentUser
    }

    func signInWithApple() async throws -> DraftUser {
        var user = DraftFixtures.currentUser
        user.isAnonymous = false
        user.email = "apple-user@drafted.local"
        return user
    }
}

struct FirebaseAuthService: AuthServicing {
    func signInAnonymously() async throws -> DraftUser {
        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signInAnonymously()
        return DraftUser(
            id: result.user.uid,
            email: result.user.email,
            isAnonymous: result.user.isAnonymous,
            createdAt: Date()
        )
        #else
        return try await DemoAuthService().signInAnonymously()
        #endif
    }

    func signInWithApple() async throws -> DraftUser {
        // The view layer can provide an Apple credential later. Demo mode keeps the flow clickable now.
        try await DemoAuthService().signInWithApple()
    }
}

final class DemoDraftRepository: DraftRepository {
    private var rooms: [String: DraftRoom] = [:]

    func save(_ room: DraftRoom) async throws {
        rooms[room.id] = room
    }

    func roomStream(roomID: String) -> AsyncStream<DraftRoom> {
        AsyncStream { continuation in
            if let room = rooms[roomID] {
                continuation.yield(room)
            }
            continuation.finish()
        }
    }
}

final class FirebaseDraftRepository: DraftRepository {
    private let fallback = DemoDraftRepository()

    func save(_ room: DraftRoom) async throws {
        #if canImport(FirebaseFirestore)
        let encoded = try JSONEncoder().encode(room)
        let data = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] ?? [:]
        try await Firestore.firestore().collection("rooms").document(room.id).setData(data, merge: true)
        #else
        try await fallback.save(room)
        #endif
    }

    func roomStream(roomID: String) -> AsyncStream<DraftRoom> {
        #if canImport(FirebaseFirestore)
        AsyncStream { continuation in
            let listener = Firestore.firestore().collection("rooms").document(roomID).addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data(),
                      let json = try? JSONSerialization.data(withJSONObject: data),
                      let room = try? JSONDecoder().decode(DraftRoom.self, from: json) else { return }
                continuation.yield(room)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
        #else
        fallback.roomStream(roomID: roomID)
        #endif
    }
}

struct MockJudgeService: JudgeServicing {
    func judge(room: DraftRoom) async throws -> JudgeResult {
        try await Task.sleep(for: .milliseconds(850))

        let scores = room.players.map { player in
            let roster = room.picks.filter { $0.pickedByPlayerID == player.id }
            let base = 72 + min(roster.count * 5, 18)
            let stealBonus = roster.filter(\.isSteal).count * 4
            let firstPickBonus = roster.contains { $0.pickNumber == 1 } ? 3 : 0
            let score = min(99, base + stealBonus + firstPickBonus + abs(player.displayName.hashValue % 7))
            return TeamScore(
                id: player.id,
                playerID: player.id,
                playerName: player.displayName,
                score: score,
                verdict: verdict(for: score)
            )
        }
        .sorted { $0.score > $1.score }

        let winner = scores.first?.playerID ?? room.players[0].id
        let sleeper = room.picks.sorted { $0.pickNumber > $1.pickNumber }.first?.name ?? "No sleeper emerged"
        let steal = room.picks.first(where: \.isSteal)?.name ?? "No thefts, suspiciously polite"

        return JudgeResult(
            id: UUID().uuidString,
            winnerPlayerID: winner,
            headline: "\(scores.first?.playerName ?? "The room") wins the draft.",
            summary: "The AI judge liked the board control, punished a few reaches, and rewarded anyone brave enough to spend a life.",
            teamScores: scores,
            funStats: [
                FunStat(id: "sleeper", title: "Biggest Sleeper", value: sleeper, symbol: "moon.fill"),
                FunStat(id: "questionable", title: "Most Questionable", value: room.picks.dropFirst().first?.name ?? "The empty board", symbol: "questionmark.circle.fill"),
                FunStat(id: "steal", title: "Top Steal", value: steal, symbol: "bolt.fill")
            ],
            createdAt: Date()
        )
    }

    private func verdict(for score: Int) -> String {
        switch score {
        case 94...: "Dominant. Clean picks, high ceiling, zero wasted motion."
        case 88...: "Strong room control with one spicy reach."
        case 80...: "Respectable board. Needed one louder swing."
        default: "Fun, chaotic, and legally still a draft."
        }
    }
}

struct FirebaseJudgeService: JudgeServicing {
    let fallback: any JudgeServicing

    func judge(room: DraftRoom) async throws -> JudgeResult {
        #if canImport(FirebaseFunctions)
        do {
            let encoder = JSONEncoder()
            let payloadData = try encoder.encode(room)
            let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] ?? [:]
            let result = try await Functions.functions().httpsCallable("judgeDraft").call(payload)
            let data = try JSONSerialization.data(withJSONObject: result.data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(JudgeResult.self, from: data)
        } catch {
            return try await fallback.judge(room: room)
        }
        #else
        return try await fallback.judge(room: room)
        #endif
    }
}

struct LocalNotificationService: NotificationServicing {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
}

struct FirebaseNotificationService: NotificationServicing {
    func requestAuthorization() async throws -> Bool {
        let granted = try await LocalNotificationService().requestAuthorization()
        #if canImport(FirebaseMessaging)
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
                Messaging.messaging().isAutoInitEnabled = true
            }
        }
        #endif
        return granted
    }
}

struct SystemContactsService: ContactsServicing {
    func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            CNContactStore().requestAccess(for: .contacts) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

final class AmbientMusicService: MusicServicing {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false

    func setEnabled(_ enabled: Bool) {
        if enabled {
            prepareIfNeeded()
            if !engine.isRunning {
                try? engine.start()
            }
            player.play()
        } else {
            player.pause()
        }
    }

    private func prepareIfNeeded() {
        guard !isPrepared else { return }
        isPrepared = true

        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleRate * 4)) else { return }

        buffer.frameLength = buffer.frameCapacity
        let frames = Int(buffer.frameLength)
        let channels = Int(format.channelCount)

        for channel in 0..<channels {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<frames {
                let t = Double(frame) / sampleRate
                let slowPulse = 0.5 + 0.5 * sin(2.0 * .pi * 0.08 * t)
                let tone = sin(2.0 * .pi * 196.0 * t) + sin(2.0 * .pi * 246.94 * t)
                data[frame] = Float(tone * 0.008 * slowPulse)
            }
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.scheduleBuffer(buffer, at: nil, options: [.loops])
    }
}

struct UIKitHapticsService: HapticsServicing {
    func play(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
