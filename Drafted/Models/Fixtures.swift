import Foundation

enum DraftFixtures {
    static let currentUser = DraftUser(id: "user-owen", email: nil, isAnonymous: true, createdAt: Date())

    static let profile = DraftProfile(
        id: currentUser.id,
        username: "Owen",
        avatarPreset: "face.smiling.inverse",
        avatarImageData: nil,
        level: 1,
        xp: 0,
        xpForNextLevel: 100,
        signInProvider: .anonymous
    )

    static let avatarPresets = [
        "face.smiling.inverse",
        "bolt.fill",
        "flame.fill",
        "crown.fill",
        "sparkles",
        "moon.fill",
        "gamecontroller.fill",
        "music.note"
    ]

    static let categories: [DraftCategory] = [
        DraftCategory(id: "sports-icons", title: "Sports Icons", subtitle: "GOATs, dynasties, and unreal highlight reels.", symbol: "figure.run", tags: [.trending, .popular, .friends]),
        DraftCategory(id: "movie-legends", title: "Movie Legends", subtitle: "Draft the actors, roles, and scenes everyone quotes.", symbol: "movieclapper.fill", tags: [.popular, .friends]),
        DraftCategory(id: "music-moments", title: "Music Moments", subtitle: "Anthems, albums, performances, and chaos.", symbol: "music.mic", tags: [.trending, .new]),
        DraftCategory(id: "viral-memes", title: "Viral Memes", subtitle: "The internet's loudest inside jokes.", symbol: "bubble.left.and.bubble.right.fill", tags: [.trending, .friends]),
        DraftCategory(id: "tv-shows", title: "TV Shows", subtitle: "Comfort classics, prestige drama, and guilty pleasures.", symbol: "tv.fill", tags: [.popular, .friends]),
        DraftCategory(id: "video-games", title: "Video Games", subtitle: "Franchises, bosses, worlds, and legendary consoles.", symbol: "gamecontroller.fill", tags: [.trending, .popular]),
        DraftCategory(id: "anime-icons", title: "Anime Icons", subtitle: "Heroes, villains, arcs, and transformation moments.", symbol: "sparkle.magnifyingglass", tags: [.new, .friends]),
        DraftCategory(id: "history-legends", title: "History Legends", subtitle: "The names that would dominate any group chat.", symbol: "building.columns.fill", tags: [.new]),
        DraftCategory(id: "food-drink", title: "Food & Drink", subtitle: "Snacks, meals, late-night orders, and elite beverages.", symbol: "fork.knife", tags: [.popular, .friends]),
        DraftCategory(id: "books-literature", title: "Books & Literature", subtitle: "Characters, worlds, authors, and plot twists.", symbol: "book.closed.fill", tags: [.new]),
        DraftCategory(id: "custom", title: "Custom Draft", subtitle: "Bring your own category and let the room decide.", symbol: "square.and.pencil", tags: [.friends, .new])
    ]

    static let activity: [ActivityItem] = [
        ActivityItem(id: "a1", title: "Mia won Movie Legends", subtitle: "Score: 91", symbol: "trophy.fill", createdAt: Date()),
        ActivityItem(id: "a2", title: "Jordan used a steal", subtitle: "Final round", symbol: "bolt.fill", createdAt: Date()),
        ActivityItem(id: "a3", title: "Music Moments", subtitle: "Trending", symbol: "music.note", createdAt: Date())
    ]

    static let historyRooms: [DraftRoom] = {
        var room = demoRoom(category: categories[1], owner: currentUser, profile: profile)
        room.status = .completed
        room.picks = [
            DraftPick(id: "p1", itemID: "movie-legends-0", name: "The Final Monologue", detail: "A legacy-defining speech.", imageSystemName: "quote.bubble.fill", pickedByPlayerID: currentUser.id, round: 1, pickNumber: 1, stolenFromPlayerID: nil, isSteal: false, createdAt: Date()),
            DraftPick(id: "p2", itemID: "movie-legends-1", name: "The Quiet Antihero", detail: "Brooding, brilliant, dangerous.", imageSystemName: "theatermasks.fill", pickedByPlayerID: "user-mia", round: 1, pickNumber: 2, stolenFromPlayerID: nil, isSteal: false, createdAt: Date())
        ]
        room.result = JudgeResult(
            id: "result-demo",
            winnerPlayerID: currentUser.id,
            headline: "Owen wins by taste and timing.",
            summary: "The board was clean, surprisingly emotional, and only a little bit ruthless.",
            teamScores: [
                TeamScore(id: "s1", playerID: currentUser.id, playerName: "Owen", score: 92, verdict: "Premium board. Strong closer."),
                TeamScore(id: "s2", playerID: "user-mia", playerName: "Mia", score: 87, verdict: "High ceiling, one risky reach.")
            ],
            funStats: [
                FunStat(id: "f1", title: "Biggest Sleeper", value: "The Final Monologue", symbol: "moon.fill"),
                FunStat(id: "f2", title: "Most Questionable", value: "Reboot Energy", symbol: "questionmark.circle.fill")
            ],
            createdAt: Date()
        )
        return [room]
    }()

    static func demoPlayers(owner: DraftUser, profile: DraftProfile) -> [DraftPlayer] {
        [
            DraftPlayer(userID: owner.id, displayName: profile.username.isEmpty ? "You" : profile.username, avatarPreset: profile.avatarPreset),
            DraftPlayer(userID: "user-mia", displayName: "Mia", avatarPreset: "flame.fill"),
            DraftPlayer(userID: "user-jordan", displayName: "Jordan", avatarPreset: "crown.fill"),
            DraftPlayer(userID: "user-sam", displayName: "Sam", avatarPreset: "gamecontroller.fill"),
            DraftPlayer(userID: "user-ava", displayName: "Ava", avatarPreset: "sparkles"),
            DraftPlayer(userID: "user-noah", displayName: "Noah", avatarPreset: "moon.fill")
        ]
    }

    static func demoRoom(category: DraftCategory, owner: DraftUser, profile: DraftProfile) -> DraftRoom {
        DraftRoom(
            id: UUID().uuidString,
            code: RoomCodeGenerator.generate(),
            category: category,
            rounds: 3,
            maxPlayers: 4,
            mode: .live,
            status: .drafting,
            ownerID: owner.id,
            currentPickIndex: 0,
            players: Array(demoPlayers(owner: owner, profile: profile).prefix(4)),
            picks: [],
            trades: [],
            reactions: [],
            result: nil,
            createdAt: Date()
        )
    }

    static func options(for category: DraftCategory) -> [DraftPickOption] {
        let base: [(String, String, String)] = [
            ("The Untouchable One Seed", "Obvious pick, impossible to hate.", "1.circle.fill"),
            ("Sleeper With Aura", "Late-round energy hiding in plain sight.", "moon.stars.fill"),
            ("Chaotic Crowd Pleaser", "Everyone laughs, then everyone regrets passing.", "party.popper.fill"),
            ("Legacy Pick", "Decades of reputation in one slot.", "crown.fill"),
            ("Deep Cut", "For people who really know the category.", "scope"),
            ("The Villain Board", "Questionable taste, incredible entertainment.", "theatermasks.fill"),
            ("Instant Group Chat War", "Guaranteed debate before the timer ends.", "bubble.left.and.bubble.right.fill"),
            ("The Comfort Classic", "No flash, just undeniable staying power.", "heart.fill"),
            ("The Technical Masterpiece", "Judges love the craft. Friends love the flex.", "gearshape.2.fill"),
            ("Final Round Theft", "A pick that should never have survived.", "bolt.fill"),
            ("Peak Nostalgia", "The room gets quiet for the right reasons.", "clock.fill"),
            ("Wildcard Genius", "Could win the room or end the friendship.", "dice.fill"),
            ("Main Character Energy", "Big entrance, bigger expectations.", "person.crop.circle.badge.star"),
            ("Cult Favorite", "Small fanbase, enormous conviction.", "star.bubble.fill"),
            ("The Closer", "The exact pick you want in the final reveal.", "flag.checkered")
        ]

        return (0..<60).map { index in
            let value = base[index % base.count]
            let themed = themedName(for: category, seed: index, fallback: value.0)
            return DraftPickOption(
                id: "\(category.id)-\(index)",
                name: index < 15 ? themed : "\(themed) \(index + 1)",
                detail: value.1,
                imageSystemName: value.2
            )
        }
    }

    private static func themedName(for category: DraftCategory, seed: Int, fallback: String) -> String {
        let names: [String: [String]] = [
            "sports-icons": ["Prime Serena", "Messi in Space", "Jordan Flu Game", "Simone's Vault", "Tiger on Sunday"],
            "movie-legends": ["The Final Monologue", "Opening Night", "The Quiet Antihero", "Oscar Bait", "The Chase Scene"],
            "music-moments": ["Surprise Drop", "Stadium Chorus", "Tiny Desk Magic", "Summer Bridge", "One-Take Verse"],
            "viral-memes": ["Distracted Draft", "Crying Filter", "Keyboard Smash", "Reply Guy", "The Screenshot"],
            "tv-shows": ["Bottle Episode", "Series Finale", "Cold Open", "Prestige Pilot", "Unhinged Reunion"],
            "video-games": ["Final Boss", "Open World Flex", "Blue Shell", "Save Point", "Speedrun Skip"],
            "anime-icons": ["Power-Up Arc", "Tournament Final", "Rival Entrance", "The Training Fit", "Studio Tears"],
            "history-legends": ["Library Flex", "Battle Map", "Reformer Era", "Explorer Myth", "Dynasty Run"],
            "food-drink": ["Midnight Taco", "Elite Fries", "Perfect Espresso", "Cold Pizza", "Birthday Cake"],
            "books-literature": ["Chapter Twist", "Unreliable Narrator", "Forbidden Library", "Epic Quest", "Last Page"],
            "custom": ["House Rule Hero", "Inside Joke", "Risky Reach", "Group Favorite", "Final Flex"]
        ]
        guard let themed = names[category.id], seed < themed.count else { return fallback }
        return themed[seed]
    }
}

enum RoomCodeGenerator {
    static func generate() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = String((0..<4).compactMap { _ in alphabet.randomElement() })
        return "DRAFT-\(suffix)"
    }
}
