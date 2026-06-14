import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    profileHeader

                    NavigationLink(value: AppRoute.newDraft(categoryID: nil)) {
                        BigStartButton()
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { appModel.tap(.medium) })

                    activeDrafts
                    recentResults
                    friendsActivity
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
        }
        .draftedNavigationTitle("Drafted")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay { Circle().stroke(DraftedColors.hairline, lineWidth: 1) }
                }
                .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
            }
        }
    }

    private var profileHeader: some View {
        NavigationLink(value: AppRoute.profile) {
            GlassCard(cornerRadius: 34, material: .regularMaterial) {
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        AvatarView(profile: appModel.profile, size: 76)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(appModel.profile.username)
                                .font(.system(.title2, weight: .black))
                                .foregroundStyle(.white)
                            Text("Level \(appModel.profile.level) - \(appModel.profile.xp) XP")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(DraftedColors.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DraftedColors.secondaryText)
                    }
                    XPProgressView(progress: Double(appModel.profile.xp) / Double(appModel.profile.xpForNextLevel))
                }
                .padding(22)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
    }

    private var activeDrafts: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Active Drafts", subtitle: "Live rooms waiting for the next pick.")
            if appModel.activeRooms.isEmpty {
                EmptyStateView(title: "No active rooms", subtitle: "Start a draft and the first board appears here.", symbol: "rectangle.stack.badge.plus")
            } else {
                ForEach(appModel.activeRooms) { room in
                    NavigationLink(value: AppRoute.room(room.id)) {
                        RoomRow(room: room)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
                }
            }
        }
    }

    private var recentResults: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Recent Results", subtitle: nil)
            ForEach(appModel.historyRooms.prefix(2)) { room in
                NavigationLink(value: AppRoute.results(room.id)) {
                    ResultRow(room: room)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
            }
        }
    }

    private var friendsActivity: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Friends Activity", subtitle: nil)
            ForEach(appModel.activity) { item in
                GlassCard(cornerRadius: 24) {
                    HStack(spacing: 14) {
                        CategorySymbol(symbol: item.symbol, size: 50)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(.white)
                            Text(item.subtitle)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DraftedColors.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
        }
    }
}

struct DiscoverView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSection: CategorySection = .trending

    var filteredCategories: [DraftCategory] {
        appModel.categories.filter { $0.tags.contains(selectedSection) }
    }

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Text("choose the room's obsession")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 24)

                    PillSelector(values: CategorySection.allCases, title: \.title, selection: $selectedSection)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredCategories) { category in
                            NavigationLink(value: AppRoute.newDraft(categoryID: category.id)) {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .padding(.top, 18)
            }
        }
        .draftedNavigationTitle("Discover")
    }
}

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("receipts")
                        .font(.system(size: 50, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if appModel.historyRooms.isEmpty {
                        EmptyStateView(title: "No results yet", subtitle: "Finish a draft and the judge will leave evidence here.", symbol: "doc.text.magnifyingglass")
                    } else {
                        ForEach(appModel.historyRooms) { room in
                            NavigationLink(value: AppRoute.results(room.id)) {
                                ResultRow(room: room)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .draftedNavigationTitle("History")
    }
}

private struct BigStartButton: View {
    var body: some View {
        GlassCard(cornerRadius: 38, material: .regularMaterial) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("start a")
                    Text("new draft")
                }
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.78)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 70, height: 70)
                    .background(Color.white, in: Circle())
            }
            .padding(24)
        }
        .accessibilityLabel("Start a New Draft")
    }
}

struct CategoryCard: View {
    var category: DraftCategory

    var body: some View {
        GlassCard(cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    CategorySymbol(symbol: category.symbol, size: 58)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white.opacity(0.70))
                }
                Text(category.title)
                    .font(.system(.title3, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(category.subtitle)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DraftedColors.secondaryText)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .padding(18)
        }
    }
}

struct RoomRow: View {
    var room: DraftRoom

    var body: some View {
        GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: room.category.symbol, size: 60)
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.category.title)
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                    Text("\(room.code) - Round \(max(1, (room.currentPickIndex / max(room.players.count, 1)) + 1)) of \(room.rounds)")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                }
                Spacer()
                Text(room.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white, in: Capsule())
            }
            .padding(16)
        }
    }
}

struct ResultRow: View {
    var room: DraftRoom

    var body: some View {
        GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: "trophy.fill", size: 58)
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.result?.headline ?? room.category.title)
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(room.result?.summary ?? "Waiting for judge.")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(16)
        }
    }
}
