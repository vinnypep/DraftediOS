import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            HomeAtmosphere()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    homeTopBar
                    profileHeader

                    NavigationLink(value: AppRoute.newDraft(categoryID: nil)) {
                        HomeStartFeature()
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { appModel.tap(.medium) })

                    activeDrafts
                    recentResults
                    friendsActivity
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var homeTopBar: some View {
        HStack(alignment: .center) {
            Text("Home")
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Spacer()

            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.20), lineWidth: 1)
                    }
                    .shadow(color: Color(red: 0.08, green: 0.34, blue: 0.90).opacity(0.18), radius: 18, x: 0, y: 12)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { appModel.tap() })
        }
        .padding(.top, 16)
    }

    private var profileHeader: some View {
        NavigationLink(value: AppRoute.profile) {
            HStack(spacing: 15) {
                AvatarView(profile: appModel.profile, size: 58)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(appModel.profile.username)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        StatusPill(title: "Level \(appModel.profile.level)")
                    }

                    Text("\(appModel.profile.xp) XP")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.64))

                    XPProgressView(progress: Double(appModel.profile.xp) / Double(appModel.profile.xpForNextLevel))
                }
                .layoutPriority(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
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
                        subtitle: "Pick a draft category.",
                        isCentered: true
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
                    ScreenTitle(title: "Results", subtitle: "Past drafts and rematches.", isCentered: true)

                    if appModel.historyRooms.isEmpty {
                        EmptyStateView(title: "No results yet", subtitle: "Finished drafts appear here.", symbol: "doc.text.magnifyingglass")
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

private struct HomeAtmosphere: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.006, green: 0.010, blue: 0.024),
                    Color(red: 0.018, green: 0.050, blue: 0.135),
                    Color(red: 0.055, green: 0.115, blue: 0.255),
                    Color(red: 0.010, green: 0.012, blue: 0.030)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.44, blue: 1.0).opacity(0.52),
                    Color(red: 0.10, green: 0.20, blue: 0.58).opacity(0.20),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 520
            )

            RadialGradient(
                colors: [
                    Color(red: 0.25, green: 0.10, blue: 0.70).opacity(0.24),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 560
            )

            HomeLightBands()
                .opacity(0.30)
        }
        .ignoresSafeArea()
    }
}

private struct HomeLightBands: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(0.055 - Double(index) * 0.006))
                        .frame(width: width * 0.64, height: 2)
                        .rotationEffect(.degrees(-16))
                        .offset(x: width * 0.36, y: height * (0.14 + CGFloat(index) * 0.025))
                }
            }
        }
    }
}

private struct HomeStartFeature: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 26, x: 0, y: 18)

            VStack(spacing: 0) {
                ZStack {
                    FloatingDraftTile(symbol: "trophy.fill", size: 112, rotation: -12)
                        .offset(x: -68, y: 0)
                    FloatingDraftTile(symbol: "rectangle.stack.fill", size: 126, rotation: 7)
                        .offset(x: 16, y: -12)
                    FloatingDraftTile(symbol: "sparkles", size: 106, rotation: 13)
                        .offset(x: 88, y: 16)
                }
                .frame(height: 178)
                .frame(maxWidth: .infinity)

                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start a New Draft")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.60)

                        Text("Create a room, share a code, and start picking.")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.66))
                            .lineLimit(2)
                    }
                    .layoutPriority(1)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.white, in: Circle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(minHeight: 292)
        .accessibilityLabel("Start a New Draft")
    }
}

private struct FloatingDraftTile: View {
    var symbol: String
    var size: CGFloat
    var rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.26),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            }
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
            .rotationEffect(.degrees(rotation))
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
