import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.pageBackground, Color(red: 0.08, green: 0.10, blue: 0.16)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                        settingsCard {
                            HStack(spacing: 14) {
                                AppLogo(size: 42)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("hashios").font(.title3.weight(.semibold))
                                    Text(language.text("common.version", appVersion))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Capsule()
                                    .fill(AppTheme.accent.opacity(0.14))
                                    .frame(width: 10, height: 10)
                            }
                        }

                        settingsCard(title: language.text("settings.language")) {
                            Picker(language.text("settings.language"), selection: $languageCode) {
                                ForEach(AppLanguage.allCases) { option in
                                    Text(option.displayName).tag(option.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        settingsCard(title: language.text("common.device")) {
                            LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                            LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                        }

                        settingsCard(title: language.text("settings.verified_versions"), footer: language.text("settings.supported_versions_footer")) {
                            HStack {
                                Text(language.text("settings.current_version"))
                                Spacer()
                                Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                                .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                            }
                            LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                            LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                            LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("iOS 27.0")
                                    .font(.body)
                                ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                                    Text(versionLabel(version))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.vertical, 18)
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .textCase(.uppercase)
            }
            content()
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            AppTheme.referenceCard,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.subtleLine, lineWidth: 1)
        )
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(language.text("accessibility.open_profile", name))
        }
    }
}
