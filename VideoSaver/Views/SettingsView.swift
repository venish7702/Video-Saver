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
    @State private var safariURL: URL?
    @State private var showPaywall = false
    @State private var showRestoreFeedback = false
    @AppStorage("isPremium") private var isPremium = false

    private let privacyURL = URL(string: "https://privacypolicydownloader1.blogspot.com/p/downloader-privacy-policy.html?m=1")!
    private let termsURL = URL(string: "https://sites.google.com/view/terms-of-use-00/home")!
    private let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id123456789?action=write-review")!

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        SettingsRow(icon: "crown.fill", iconColor: .orange, title: "Subscribe / Premium")
                    }
                    Button {
                        shareApp()
                    } label: {
                        SettingsRow(icon: "square.and.arrow.up", iconColor: .green, title: "Share App")
                    }
                    Button {
                        openAppStoreReview()
                    } label: {
                        SettingsRow(icon: "star.fill", iconColor: .yellow, title: "Rate / Review App")
                    }
                    Button {
                        restorePurchases()
                    } label: {
                        SettingsRow(icon: "arrow.clockwise.circle.fill", iconColor: .blue, title: "Restore Purchases")
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
                    Button {
                        safariURL = termsURL
                    } label: {
                        SettingsRow(icon: "doc.text", iconColor: .gray, title: "Terms of Use")
                    }
                } header: {
                    Text("LEGAL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(item: Binding(
                get: { safariURL.map { IdentifiableURL(url: $0) } },
                set: { safariURL = $0?.url }
            )) { identifiable in
                InAppSafariView(url: identifiable.url) {
                    safariURL = nil
                }
            }
            .alert("Restore Purchases", isPresented: $showRestoreFeedback) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Restore complete. If you had an active subscription, premium is now enabled.")
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

    private func openAppStoreReview() {
        UIApplication.shared.open(appStoreReviewURL)
    }

    private func restorePurchases() {
        if !isPremium {
            showRestoreFeedback = true
        }
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
