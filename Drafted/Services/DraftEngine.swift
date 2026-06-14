import Foundation

enum DraftEngine {
    static func snakeOrder(players: [DraftPlayer], rounds: Int) -> [String] {
        guard rounds > 0 else { return [] }
        let playerIDs = players.map(\.id)

        return (0..<rounds).flatMap { round in
            round.isMultiple(of: 2) ? playerIDs : Array(playerIDs.reversed())
        }
    }

    static func currentTurnPlayerID(in room: DraftRoom) -> String? {
        let order = snakeOrder(players: room.players, rounds: room.rounds)
        guard room.currentPickIndex >= 0, room.currentPickIndex < order.count else { return nil }
        return order[room.currentPickIndex]
    }

    static func roundAndPickNumber(for pickIndex: Int, playerCount: Int) -> (round: Int, pickNumber: Int) {
        guard playerCount > 0 else { return (1, 1) }
        return ((pickIndex / playerCount) + 1, pickIndex + 1)
    }

    static func makePick(_ option: DraftPickOption, by playerID: String, in room: inout DraftRoom) throws {
        guard room.status == .drafting else { throw DraftError.notDrafting }
        guard currentTurnPlayerID(in: room) == playerID else { throw DraftError.notPlayersTurn }
        guard !room.picks.contains(where: { $0.itemID == option.id }) else { throw DraftError.duplicatePick }

        let roundInfo = roundAndPickNumber(for: room.currentPickIndex, playerCount: room.players.count)
        let pick = DraftPick(
            id: UUID().uuidString,
            itemID: option.id,
            name: option.name,
            detail: option.detail,
            imageSystemName: option.imageSystemName,
            pickedByPlayerID: playerID,
            round: roundInfo.round,
            pickNumber: roundInfo.pickNumber,
            stolenFromPlayerID: nil,
            isSteal: false,
            createdAt: Date()
        )

        room.picks.append(pick)
        room.currentPickIndex += 1

        if room.currentPickIndex >= room.players.count * room.rounds {
            room.status = .judging
        }
    }

    static func stealPick(pickID: String, by thiefID: String, in room: inout DraftRoom) throws {
        guard let thiefIndex = room.players.firstIndex(where: { $0.id == thiefID }) else { throw DraftError.playerNotFound }
        guard room.players[thiefIndex].lives > 0 else { throw DraftError.noLivesRemaining }
        guard let pickIndex = room.picks.firstIndex(where: { $0.id == pickID }) else { throw DraftError.pickNotFound }
        guard room.picks[pickIndex].pickedByPlayerID != thiefID else { throw DraftError.cannotStealOwnPick }

        room.players[thiefIndex].lives -= 1
        room.picks[pickIndex].stolenFromPlayerID = room.picks[pickIndex].pickedByPlayerID
        room.picks[pickIndex].pickedByPlayerID = thiefID
        room.picks[pickIndex].isSteal = true
    }
}
