import SwiftUI

struct ResultsView: View {
    @Environment(AppModel.self) private var appModel
    let roomID: String
    var onRematch: (DraftRoom) -> Void

    @State private var revealScores = false
    @State private var revealStats = false
    @State private var isRejudging = false

    var body: some View {
        ScreenScaffold {
            if let room = appModel.room(id: roomID), let result = room.result {
                ZStack {
                    ConfettiView(isActive: revealScores)
                        .allowsHitTesting(false)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            winnerHero(room: room, result: result)
                            scores(result.teamScores)
                            stats(result.funStats)
                            actions(room)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 34)
                    }
                }
                .task {
                    revealScores = false
                    revealStats = false
                    try? await Task.sleep(for: .milliseconds(350))
                    withAnimation(.snappy(duration: 0.45)) { revealScores = true }
                    try? await Task.sleep(for: .milliseconds(500))
                    withAnimation(.snappy(duration: 0.45)) { revealStats = true }
                }
            } else {
                VStack(spacing: 20) {
                    EmptyStateView(title: "No result yet", subtitle: "Send the room to judging first.", symbol: "sparkles")
                    GlassButton(title: "Run Judge", systemImage: "sparkles", isProminent: true) {
                        isRejudging = true
                        Task {
                            await appModel.judge(roomID: roomID)
                            isRejudging = false
                        }
                    }
                }
                .padding(24)
            }
        }
        .draftedNavigationTitle("Results")
    }

    private func winnerHero(room: DraftRoom, result: JudgeResult) -> some View {
        let winner = room.players.first { $0.id == result.winnerPlayerID }

        return VStack(alignment: .leading, spacing: 20) {
            Text("the winner is")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(DraftedColors.secondaryText)
                .textCase(.uppercase)

            GlassCard(cornerRadius: 38, material: .regularMaterial) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 18) {
                        AvatarView(player: winner, size: 88)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(winner?.displayName ?? "Winner")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.72)
                            Text(room.category.title)
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(DraftedColors.secondaryText)
                        }
                    }

                    Text(result.headline)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(result.summary)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                }
                .padding(24)
            }
            .scaleEffect(revealScores ? 1 : 0.96)
            .opacity(revealScores ? 1 : 0)
        }
    }

    private func scores(_ scores: [TeamScore]) -> some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Team Scores", subtitle: "The judge has notes.")
            ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                GlassCard(cornerRadius: 28) {
                    HStack(spacing: 16) {
                        Text("#\(index + 1)")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 50, height: 50)
                            .background(Color.white, in: Circle())

                        VStack(alignment: .leading, spacing: 5) {
                            Text(score.playerName)
                                .font(.system(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(score.verdict)
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(DraftedColors.secondaryText)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text("\(score.score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                }
                .opacity(revealScores ? 1 : 0)
                .offset(y: revealScores ? 0 : 14)
            }
        }
    }

    private func stats(_ stats: [FunStat]) -> some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Fun Stats", subtitle: "Important science.")
            ForEach(stats) { stat in
                GlassCard(cornerRadius: 26) {
                    HStack(spacing: 14) {
                        CategorySymbol(symbol: stat.symbol, size: 54)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.title)
                                .font(.system(.headline, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(stat.value)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DraftedColors.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(16)
                }
                .opacity(revealStats ? 1 : 0)
            }
        }
    }

    private func actions(_ room: DraftRoom) -> some View {
        VStack(spacing: 12) {
            GlassButton(title: isRejudging ? "Re-Judging..." : "Force Re-Judge", systemImage: "arrow.clockwise", isProminent: false) {
                guard !isRejudging else { return }
                isRejudging = true
                Task {
                    await appModel.forceRejudge(roomID: room.id)
                    isRejudging = false
                }
            }

            GlassButton(title: "Rematch", systemImage: "arrow.counterclockwise", isProminent: true) {
                if let rematch = appModel.rematch(roomID: room.id) {
                    onRematch(rematch)
                }
            }
        }
    }
}

private struct ConfettiView: View {
    var isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<36, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.95 : 0.42))
                    .frame(width: CGFloat(4 + (index % 4) * 2), height: CGFloat(4 + (index % 4) * 2))
                    .position(
                        x: CGFloat((index * 37) % max(Int(proxy.size.width), 1)),
                        y: isActive ? proxy.size.height + CGFloat((index * 17) % 90) : -40
                    )
                    .animation(.easeInOut(duration: Double(1.4 + Double(index % 6) * 0.18)).delay(Double(index % 10) * 0.035), value: isActive)
            }
        }
        .ignoresSafeArea()
    }
}
