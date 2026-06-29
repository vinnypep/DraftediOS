import PhotosUI
import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var step: OnboardingStep = .welcome
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        @Bindable var appModel = appModel

        ScreenScaffold {
            ZStack {
                OnboardingAtmosphere()

                VStack(spacing: 0) {
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
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                appModel.profile.avatarImageData = data
                appModel.tap(.success)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 42)

            DraftedHeroIcon()
                .padding(.top, 22)

            Spacer(minLength: 74)

            VStack(spacing: 12) {
                Text("LET'S DRAFT")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.78))
                    .textCase(.uppercase)

                Text("Draft your dream team")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

                Text("Pick a category, build your roster, and see whose team wins.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 18)
            }

            Spacer(minLength: 84)
        }
        .padding(.horizontal, 24)
    }

    private func usernameStep(username: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer(minLength: 34)
            Text("What should friends call you?")
                .font(.system(size: 42, weight: .bold))
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
            Text("Choose your avatar")
                .font(.system(size: 42, weight: .bold))
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
        VStack(spacing: 30) {
            Spacer(minLength: 28)

            VStack(spacing: 8) {
                Text("How it works")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("A quick draft, a cleaner board, and a reveal everyone can argue about.")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            VStack(spacing: 0) {
                FeatureStepRow(
                    symbol: "person.2.badge.plus",
                    title: "Create a room",
                    subtitle: "Choose a category and invite friends with a room code."
                )
                FeatureDivider()
                FeatureStepRow(
                    symbol: "rectangle.stack.fill",
                    title: "Draft your team",
                    subtitle: "Take turns picking the best roster from the board."
                )
                FeatureDivider()
                FeatureStepRow(
                    symbol: "sparkles",
                    title: "Reveal the winner",
                    subtitle: "The judge scores every team and shows the final results."
                )
            }
            .padding(.vertical, 4)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 18)
            Text("Stay in the draft")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)

            PermissionCard(symbol: "bell.badge.fill", title: "Turn notifications", subtitle: "Get a notification when it is your pick.") {
                Task { await appModel.requestNotifications() }
            }

            PermissionCard(symbol: "person.2.fill", title: "Invite friends", subtitle: "Find people faster from your contacts.") {
                Task { await appModel.requestContacts() }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var finalStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer(minLength: 30)
            Text("Get ready to be on the clock")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)

            GlassCard(cornerRadius: 30) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        AvatarView(profile: appModel.profile, size: 72)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appModel.profile.username.isEmpty ? "Draft Captain" : appModel.profile.username)
                                .font(.system(.title3, weight: .semibold))
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

            Button {
                appModel.tap(.medium)
                if step == .ready {
                    appModel.completeOnboarding()
                } else {
                    step = step.next
                }
            } label: {
                Text(step == .ready ? "Create or Join" : "Continue")
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 21)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(step == .username && appModel.profile.username.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(step == .username && appModel.profile.username.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
        }
    }
}

private struct OnboardingAtmosphere: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.005, green: 0.007, blue: 0.018),
                    Color(red: 0.010, green: 0.030, blue: 0.080),
                    Color(red: 0.015, green: 0.090, blue: 0.210),
                    Color(red: 0.010, green: 0.020, blue: 0.055)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.48, blue: 0.95).opacity(0.58),
                    Color(red: 0.02, green: 0.13, blue: 0.36).opacity(0.26),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 520
            )

            RadialGradient(
                colors: [
                    Color(red: 0.14, green: 0.58, blue: 1.0).opacity(0.24),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            DiagonalLightBands()
                .opacity(0.42)
                .blur(radius: 0.8)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct DiagonalLightBands: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(0.08 - Double(index) * 0.006))
                        .frame(width: width * 0.72, height: 2.2)
                        .rotationEffect(.degrees(-18))
                        .offset(x: width * 0.32, y: height * (0.38 + CGFloat(index) * 0.028))
                }
            }
        }
    }
}

private struct DraftedHeroIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.42, blue: 1.0),
                            Color(red: 0.04, green: 0.18, blue: 0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 188, height: 188)
                .shadow(color: Color(red: 0.04, green: 0.32, blue: 0.95).opacity(0.48), radius: 38, x: 0, y: 24)
                .overlay {
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.24))
                .frame(width: 88, height: 116)
                .rotationEffect(.degrees(-14))
                .offset(x: -22, y: 10)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.36))
                .frame(width: 88, height: 116)
                .rotationEffect(.degrees(14))
                .offset(x: 24, y: -2)

            Image(systemName: "trophy.fill")
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        }
        .accessibilityHidden(true)
    }
}

private struct FeatureStepRow: View {
    var symbol: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
    }
}

private struct FeatureDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 1)
            .padding(.leading, 82)
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
                        .font(.system(.headline, weight: .semibold))
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
