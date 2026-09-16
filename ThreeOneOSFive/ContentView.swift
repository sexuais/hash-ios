import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    @State private var aimDragEnabled = false
    @State private var aimNeckEnabled = false
    @State private var hspeitoffEnabled = false
    @State private var hyperBalamagicaEnabled = false
    @State private var aimBodyPackageEnabled = false
    @State private var aimChestPackageEnabled = false
    @State private var magicEnabled = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                brandHeader
                devicePanel
                patchOptions
                gameLaunchPanel
                footerStatus
                developerCredits
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCleaner) {
            CleanerView()
        }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { _ in
            PatchUnlockPrompt(store: patchStore)
        }
        .onAppear { syncPatchStates() }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !patchOperationBusy else { return }
            syncPatchStates()
            patchMessage = "READY — SELECT A PATCH"
        }
    }

    private var brandHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            AppLogo(size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text("hashios")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Patch control center")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.referenceCard, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open settings")
        }
    }

    private var devicePanel: some View {
        VStack(spacing: 0) {
            sectionHeader("Device", detail: appState.isSupported ? "Supported" : "Unsupported", icon: "iphone")
            statusRow(icon: "apple.logo", title: "iOS", value: AppInfo.osVersion, color: AppTheme.secondaryAccent)
            statusRow(icon: "iphone", title: "Device", value: AppInfo.displayMachineName, color: AppTheme.secondaryAccent)
            statusRow(icon: "checkmark.seal.fill", title: "Support", value: appState.isSupported ? "SUPPORTED" : "UNSUPPORTED", color: appState.isSupported ? .green : .red)
        }
        .padding(18)
        .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var patchOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Patches", detail: "Tap to toggle", icon: "slider.horizontal.3")

            LazyVStack(spacing: 8) {
                patchCard(name: "Aim Drag", target: "FREE FIRE • NORMAL", package: "OGIOS File (6).3105", color: AppTheme.accent, state: $aimDragEnabled)
                patchCard(name: "Aim Neck", target: "FREE FIRE • NORMAL", package: "OGIOS File (7).3105", color: AppTheme.secondaryAccent, state: $aimNeckEnabled)
                patchCard(name: "Antenna", target: "FREE FIRE • NORMAL", package: "OGIOS File (8).3105", color: AppTheme.secondaryAccent, state: $hspeitoffEnabled)
                patchCard(name: "144 FPS", target: "FREE FIRE • NORMAL", package: "OGIOS File (10).3105", color: AppTheme.secondaryAccent, state: $hyperBalamagicaEnabled)
                patchCard(name: "Aim Body", target: "FREE FIRE • NORMAL", package: "OGIOS File (12).3105", color: AppTheme.accent, state: $aimBodyPackageEnabled)
                patchCard(name: "Aim Chest", target: "FREE FIRE • NORMAL", package: "OGIOS File (2).3105", color: AppTheme.secondaryAccent, state: $aimChestPackageEnabled)
                patchCard(name: "Magic", target: "FREE FIRE • NORMAL", package: "OGIOS File (14).3105", color: AppTheme.accent, state: $magicEnabled)
            }

            Text(patchOperationBusy ? "Processing patch..." : patchMessage)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.top, 2)
        }
    }

    private func patchCard(name: String, target: String, package: String, color: Color, state: Binding<Bool>) -> some View {
        PatchOptionCard(name: name, target: target, color: color, isEnabled: state, isBusy: patchOperationBusy) {
            togglePatch(packageFilename: package, state: state)
        }
    }

    private var gameLaunchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Actions", detail: "Quick access", icon: "arrow.up.forward.app")
            HStack(spacing: 12) {
                launchButton(title: "FF NORMAL", subtitle: "Free Fire Normal", color: AppTheme.accent, scheme: "freefireth")
                lockedLaunchButton(title: "FF MAX", subtitle: "Locked • Coming Soon", color: AppTheme.secondaryAccent)
            }
            Button {
                showCleaner = true
            } label: {
                Label("Clean Cache & Temp", systemImage: "trash.slash.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open cache and temporary files cleaner")
        }
    }

    private func launchButton(title: String, subtitle: String, color: Color, scheme: String) -> some View {
        Button { openGame(scheme: scheme) } label: {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .padding(.horizontal, 14)
            .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func lockedLaunchButton(title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color.opacity(0.72))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(.horizontal, 14)
        .background(AppTheme.referenceCard.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(0.58)
        .accessibilityLabel("FF MAX locked, coming soon")
    }

    private var footerStatus: some View {
        HStack(spacing: 10) {
            Circle().fill(.green).frame(width: 8, height: 8)
            Text("System ready")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("hashios")
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 4)
    }

    private var developerCredits: some View {
        VStack(spacing: 10) {
            Text("Developed by hashios")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Our Telegram channels")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryAccent.opacity(0.85))

            HStack(spacing: 10) {
                channelButton(title: "hashios Telegram", url: "https://t.me/ogios1")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func channelButton(title: String, url: String) -> some View {
        Button {
            guard let destination = URL(string: url) else { return }
            UIApplication.shared.open(destination)
        } label: {
            Label(title, systemImage: "paperplane.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.referenceCard, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            Text(detail)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func statusRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .medium)).foregroundStyle(color).frame(width: 22)
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
        }
        .padding(.top, 13)
    }

    private func syncPatchStates() {
        aimDragEnabled = isPatchActive("OGIOS File (6).3105")
        aimNeckEnabled = isPatchActive("OGIOS File (7).3105")
        hspeitoffEnabled = isPatchActive("OGIOS File (8).3105")
        hyperBalamagicaEnabled = isPatchActive("OGIOS File (10).3105")
        aimBodyPackageEnabled = isPatchActive("OGIOS File (12).3105")
        aimChestPackageEnabled = isPatchActive("OGIOS File (2).3105")
        magicEnabled = isPatchActive("OGIOS File (14).3105")
    }

    private func isPatchActive(_ packageFilename: String) -> Bool {
        patchStore.items.first(where: { $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame })
            .flatMap { DevicePatchService.latestReceipt(projectID: $0.id) } != nil
    }

    private enum PatchActionResult {
        case applied
        case restored
        case unavailable(String)
    }

    private func setPatchState(for packageFilename: String, enabled: Bool) {
        switch packageFilename {
        case "OGIOS File (6).3105": aimDragEnabled = enabled
        case "OGIOS File (7).3105": aimNeckEnabled = enabled
        case "OGIOS File (8).3105": hspeitoffEnabled = enabled
        case "OGIOS File (10).3105": hyperBalamagicaEnabled = enabled
        case "OGIOS File (12).3105": aimBodyPackageEnabled = enabled
        case "OGIOS File (2).3105": aimChestPackageEnabled = enabled
        case "OGIOS File (14).3105": magicEnabled = enabled
        default: break
        }
    }

    private func togglePatch(packageFilename: String, state: Binding<Bool>) {
        guard !patchOperationBusy else { return }
        guard let item = patchStore.items.first(where: { $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame }) else {
            patchMessage = "ERROR — PACKAGE NOT FOUND"
            log("patch: package not found: \(packageFilename)")
            return
        }

        let wasEnabled = state.wrappedValue
        patchOperationBusy = true
        patchMessage = "PROCESSING — \(packageFilename)"
        let project = item.project
        let projectID = item.id

        DispatchQueue.global(qos: .userInitiated).async {
            let result: PatchActionResult
            do {
                if wasEnabled {
                    guard let receipt = DevicePatchService.latestReceipt(projectID: projectID) else {
                        result = .unavailable("NO ACTIVE RECEIPT — NOTHING TO RESTORE")
                        DispatchQueue.main.async {
                            self.setPatchState(for: packageFilename, enabled: false)
                            self.patchMessage = "OFF — NO ACTIVE PATCH FOUND"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    try DevicePatchService.restore(receipt: receipt)
                    result = .restored
                } else {
                    guard let project else {
                        result = .unavailable("PASSWORD REQUIRED — UNLOCK PACKAGE")
                        DispatchQueue.main.async {
                            self.patchStore.requestUnlock(for: item)
                            self.patchMessage = "PASSWORD REQUIRED — ENTER PACKAGE PASSWORD"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    _ = try DevicePatchService.apply(project: project)
                    result = .applied
                }
            } catch {
                result = .unavailable("FAILED — \(String(describing: error))")
            }

            DispatchQueue.main.async {
                switch result {
                case .applied:
                    self.setPatchState(for: packageFilename, enabled: true)
                    self.patchMessage = "Inject Successful — \(packageFilename)"
                    PatchAudioFeedback.bypassActivated()
                case .restored:
                    self.setPatchState(for: packageFilename, enabled: false)
                    self.patchMessage = "Restore Successful — \(packageFilename)"
                    PatchAudioFeedback.originalRestored()
                case .unavailable(let message):
                    self.patchMessage = message
                }
                self.patchOperationBusy = false
            }
        }
    }

    private func openGame(scheme: String) {
        guard let url = URL(string: "\(scheme)://") else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            log("launch: \(scheme) success=\(success)")
        }
    }
}

private struct PatchOptionCard: View {
    let name: String
    let target: String
    let color: Color
    @Binding var isEnabled: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isEnabled ? color : .secondary)
                    .frame(width: 28, height: 28)
                    .background((isEnabled ? color : Color.secondary).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(target)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(isEnabled ? "ON" : "OFF")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isEnabled ? .green : .secondary)
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isEnabled ? .green : .secondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 12)
            .background(AppTheme.referenceCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isEnabled ? color : .clear)
                    .frame(width: 3, height: 28)
            }
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
        .accessibilityLabel("\(name), \(target), \(isEnabled ? "On" : "Off")")
    }
}

private enum PatchAudioFeedback {
    private static let synthesizer = AVSpeechSynthesizer()
    static func bypassActivated() { speak("Bypass ativado") }
    static func originalRestored() { speak("Bypass desativado") }
    private static func speak(_ message: String) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = voices.first(where: {
            ($0.language.hasPrefix("pt-BR") || $0.language.hasPrefix("pt-PT") || $0.language.hasPrefix("pt")) && $0.gender == .female && $0.quality == .enhanced
        }) ?? voices.first(where: {
            $0.language.hasPrefix("pt-BR") || $0.language.hasPrefix("pt-PT") || $0.language.hasPrefix("pt")
        }) ?? AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.10
        utterance.volume = 0.90
        synthesizer.speak(utterance)
    }
}

private struct PatchUnlockPrompt: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PatchProjectStore
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Package password", text: $password)
                        .textContentType(.password)
                        .submitLabel(.done)
                        .onSubmit(unlock)
                        .onChange(of: password) { _ in store.clearUnlockError() }
                    if let errorKey = store.unlockErrorKey {
                        Text(AppLanguage.english.text(errorKey))
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Enter the password once to unlock this hashios package on this device.")
                }
            }
            .navigationTitle("Unlock package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock", action: unlock)
                        .disabled(password.isEmpty || store.isBusy)
                }
            }
        }
    }

    private func unlock() {
        guard !password.isEmpty else { return }
        store.unlock(password: password)
    }
}

struct AnimatedHyperBackdrop: View {
    var body: some View {
        AppTheme.pageBackground
    }
}
