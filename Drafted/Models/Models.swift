import Foundation

struct DraftUser: Identifiable, Codable, Hashable {
    var id: String
    var email: String?
    var isAnonymous: Bool
    var createdAt: Date
}

struct DraftProfile: Identifiable, Codable, Hashable {
    var id: String
    var username: String
    var avatarPreset: String
    var avatarImageData: Data?
    var level: Int
    var xp: Int
    var xpForNextLevel: Int
    var signInProvider: SignInProvider
}

enum SignInProvider: String, Codable, Hashable {
    case anonymous
    case apple
}

struct DraftCategory: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var symbol: String
    var tags: [CategorySection]
}

enum CategorySection: String, Codable, Hashable, CaseIterable, Identifiable {
    case trending
    case popular
    case friends
    case new

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trending: "Trending"
        case .popular: "Most Popular"
        case .friends: "For Friends"
        case .new: "New"
        }
    }
}

struct DraftRoom: Identifiable, Codable, Hashable {
    var id: String
    var code: String
    var category: DraftCategory
    var rounds: Int
    var maxPlayers: Int
    var mode: DraftMode
    var status: RoomStatus
    var ownerID: String
    var currentPickIndex: Int
    var players: [DraftPlayer]
    var picks: [DraftPick]
    var trades: [TradeOffer]
    var reactions: [EmojiReaction]
    var result: JudgeResult?
    var createdAt: Date
}

enum DraftMode: String, Codable, Hashable, CaseIterable, Identifiable {
    case live
    case async

    var id: String { rawValue }
    var title: String { self == .live ? "Live" : "Async" }
}

enum RoomStatus: String, Codable, Hashable {
    case lobby
    case drafting
    case judging
    case completed
}

struct DraftPlayer: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var avatarPreset: String
    var lives: Int
    var isReady: Bool

    init(userID: String, displayName: String, avatarPreset: String, lives: Int = 3, isReady: Bool = true) {
        self.id = userID
        self.displayName = displayName
        self.avatarPreset = avatarPreset
        self.lives = lives
        self.isReady = isReady
    }
}

struct DraftPick: Identifiable, Codable, Hashable {
    var id: String
    var itemID: String
    var name: String
    var detail: String
    var imageSystemName: String
    var pickedByPlayerID: String
    var round: Int
    var pickNumber: Int
    var stolenFromPlayerID: String?
    var isSteal: Bool
    var createdAt: Date
}

struct DraftPickOption: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var detail: String
    var imageSystemName: String
}

struct TradeOffer: Identifiable, Codable, Hashable {
    var id: String
    var fromPlayerID: String
    var toPlayerID: String
    var offeredPickID: String?
    var requestedPickID: String?
    var status: TradeStatus
    var createdAt: Date
}

enum TradeStatus: String, Codable, Hashable {
    case pending
    case accepted
    case declined
}

struct EmojiReaction: Identifiable, Codable, Hashable {
    var id: String
    var playerID: String
    var emoji: String
    var createdAt: Date
}

struct JudgeResult: Identifiable, Codable, Hashable {
    var id: String
    var winnerPlayerID: String
    var headline: String
    var summary: String
    var teamScores: [TeamScore]
    var funStats: [FunStat]
    var createdAt: Date
}

struct TeamScore: Identifiable, Codable, Hashable {
    var id: String
    var playerID: String
    var playerName: String
    var score: Int
    var verdict: String
}

struct FunStat: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var value: String
    var symbol: String
}

struct ActivityItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var symbol: String
    var createdAt: Date
}

enum DraftError: LocalizedError, Equatable {
    case notDrafting
    case notPlayersTurn
    case duplicatePick
    case pickNotFound
    case playerNotFound
    case noLivesRemaining
    case cannotStealOwnPick

    var errorDescription: String? {
        switch self {
        case .notDrafting: "This draft is not currently active."
        case .notPlayersTurn: "It is not this player's turn."
        case .duplicatePick: "That pick has already been drafted."
        case .pickNotFound: "That pick could not be found."
        case .playerNotFound: "That player could not be found."
        case .noLivesRemaining: "No lives remaining."
        case .cannotStealOwnPick: "You already own that pick."
        }
    }
}

