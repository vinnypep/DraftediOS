import PhotosUI
import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var step: OnboardingStep = .welcome
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        @Bindable var appModel = appModel

        ScreenScaffold {
            VStack(spacing: 0) {
                HStack {
                    CircleIconButton(systemImage: "line.3.horizontal", size: 58) {
                        appModel.tap()
                    }
                    Spacer()
                    stepDots
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                TabView(selection: $step) {
                    welcomeStep.tag(OnboardingStep.welcome)
                    usernameStep(username: $appModel.profile.username).tag(OnboardingStep.username)
                    avatarStep(profile: $appModel.profile).tag(OnboardingStep.avatar)
                    howItWorksStep.tag(OnboardingStep.howItWorks)
                    permissionsStep.tag(OnboardingStep.permissions)
                    finalStep.tag(OnboardingStep.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.snappy(duration: 0.35), value: step)

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
            }
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                appModel.profile.avatarImageData = data
                appModel.tap(.success)
            }
        }
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases) { candidate in
                Circle()
                    .fill(candidate == step ? Color.white : Color.white.opacity(0.20))
                    .frame(width: candidate == step ? 11 : 7, height: candidate == step ? 11 : 7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(DraftedColors.hairline, lineWidth: 1) }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer(minLength: 28)

            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("draft night")
                    Text("finally has")
                    Text("a scoreboard")
                }
                .font(.system(size: 58, weight: .black, design: .default))
                .minimumScaleFactor(0.72)
                .foregroundStyle(.white)
                .tracking(0)

                FloatingSticker(symbol: "sparkles")
                    .offset(x: -8, y: -14)
            }

            GlassCard(cornerRadius: 30) {
                HStack(spacing: 18) {
                    CategorySymbol(symbol: "trophy.fill", size: 74)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Snake drafts for any obsession.")
                            .font(.system(.headline, design: .default, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Room code, live picks, steals, trades, and an AI judge with theatrical timing.")
                            .font(.system(.subheadline, design: .default, weight: .medium))
                            .foregroundStyle(DraftedColors.secondaryText)
                    }
                }
                .padding(22)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func usernameStep(username: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer(minLength: 34)
            Text("what should friends call you?")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

            GlassCard(cornerRadius: 28, material: .regularMaterial) {
                TextField("Username", text: username)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(22)
            }

            Text("This name shows up in rooms, results, trades, and rematches.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(DraftedColors.secondaryText)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func avatarStep(profile: Binding<DraftProfile>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)
            Text("pick your draft face")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)

            HStack(spacing: 18) {
                AvatarView(profile: profile.wrappedValue, size: 92)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Camera Roll")
                    }
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.white, in: Capsule())
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 14)], spacing: 14) {
                ForEach(DraftFixtures.avatarPresets, id: \.self) { preset in
                    Button {
                        profile.wrappedValue.avatarPreset = preset
                        profile.wrappedValue.avatarImageData = nil
                        appModel.tap(.medium)
                    } label: {
                        Image(systemName: preset)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(profile.wrappedValue.avatarPreset == preset ? Color.white : Color.white.opacity(0.16), lineWidth: profile.wrappedValue.avatarPreset == preset ? 2 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var howItWorksStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer(minLength: 20)
            Text("how it works")
                .font(.system(size: 52, weight: .black))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                FlowCard(number: "1", title: "Create or join", subtitle: "Choose a category and share a room code.")
                FlowCard(number: "2", title: "Snake draft", subtitle: "Take turns, react, trade, and spend lives on steals.")
                FlowCard(number: "3", title: "Reveal", subtitle: "The AI judge scores boards and announces the winner.")
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 18)
            Text("keep the room moving")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)

            PermissionCard(symbol: "bell.badge.fill", title: "Turn alerts", subtitle: "Get a tap when it is your pick.") {
                Task { await appModel.requestNotifications() }
            }

            PermissionCard(symbol: "person.2.fill", title: "Invite friends", subtitle: "Find people faster from contacts.") {
                Task { await appModel.requestContacts() }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var finalStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer(minLength: 30)
            Text("you're on the clock")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

            GlassCard(cornerRadius: 30) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        AvatarView(profile: appModel.profile, size: 72)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appModel.profile.username.isEmpty ? "Draft Captain" : appModel.profile.username)
                                .font(.system(.title3, weight: .black))
                                .foregroundStyle(.white)
                            Text("Level \(appModel.profile.level) - \(appModel.profile.xp) XP")
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DraftedColors.secondaryText)
                        }
                    }
                    XPProgressView(progress: Double(appModel.profile.xp) / Double(appModel.profile.xpForNextLevel))
                }
                .padding(24)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step != .welcome {
                CircleIconButton(systemImage: "chevron.left", size: 58) {
                    appModel.tap()
                    step = step.previous
                }
            }

            GlassButton(
                title: step == .ready ? "Create or Join" : "Continue",
                systemImage: step == .ready ? "arrow.right" : "chevron.right",
                isProminent: true
            ) {
                appModel.tap(.medium)
                if step == .ready {
                    appModel.completeOnboarding()
                } else {
                    step = step.next
                }
            }
            .disabled(step == .username && appModel.profile.username.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(step == .username && appModel.profile.username.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
        }
    }
}

private struct FlowCard: View {
    var number: String
    var title: String
    var subtitle: String

    var body: some View {
        GlassCard(cornerRadius: 26) {
            HStack(spacing: 16) {
                Text(number)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 54, height: 54)
                    .background(Color.white, in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(.headline, weight: .black))
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

private struct PermissionCard: View {
    var symbol: String
    var title: String
    var subtitle: String
    var action: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: symbol, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                }
                Spacer()
                CircleIconButton(systemImage: "arrow.right", size: 50, action: action)
            }
            .padding(18)
        }
    }
}

private enum OnboardingStep: String, CaseIterable, Identifiable {
    case welcome
    case username
    case avatar
    case howItWorks
    case permissions
    case ready

    var id: String { rawValue }

    var next: OnboardingStep {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index < all.count - 1 else { return self }
        return all[index + 1]
    }

    var previous: OnboardingStep {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return self }
        return all[index - 1]
    }
}
