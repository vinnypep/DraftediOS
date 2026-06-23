import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
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
                .padding(.top, 10)
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
            GlassCard(cornerRadius: 28, material: .regularMaterial) {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        AvatarView(profile: appModel.profile, size: 64)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(appModel.profile.username)
                                .font(.system(.title3, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Text("Level \(appModel.profile.level) - \(appModel.profile.xp) XP")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(DraftedColors.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        .layoutPriority(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DraftedColors.secondaryText)
                    }
                    XPProgressView(progress: Double(appModel.profile.xp) / Double(appModel.profile.xpForNextLevel))
                }
                .padding(18)
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
                    ScreenTitle(
                        title: "Choose a category",
                        subtitle: "Pick the board your friends will argue about.",
                        alignment: .center
                    )
                        .padding(.horizontal, 24)

                    PillSelector(values: CategorySection.allCases, title: \.title, selection: $selectedSection)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
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
                    ScreenTitle(title: "Results", subtitle: "Receipts, rematches, and judge notes.", alignment: .center)

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
        GlassCard(cornerRadius: 30, material: .regularMaterial) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start a New Draft")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text("Create a room, share a code, and start picking.")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: 10)

                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(Color.white, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(20)
        }
        .accessibilityLabel("Start a New Draft")
    }
}

struct CategoryCard: View {
    var category: DraftCategory

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    CategorySymbol(symbol: category.symbol, size: 50)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.52))
                }
                Text(category.title)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(category.subtitle)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DraftedColors.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
            .padding(16)
        }
    }
}

struct RoomRow: View {
    var room: DraftRoom

    var body: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: room.category.symbol, size: 50)
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.category.title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("\(room.code) - Round \(max(1, (room.currentPickIndex / max(room.players.count, 1)) + 1)) of \(room.rounds)")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .layoutPriority(1)
                Spacer()
                StatusPill(title: room.status.rawValue.uppercased(), isProminent: true)
            }
            .padding(15)
        }
    }
}

struct ResultRow: View {
    var room: DraftRoom

    var body: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: "trophy.fill", size: 50)
                VStack(alignment: .leading, spacing: 6) {
                    Text(room.result?.headline ?? room.category.title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(room.result?.summary ?? "Waiting for judge.")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                Spacer()
            }
            .padding(15)
        }
    }
}
