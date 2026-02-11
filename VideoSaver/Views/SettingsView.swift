//
//  SettingsView.swift
//  VideoSaver
//

import SwiftUI
import SafariServices

struct InAppSafariView: UIViewControllerRepresentable {
    let url: URL
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onDismiss: (() -> Void)?

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDismiss?()
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var safariURL: URL?

    private let privacyURL = URL(string: "https://example.com/privacy")!
    private let appVersion = "1.0.0 (Build 42)"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("Dark Mode")
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                } header: {
                    Text("PREFERENCES")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        shareApp()
                    } label: {
                        SettingsRow(icon: "square.and.arrow.up", iconColor: .green, title: "Share App")
                    }
                } header: {
                    Text("APP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        safariURL = privacyURL
                    } label: {
                        SettingsRow(icon: "shield.checkered", iconColor: .blue, title: "Privacy Policy")
                    }
                } header: {
                    Text("LEGAL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(item: Binding(
                get: { safariURL.map { IdentifiableURL(url: $0) } },
                set: { safariURL = $0?.url }
            )) { identifiable in
                InAppSafariView(url: identifiable.url) {
                    safariURL = nil
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    Text("Video Saver Pro")
                        .font(.headline)
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("© 2024 VIDEO SAVER STUDIO")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
            }
        }
    }

    private func shareApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let item = URL(string: "https://apps.apple.com/app/id123456789")!
        let av = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        rootVC.present(av, animated: true)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    SettingsView()
}
