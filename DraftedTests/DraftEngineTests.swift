import XCTest
@testable import Drafted

final class DraftEngineTests: XCTestCase {
    func testSnakeOrderAlternatesEveryRound() {
        let players = [
            DraftPlayer(userID: "a", displayName: "A", avatarPreset: "a"),
            DraftPlayer(userID: "b", displayName: "B", avatarPreset: "b"),
            DraftPlayer(userID: "c", displayName: "C", avatarPreset: "c")
        ]

        XCTAssertEqual(DraftEngine.snakeOrder(players: players, rounds: 3), ["a", "b", "c", "c", "b", "a", "a", "b", "c"])
    }

    func testPickValidationAdvancesTurnAndCompletesRoom() throws {
        var room = DraftRoom(
            id: "room",
            code: "DRAFT-TEST",
            category: DraftFixtures.categories[0],
            rounds: 1,
            maxPlayers: 2,
            mode: .live,
            status: .drafting,
            ownerID: "a",
            currentPickIndex: 0,
            players: [
                DraftPlayer(userID: "a", displayName: "A", avatarPreset: "a"),
                DraftPlayer(userID: "b", displayName: "B", avatarPreset: "b")
            ],
            picks: [],
            trades: [],
            reactions: [],
            result: nil,
            createdAt: Date()
        )

        try DraftEngine.makePick(DraftPickOption(id: "one", name: "One", detail: "Detail", imageSystemName: "1.circle"), by: "a", in: &room)
        XCTAssertEqual(DraftEngine.currentTurnPlayerID(in: room), "b")

        try DraftEngine.makePick(DraftPickOption(id: "two", name: "Two", detail: "Detail", imageSystemName: "2.circle"), by: "b", in: &room)
        XCTAssertEqual(room.status, .judging)
    }

    func testStealCostsLifeAndTransfersPick() throws {
        var room = DraftFixtures.demoRoom(category: DraftFixtures.categories[0], owner: DraftFixtures.currentUser, profile: DraftFixtures.profile)
        try DraftEngine.makePick(DraftPickOption(id: "one", name: "One", detail: "Detail", imageSystemName: "1.circle"), by: room.players[0].id, in: &room)

        let pickID = try XCTUnwrap(room.picks.first?.id)
        let thief = room.players[1].id
        try DraftEngine.stealPick(pickID: pickID, by: thief, in: &room)

        XCTAssertEqual(room.picks[0].pickedByPlayerID, thief)
        XCTAssertEqual(room.players[1].lives, 2)
        XCTAssertTrue(room.picks[0].isSteal)
    }
}

