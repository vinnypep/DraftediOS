import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.didCompleteOnboarding {
                AppShellView()
            } else {
                OnboardingView()
            }
        }
        .background(DraftedColors.background.ignoresSafeArea())
    }
}

struct AppShellView: View {
    @Environment(AppModel.self) private var appModel
    @State private var homePath: [AppRoute] = []
    @State private var discoverPath: [AppRoute] = []
    @State private var historyPath: [AppRoute] = []

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route, path: $homePath)
                    }
            }
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbol) }
            .tag(AppTab.home)

            NavigationStack(path: $discoverPath) {
                DiscoverView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route, path: $discoverPath)
                    }
            }
            .tabItem { Label(AppTab.discover.title, systemImage: AppTab.discover.symbol) }
            .tag(AppTab.discover)

            NavigationStack(path: $historyPath) {
                HistoryView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route, path: $historyPath)
                    }
            }
            .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.symbol) }
            .tag(AppTab.history)
        }
        .tint(.white)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }

    @ViewBuilder
    private func destination(for route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {
        case .newDraft(let categoryID):
            NewDraftView(initialCategoryID: categoryID) { room in
                path.wrappedValue.append(.room(room.id))
            }
        case .joinCode:
            JoinCodeView { room in
                path.wrappedValue.append(.room(room.id))
            }
        case .room(let roomID):
            DraftRoomView(
                roomID: roomID,
                onShowJudging: { path.wrappedValue.append(.judging(roomID)) },
                onShowResults: { path.wrappedValue.append(.results(roomID)) }
            )
        case .judging(let roomID):
            JudgingView(roomID: roomID) {
                path.wrappedValue.append(.results(roomID))
            }
        case .results(let roomID):
            ResultsView(roomID: roomID) { rematch in
                path.wrappedValue.append(.room(rematch.id))
            }
        case .settings:
            SettingsView()
        case .profile:
            ProfileView()
        }
    }
}

