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
        DraftCategory(id: "sports-icons", title: "Sports Icons", subtitle: "Athletes, teams, and moments.", symbol: "figure.run", tags: [.trending, .popular, .friends]),
        DraftCategory(id: "movie-legends", title: "Movie Legends", subtitle: "Actors, roles, and scenes.", symbol: "movieclapper.fill", tags: [.popular, .friends]),
        DraftCategory(id: "music-moments", title: "Music Moments", subtitle: "Songs, albums, and performances.", symbol: "music.mic", tags: [.trending, .new]),
        DraftCategory(id: "viral-memes", title: "Viral Memes", subtitle: "Posts, clips, and internet moments.", symbol: "bubble.left.and.bubble.right.fill", tags: [.trending, .friends]),
        DraftCategory(id: "tv-shows", title: "TV Shows", subtitle: "Series, episodes, and characters.", symbol: "tv.fill", tags: [.popular, .friends]),
        DraftCategory(id: "video-games", title: "Video Games", subtitle: "Franchises, bosses, and worlds.", symbol: "gamecontroller.fill", tags: [.trending, .popular]),
        DraftCategory(id: "anime-icons", title: "Anime Icons", subtitle: "Characters, arcs, and battles.", symbol: "sparkle.magnifyingglass", tags: [.new, .friends]),
        DraftCategory(id: "history-legends", title: "History Legends", subtitle: "People, eras, and events.", symbol: "building.columns.fill", tags: [.new]),
        DraftCategory(id: "food-drink", title: "Food & Drink", subtitle: "Meals, snacks, and drinks.", symbol: "fork.knife", tags: [.popular, .friends]),
        DraftCategory(id: "books-literature", title: "Books & Literature", subtitle: "Books, authors, and characters.", symbol: "book.closed.fill", tags: [.new]),
        DraftCategory(id: "custom", title: "Custom Draft", subtitle: "Create your own category.", symbol: "square.and.pencil", tags: [.friends, .new])
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
            headline: "Owen wins Movie Legends.",
            summary: "Final score: 92.",
            teamScores: [
                TeamScore(id: "s1", playerID: currentUser.id, playerName: "Owen", score: 92, verdict: "Best overall roster."),
                TeamScore(id: "s2", playerID: "user-mia", playerName: "Mia", score: 87, verdict: "Second place.")
            ],
            funStats: [
                FunStat(id: "f1", title: "Biggest Sleeper", value: "The Final Monologue", symbol: "moon.fill"),
                FunStat(id: "f2", title: "Lowest Pick", value: "Reboot Energy", symbol: "questionmark.circle.fill")
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
            ("Top Seed", "Best available pick.", "1.circle.fill"),
            ("Sleeper Pick", "Strong late-round option.", "moon.stars.fill"),
            ("Popular Pick", "High-demand board item.", "party.popper.fill"),
            ("Legacy Pick", "Long-term reputation.", "crown.fill"),
            ("Deep Cut", "Category-specific pick.", "scope"),
            ("Rival Pick", "Strong opposing choice.", "theatermasks.fill"),
            ("Debate Pick", "Likely to split the room.", "bubble.left.and.bubble.right.fill"),
            ("Classic Pick", "Reliable roster choice.", "heart.fill"),
            ("Technical Pick", "Strong on details.", "gearshape.2.fill"),
            ("Late Steal", "Available late in the draft.", "bolt.fill"),
            ("Nostalgia Pick", "Older favorite.", "clock.fill"),
            ("Wildcard", "High-variance choice.", "dice.fill"),
            ("Lead Pick", "Strong top-line option.", "person.crop.circle.badge.star"),
            ("Cult Favorite", "Niche pick.", "star.bubble.fill"),
            ("Closer", "Good final pick.", "flag.checkered")
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
