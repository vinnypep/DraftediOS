import SwiftUI

struct NewDraftView: View {
    @Environment(AppModel.self) private var appModel
    let initialCategoryID: String?
    var onCreate: (DraftRoom) -> Void

    @State private var selectedSection: CategorySection = .trending
    @State private var selectedCategory: DraftCategory?
    @State private var rounds = 3
    @State private var maxPlayers = 4
    @State private var mode: DraftMode = .live

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let selectedCategory {
                        settingsView(for: selectedCategory)
                    } else {
                        categoryPicker
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .draftedNavigationTitle("New Draft")
        .onAppear {
            selectedCategory = appModel.category(id: initialCategoryID)
        }
    }

    private var categoryPicker: some View {
        VStack(spacing: 22) {
            ScreenTitle(
                title: "New Draft",
                subtitle: "Choose a category, then set up the room.",
                isCentered: true
            )
                .padding(.horizontal, 24)

            PillSelector(values: CategorySection.allCases, title: \.title, selection: $selectedSection)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                ForEach(appModel.categories.filter { $0.tags.contains(selectedSection) }) { category in
                    Button {
                        appModel.tap(.medium)
                        selectedCategory = category
                    } label: {
                        CategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func settingsView(for category: DraftCategory) -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                Button {
                    appModel.tap()
                    selectedCategory = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial, in: Circle())
                }
                ScreenTitle(title: category.title, subtitle: nil)
                    .layoutPriority(1)
                Spacer()
            }
            .padding(.horizontal, 24)

            GlassCard(cornerRadius: 28, material: .regularMaterial) {
                VStack(spacing: 22) {
                    HStack(spacing: 18) {
                        CategorySymbol(symbol: category.symbol, size: 62)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.subtitle)
                                .font(.system(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Room code generates after setup.")
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DraftedColors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .layoutPriority(1)
                    }

                    StepperRow(title: "Rounds", value: $rounds, range: 1...8)
                    StepperRow(title: "Max players", value: $maxPlayers, range: 2...6)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 10) {
                            ForEach(DraftMode.allCases) { candidate in
                                Button {
                                    appModel.tap()
                                    mode = candidate
                                } label: {
                                    Text(candidate.title)
                                        .font(.system(.headline, weight: .semibold))
                                        .foregroundStyle(mode == candidate ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(mode == candidate ? Color.white : Color.white.opacity(0.08), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    GlassButton(title: "Generate Room", systemImage: "arrow.right", isProminent: true) {
                        let room = appModel.createRoom(category: category, rounds: rounds, maxPlayers: maxPlayers, mode: mode)
                        onCreate(room)
                    }
                }
                .padding(22)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct JoinCodeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var code = ""
    var onJoin: (DraftRoom) -> Void

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 24) {
                ScreenTitle(title: "Join Draft", subtitle: "Enter a room code from a friend.", isCentered: true)

                GlassCard(cornerRadius: 28, material: .regularMaterial) {
                    VStack(spacing: 20) {
                        TextField("DRAFT-X7K9", text: $code)
                            .font(.system(size: 30, weight: .semibold, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(18)
                            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                        GlassButton(title: "Join Draft", systemImage: "arrow.right", isProminent: true) {
                            onJoin(appModel.joinRoom(code: code))
                        }

                        ShareLink(item: "Join my Drafted room: \(code.isEmpty ? "DRAFT-X7K9" : code.uppercased())") {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Invite")
                            }
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay { Capsule().stroke(DraftedColors.hairline, lineWidth: 1) }
                        }
                    }
                    .padding(22)
                }

                Spacer()
            }
            .padding(24)
        }
        .draftedNavigationTitle("Join")
    }
}

struct DraftRoomView: View {
    @Environment(AppModel.self) private var appModel
    let roomID: String
    var onShowJudging: () -> Void
    var onShowResults: () -> Void

    @State private var query = ""
    @State private var remainingSeconds = 45
    @State private var tradeTarget: DraftPlayer?

    var body: some View {
        ScreenScaffold {
            if let room = appModel.room(id: roomID) {
                VStack(spacing: 0) {
                    roomTopBar(room)
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            turnIndicator(room)
                            searchField
                            pickGrid(room)
                            rosters(room)
                            tradeOffers(room)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 104)
                    }

                    bottomBar(room)
                }
            } else {
                EmptyStateView(title: "Room missing", subtitle: "This draft could not be found.", symbol: "exclamationmark.triangle.fill")
                    .padding(24)
            }
        }
        .navigationTitle("Draft Room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let room = appModel.room(id: roomID) {
                    ShareLink(item: "Join my Drafted room: \(room.code)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(item: $tradeTarget) { player in
            TradeSheet(player: player, roomID: roomID)
                .presentationDetents([.medium])
                .presentationBackground(.regularMaterial)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    remainingSeconds = 45
                }
            }
        }
    }

    private func roomTopBar(_ room: DraftRoom) -> some View {
        GlassCard(cornerRadius: 28, material: .regularMaterial) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.code)
                            .font(.system(.headline, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text("Round \(currentRound(room)) of \(room.rounds)")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(DraftedColors.secondaryText)
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                    Spacer()
                    StatusPill(title: "\(myLives(room)) lives", isProminent: true)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(room.players) { player in
                            VStack(spacing: 5) {
                                AvatarView(player: player, size: 40)
                                Text(player.displayName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(isCurrentTurn(player, room) ? .white : DraftedColors.tertiaryText)
                                    .lineLimit(1)
                            }
                            .padding(7)
                            .background(isCurrentTurn(player, room) ? Color.white.opacity(0.13) : Color.clear, in: Capsule())
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func turnIndicator(_ room: DraftRoom) -> some View {
        let currentID = DraftEngine.currentTurnPlayerID(in: room)
        let player = room.players.first { $0.id == currentID }
        let isMine = currentID == appModel.currentUser.id

        return GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                Image(systemName: isMine ? "hand.tap.fill" : "hourglass")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isMine ? .black : .white)
                    .frame(width: 56, height: 56)
                    .background(isMine ? Color.white : Color.white.opacity(0.08), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(isMine ? "your pick" : "\(player?.displayName ?? "Someone") is picking")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text(room.status == .judging ? "All picks are in. Send it to the judge." : "Timer is live. Make it count.")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                Spacer()
            }
            .padding(18)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DraftedColors.secondaryText)
            TextField("Search picks", text: $query)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(.white)
                .submitLabel(.search)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(DraftedColors.hairline, lineWidth: 1) }
    }

    private func pickGrid(_ room: DraftRoom) -> some View {
        let options = filteredOptions(room)
        return VStack(spacing: 14) {
            SectionHeader(title: "Draft Board", subtitle: "\(options.count) picks left")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                ForEach(options) { option in
                    PickOptionCard(option: option) {
                        let status = appModel.makePick(roomID: room.id, option: option)
                        if status == .judging {
                            onShowJudging()
                        }
                    }
                    .disabled(room.status != .drafting || DraftEngine.currentTurnPlayerID(in: room) != appModel.currentUser.id)
                    .opacity(room.status != .drafting ? 0.55 : 1)
                }
            }

            if room.status == .judging {
                GlassButton(title: "Start Judging", systemImage: "sparkles", isProminent: true, action: onShowJudging)
            } else if options.isEmpty {
                EmptyStateView(title: "Board cleared", subtitle: "The judge is almost ready.", symbol: "checkmark.seal.fill")
            }
        }
    }

    private func rosters(_ room: DraftRoom) -> some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Live Rosters", subtitle: "Tap a rival pick to steal it for one life.")
            ForEach(room.players) { player in
                GlassCard(cornerRadius: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            AvatarView(player: player, size: 42)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(player.displayName)
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Text("\(player.lives) lives - \(appModel.roster(for: player.id, in: room).count) picks")
                                    .font(.system(.caption, weight: .bold))
                                    .foregroundStyle(DraftedColors.secondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.74)
                            }
                            .layoutPriority(1)
                            Spacer()
                            if player.id != appModel.currentUser.id {
                                Button("Trade") {
                                    tradeTarget = player
                                }
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white, in: Capsule())
                            }
                        }

                        let roster = appModel.roster(for: player.id, in: room)
                        if roster.isEmpty {
                            Text("No picks yet")
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DraftedColors.tertiaryText)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(roster) { pick in
                                    HStack(spacing: 10) {
                                        Image(systemName: pick.imageSystemName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Color.white.opacity(0.08), in: Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pick.name)
                                                .font(.system(.subheadline, weight: .bold))
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.74)
                                            Text("Pick \(pick.pickNumber)")
                                                .font(.system(.caption2, weight: .bold))
                                                .foregroundStyle(DraftedColors.secondaryText)
                                        }
                                        .layoutPriority(1)
                                        Spacer()
                                        if player.id != appModel.currentUser.id && room.status != .completed {
                                            Button("Steal") {
                                                appModel.stealPick(roomID: room.id, pickID: pick.id)
                                            }
                                            .font(.system(.caption2, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(Color.white.opacity(0.10), in: Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func tradeOffers(_ room: DraftRoom) -> some View {
        VStack(spacing: 12) {
            if !room.trades.isEmpty {
                SectionHeader(title: "Trade Desk", subtitle: "Demo trades swap each side's latest pick.")
                ForEach(room.trades) { trade in
                    GlassCard(cornerRadius: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Trade proposed")
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(trade.status.rawValue.capitalized)
                                    .font(.system(.caption, weight: .bold))
                                    .foregroundStyle(DraftedColors.secondaryText)
                            }
                            Spacer()
                            if trade.status == .pending {
                                Button("Accept") {
                                    appModel.acceptTrade(roomID: room.id, tradeID: trade.id)
                                }
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.white, in: Capsule())
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
    }

    private func bottomBar(_ room: DraftRoom) -> some View {
        GlassCard(cornerRadius: 0, material: .regularMaterial) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text("\(remainingSeconds)s")
                }
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 78)

                ForEach(["🔥", "😮", "💀", "👏"], id: \.self) { emoji in
                    Button {
                        appModel.addReaction(roomID: room.id, emoji: emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 20))
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if room.status == .judging {
                    Button(action: onShowJudging) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 48, height: 48)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func filteredOptions(_ room: DraftRoom) -> [DraftPickOption] {
        let options = appModel.availableOptions(for: room)
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return options }
        return options.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    private func currentRound(_ room: DraftRoom) -> Int {
        min(room.rounds, max(1, (room.currentPickIndex / max(room.players.count, 1)) + 1))
    }

    private func isCurrentTurn(_ player: DraftPlayer, _ room: DraftRoom) -> Bool {
        DraftEngine.currentTurnPlayerID(in: room) == player.id
    }

    private func myLives(_ room: DraftRoom) -> Int {
        room.players.first { $0.id == appModel.currentUser.id }?.lives ?? 0
    }
}

struct JudgingView: View {
    @Environment(AppModel.self) private var appModel
    let roomID: String
    var onResults: () -> Void
    @State private var isJudging = false

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: 24) {
                ScreenTitle(title: "Judging", subtitle: "The AI weighs fit, drama, and ceiling.", isCentered: true)

                VStack(spacing: 14) {
                    JudgeCriteriaCard(symbol: "scope", title: "Fit", subtitle: "Does the team make sense for the category?")
                    JudgeCriteriaCard(symbol: "bolt.fill", title: "Drama", subtitle: "Were there steals, reaches, or momentum swings?")
                    JudgeCriteriaCard(symbol: "crown.fill", title: "Ceiling", subtitle: "Which roster can actually win the room?")
                }

                Spacer()

                GlassButton(title: isJudging ? "Judging..." : "Reveal Results", systemImage: "sparkles", isProminent: true) {
                    guard !isJudging else { return }
                    isJudging = true
                    Task {
                        await appModel.judge(roomID: roomID)
                        isJudging = false
                        onResults()
                    }
                }
            }
            .padding(24)
        }
        .draftedNavigationTitle("Judge")
    }
}

private struct StepperRow: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    value = max(range.lowerBound, value - 1)
                } label: {
                    Image(systemName: "minus")
                }
                Text("\(value)")
                    .font(.system(.title3, weight: .semibold))
                    .frame(width: 34)
                Button {
                    value = min(range.upperBound, value + 1)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .font(.system(.headline, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: Capsule())
        }
    }
}

private struct PickOptionCard: View {
    var option: DraftPickOption
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        CategorySymbol(symbol: option.imageSystemName, size: 48)
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Color.white, in: Circle())
                    }
                    Text(option.name)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    Text(option.detail)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TradeSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    var player: DraftPlayer
    var roomID: String

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.30))
                .frame(width: 44, height: 5)

            AvatarView(player: player, size: 82)
            Text("Trade with \(player.displayName)?")
                .font(.system(.title2, weight: .semibold))
                .foregroundStyle(.white)
            Text("Demo trades offer your latest pick for their latest pick.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DraftedColors.secondaryText)
                .multilineTextAlignment(.center)

            GlassButton(title: "Propose Trade", systemImage: "arrow.left.arrow.right", isProminent: true) {
                appModel.proposeTrade(roomID: roomID, targetPlayerID: player.id)
                dismiss()
            }
        }
        .padding(24)
        .background(DraftedColors.background.opacity(0.88))
    }
}

private struct JudgeCriteriaCard: View {
    var symbol: String
    var title: String
    var subtitle: String

    var body: some View {
        GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: symbol, size: 52)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                }
                Spacer()
            }
            .padding(18)
        }
    }
}
