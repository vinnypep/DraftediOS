import AuthenticationServices
import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ScreenTitle(title: "Settings", subtitle: "Sound, touch, account, and sync.", alignment: .center)

                    SettingsToggleRow(title: "Draft music", subtitle: "Subtle room ambience during live drafts.", symbol: "music.note", isOn: appModel.musicEnabled) {
                        appModel.toggleMusic()
                    }

                    SettingsToggleRow(title: "Haptics", subtitle: "Taps, picks, steals, and reveals feel alive.", symbol: "hand.tap.fill", isOn: appModel.hapticsEnabled) {
                        appModel.toggleHaptics()
                    }

                    GlassCard(cornerRadius: 28) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 14) {
                                CategorySymbol(symbol: "icloud.fill", size: 58)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appModel.isFirebaseConfigured ? "Firebase ready" : "Demo mode")
                                        .font(.system(.headline, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(appModel.isFirebaseConfigured ? "GoogleService-Info.plist detected." : "Add GoogleService-Info.plist to enable live sync.")
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundStyle(DraftedColors.secondaryText)
                                }
                            }

                            Button {
                                Task { await appModel.signInWithApple() }
                            } label: {
                                SignInWithAppleButtonView()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(18)
                    }
                }
                .padding(24)
            }
        }
        .draftedNavigationTitle("Settings")
    }
}

struct ProfileView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        @Bindable var appModel = appModel

        ScreenScaffold {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ScreenTitle(title: "Profile", subtitle: "Your draft name and avatar.", alignment: .center)

                    GlassCard(cornerRadius: 34, material: .regularMaterial) {
                        VStack(spacing: 22) {
                            AvatarView(profile: appModel.profile, size: 112)

                            TextField("Username", text: $appModel.profile.username)
                                .font(.system(size: 28, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo")
                                    Text("Choose Photo")
                                }
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white, in: Capsule())
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 12)], spacing: 12) {
                                ForEach(DraftFixtures.avatarPresets, id: \.self) { preset in
                                    Button {
                                        appModel.profile.avatarPreset = preset
                                        appModel.profile.avatarImageData = nil
                                        appModel.tap(.medium)
                                    } label: {
                                        Image(systemName: preset)
                                            .font(.system(size: 23, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 64, height: 64)
                                            .background(.ultraThinMaterial, in: Circle())
                                            .overlay {
                                                Circle().stroke(appModel.profile.avatarPreset == preset ? Color.white : Color.white.opacity(0.16), lineWidth: appModel.profile.avatarPreset == preset ? 2 : 1)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(22)
                    }
                }
                .padding(24)
            }
        }
        .draftedNavigationTitle("Profile")
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                appModel.profile.avatarImageData = data
                appModel.tap(.success)
            }
        }
    }
}

private struct SettingsToggleRow: View {
    var title: String
    var subtitle: String
    var symbol: String
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 28) {
            HStack(spacing: 16) {
                CategorySymbol(symbol: symbol, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DraftedColors.secondaryText)
                }
                Spacer()
                Button(action: action) {
                    ZStack(alignment: isOn ? .trailing : .leading) {
                        Capsule()
                            .fill(isOn ? Color.white : Color.white.opacity(0.12))
                            .frame(width: 58, height: 34)
                        Circle()
                            .fill(isOn ? Color.black : Color.white)
                            .frame(width: 28, height: 28)
                            .padding(3)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
    }
}

private struct SignInWithAppleButtonView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "apple.logo")
            Text("Sign in with Apple")
        }
        .font(.system(.headline, weight: .semibold))
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white, in: Capsule())
    }
}
