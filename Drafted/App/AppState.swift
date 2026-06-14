import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var currentUser: DraftUser
    var profile: DraftProfile
    var didCompleteOnboarding: Bool
    var selectedTab: AppTab = .home
    var categories: [DraftCategory]
    var activeRooms: [DraftRoom]
    var historyRooms: [DraftRoom]
    var activity: [ActivityItem]
    var musicEnabled = false
    var hapticsEnabled = true
    var lastError: String?
    let isFirebaseConfigured: Bool

    private let authService: any AuthServicing
    private let draftRepository: any DraftRepository
    private let judgeService: any JudgeServicing
    private let notificationService: any NotificationServicing
    private let contactsService: any ContactsServicing
    private let musicService: any MusicServicing
    private let hapticsService: any HapticsServicing

    init(
        currentUser: DraftUser,
        profile: DraftProfile,
        didCompleteOnboarding: Bool,
        categories: [DraftCategory],
        activeRooms: [DraftRoom],
        historyRooms: [DraftRoom],
        activity: [ActivityItem],
        isFirebaseConfigured: Bool,
        authService: any AuthServicing,
        draftRepository: any DraftRepository,
        judgeService: any JudgeServicing,
        notificationService: any NotificationServicing,
        contactsService: any ContactsServicing,
        musicService: any MusicServicing,
        hapticsService: any HapticsServicing
    ) {
        self.currentUser = currentUser
        self.profile = profile
        self.didCompleteOnboarding = didCompleteOnboarding
        self.categories = categories
        self.activeRooms = activeRooms
        self.historyRooms = historyRooms
        self.activity = activity
        self.isFirebaseConfigured = isFirebaseConfigured
        self.authService = authService
        self.draftRepository = draftRepository
        self.judgeService = judgeService
        self.notificationService = notificationService
        self.contactsService = contactsService
        self.musicService = musicService
        self.hapticsService = hapticsService
    }

    static func bootstrap() -> AppModel {
        let firebaseReady = FirebaseBootstrap.hasGoogleServiceInfo
        let user = DraftFixtures.currentUser
        let profile = DraftFixtures.profile
        let serviceFactory = ServiceFactory(firebaseReady: firebaseReady)

        return AppModel(
            currentUser: user,
            profile: profile,
            didCompleteOnboarding: false,
            categories: DraftFixtures.categories,
            activeRooms: [],
            historyRooms: DraftFixtures.historyRooms,
            activity: DraftFixtures.activity,
            isFirebaseConfigured: firebaseReady,
            authService: serviceFactory.auth,
            draftRepository: serviceFactory.drafts,
            judgeService: serviceFactory.judge,
            notificationService: serviceFactory.notifications,
            contactsService: serviceFactory.contacts,
            musicService: serviceFactory.music,
            hapticsService: serviceFactory.haptics
        )
    }

    func completeOnboarding() {
        tap()
        didCompleteOnboarding = true
    }

    func tap(_ style: HapticStyle = .light) {
        guard hapticsEnabled else { return }
        hapticsService.play(style)
    }

    func requestNotifications() async {
        do {
            _ = try await notificationService.requestAuthorization()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func requestContacts() async {
        do {
            _ = try await contactsService.requestAccess()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func toggleMusic() {
        musicEnabled.toggle()
        musicService.setEnabled(musicEnabled)
        tap(.medium)
    }

    func toggleHaptics() {
        hapticsEnabled.toggle()
        if hapticsEnabled {
            hapticsService.play(.medium)
        }
    }

    func signInAnonymously() async {
        do {
            currentUser = try await authService.signInAnonymously()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func signInWithApple() async {
        do {
            currentUser = try await authService.signInWithApple()
            profile.signInProvider = .apple
            tap(.success)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func category(id: String?) -> DraftCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    func room(id: String) -> DraftRoom? {
        activeRooms.first { $0.id == id } ?? historyRooms.first { $0.id == id }
    }

    func createRoom(category: DraftCategory, rounds: Int, maxPlayers: Int, mode: DraftMode) -> DraftRoom {
        tap(.medium)

        var players = DraftFixtures.demoPlayers(owner: currentUser, profile: profile)
        players = Array(players.prefix(maxPlayers))
        let room = DraftRoom(
            id: UUID().uuidString,
            code: RoomCodeGenerator.generate(),
            category: category,
            rounds: rounds,
            maxPlayers: maxPlayers,
            mode: mode,
            status: .drafting,
            ownerID: currentUser.id,
            currentPickIndex: 0,
            players: players,
            picks: [],
            trades: [],
            reactions: [],
            result: nil,
            createdAt: Date()
        )
        activeRooms.insert(room, at: 0)
        Task { try? await draftRepository.save(room) }
        return room
    }

    func joinRoom(code: String) -> DraftRoom {
        tap(.medium)
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if let existing = activeRooms.first(where: { $0.code == normalizedCode || $0.code.replacingOccurrences(of: "-", with: "") == normalizedCode }) {
            return existing
        }

        var room = DraftFixtures.demoRoom(
            category: categories.first ?? DraftFixtures.categories[0],
            owner: currentUser,
            profile: profile
        )
        room.code = normalizedCode.isEmpty ? RoomCodeGenerator.generate() : normalizedCode
        activeRooms.insert(room, at: 0)
        return room
    }

    @discardableResult
    func makePick(roomID: String, option: DraftPickOption) -> RoomStatus? {
        tap(.medium)

        guard let index = activeRooms.firstIndex(where: { $0.id == roomID }) else { return nil }
        guard DraftEngine.currentTurnPlayerID(in: activeRooms[index]) == currentUser.id else {
            lastError = "It is not your turn yet."
            return activeRooms[index].status
        }

        do {
            try DraftEngine.makePick(option, by: currentUser.id, in: &activeRooms[index])
            autoDraftOpponents(in: index)
            Task { try? await draftRepository.save(activeRooms[index]) }
            return activeRooms[index].status
        } catch {
            lastError = error.localizedDescription
            return activeRooms[index].status
        }
    }

    func stealPick(roomID: String, pickID: String) {
        tap(.heavy)
        guard let index = activeRooms.firstIndex(where: { $0.id == roomID }) else { return }

        do {
            try DraftEngine.stealPick(pickID: pickID, by: currentUser.id, in: &activeRooms[index])
        } catch {
            lastError = error.localizedDescription
        }
    }

    func proposeTrade(roomID: String, targetPlayerID: String) {
        tap(.medium)
        guard let index = activeRooms.firstIndex(where: { $0.id == roomID }) else { return }
        let trade = TradeOffer(
            id: UUID().uuidString,
            fromPlayerID: currentUser.id,
            toPlayerID: targetPlayerID,
            offeredPickID: activeRooms[index].picks.last(where: { $0.pickedByPlayerID == currentUser.id })?.id,
            requestedPickID: activeRooms[index].picks.last(where: { $0.pickedByPlayerID == targetPlayerID })?.id,
            status: .pending,
            createdAt: Date()
        )
        activeRooms[index].trades.insert(trade, at: 0)
    }

    func acceptTrade(roomID: String, tradeID: String) {
        tap(.success)
        guard let roomIndex = activeRooms.firstIndex(where: { $0.id == roomID }),
              let tradeIndex = activeRooms[roomIndex].trades.firstIndex(where: { $0.id == tradeID }) else { return }

        var trade = activeRooms[roomIndex].trades[tradeIndex]
        trade.status = .accepted
        activeRooms[roomIndex].trades[tradeIndex] = trade

        guard
            let offeredID = trade.offeredPickID,
            let requestedID = trade.requestedPickID,
            let offeredIndex = activeRooms[roomIndex].picks.firstIndex(where: { $0.id == offeredID }),
            let requestedIndex = activeRooms[roomIndex].picks.firstIndex(where: { $0.id == requestedID })
        else { return }

        let offeredOwner = activeRooms[roomIndex].picks[offeredIndex].pickedByPlayerID
        activeRooms[roomIndex].picks[offeredIndex].pickedByPlayerID = activeRooms[roomIndex].picks[requestedIndex].pickedByPlayerID
        activeRooms[roomIndex].picks[requestedIndex].pickedByPlayerID = offeredOwner
    }

    func addReaction(roomID: String, emoji: String) {
        tap()
        guard let index = activeRooms.firstIndex(where: { $0.id == roomID }) else { return }
        activeRooms[index].reactions.insert(
            EmojiReaction(id: UUID().uuidString, playerID: currentUser.id, emoji: emoji, createdAt: Date()),
            at: 0
        )
        activeRooms[index].reactions = Array(activeRooms[index].reactions.prefix(8))
    }

    func judge(roomID: String) async {
        guard let index = activeRooms.firstIndex(where: { $0.id == roomID }) else { return }
        activeRooms[index].status = .judging

        do {
            let result = try await judgeService.judge(room: activeRooms[index])
            activeRooms[index].result = result
            activeRooms[index].status = .completed
            let completed = activeRooms.remove(at: index)
            historyRooms.insert(completed, at: 0)
            tap(.success)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func forceRejudge(roomID: String) async {
        if let activeIndex = activeRooms.firstIndex(where: { $0.id == roomID }) {
            spendLife(in: &activeRooms[activeIndex])
            activeRooms[activeIndex].result = nil
            await judge(roomID: roomID)
            return
        }

        guard let historyIndex = historyRooms.firstIndex(where: { $0.id == roomID }) else { return }
        spendLife(in: &historyRooms[historyIndex])
        do {
            let result = try await judgeService.judge(room: historyRooms[historyIndex])
            historyRooms[historyIndex].result = result
            tap(.success)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func rematch(roomID: String) -> DraftRoom? {
        guard let oldRoom = room(id: roomID) else { return nil }
        tap(.medium)
        var rematch = DraftRoom(
            id: UUID().uuidString,
            code: RoomCodeGenerator.generate(),
            category: oldRoom.category,
            rounds: oldRoom.rounds,
            maxPlayers: oldRoom.maxPlayers,
            mode: oldRoom.mode,
            status: .drafting,
            ownerID: currentUser.id,
            currentPickIndex: 0,
            players: oldRoom.players.map { player in
                var copy = player
                copy.lives = 3
                return copy
            },
            picks: [],
            trades: [],
            reactions: [],
            result: nil,
            createdAt: Date()
        )
        if !rematch.players.contains(where: { $0.id == currentUser.id }) {
            rematch.players.insert(DraftPlayer(userID: currentUser.id, displayName: profile.username, avatarPreset: profile.avatarPreset), at: 0)
        }
        activeRooms.insert(rematch, at: 0)
        return rematch
    }

    func availableOptions(for room: DraftRoom) -> [DraftPickOption] {
        let used = Set(room.picks.map(\.itemID))
        return DraftFixtures.options(for: room.category).filter { !used.contains($0.id) }
    }

    func roster(for playerID: String, in room: DraftRoom) -> [DraftPick] {
        room.picks.filter { $0.pickedByPlayerID == playerID }.sorted { $0.pickNumber < $1.pickNumber }
    }

    private func autoDraftOpponents(in roomIndex: Int) {
        while activeRooms[roomIndex].status == .drafting,
              let turnPlayerID = DraftEngine.currentTurnPlayerID(in: activeRooms[roomIndex]),
              turnPlayerID != currentUser.id {
            guard let option = availableOptions(for: activeRooms[roomIndex]).first else { break }
            try? DraftEngine.makePick(option, by: turnPlayerID, in: &activeRooms[roomIndex])
        }
    }

    private func spendLife(in room: inout DraftRoom) {
        guard let playerIndex = room.players.firstIndex(where: { $0.id == currentUser.id }),
              room.players[playerIndex].lives > 0 else { return }
        room.players[playerIndex].lives -= 1
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case discover
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .discover: "Discover"
        case .history: "History"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .discover: "sparkles"
        case .history: "clock.fill"
        }
    }
}

enum AppRoute: Hashable {
    case newDraft(categoryID: String?)
    case joinCode
    case room(String)
    case judging(String)
    case results(String)
    case settings
    case profile
}

