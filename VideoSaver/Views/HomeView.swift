//
//  HomeView.swift
//  VideoSaver
//
//  Screen 1 – Fetch: paste video URL, tap Fetch Video. Generic web video links only.
//

import SwiftUI

struct FetchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var urlInput = ""
    @State private var showEmptyError = false
    @State private var showErrorAlert = false
    @State private var pendingQualityItem: MediaItem?
    @State private var showPaywall = false

    private var isAnalyzing: Bool {
        if case .analyzing = appViewModel.flowState { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 95, height: 95)
                            .shadow(color: .blue.opacity(0.35), radius: 12, y: 6)

                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)

                    Text("Paste Video Link")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Download videos quickly and securely.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("Only save content you own or have permission to use.")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    TextField("Paste video link", text: $urlInput)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
                        )
                        .padding(.horizontal)

                    if showEmptyError {
                        Text("Please enter a URL.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if case .failure(let message) = appViewModel.flowState {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            showEmptyError = true
                            showErrorAlert = true
                        } else {
                            showEmptyError = false
                            Task {
                                await appViewModel.analyze(url: trimmed)
                                if case .failure = appViewModel.flowState {
                                    showErrorAlert = true
                                }
                            }
                        }
                    } label: {
                        Group {
                            if case .analyzing = appViewModel.flowState {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "arrow.down")
                                    Text("Fetch Video")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnalyzing)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    Spacer(minLength: 24)

                    Text("Fast • Secure • No Login Required")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
                .padding(32)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            if isAnalyzing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Fetching video...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }

            Button {
                showPaywall = true
            } label: {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywallView()
        }
        .onChange(of: appViewModel.flowState) { newState in
            if case .qualitySelection(let item) = newState {
                pendingQualityItem = item
            }
            if case .success = newState {
                urlInput = ""
            }
            if case .failure = newState {
                showErrorAlert = true
            }
        }
        .sheet(item: $pendingQualityItem) { item in
            QualitySelectionSheet(
                item: item,
                onSelect: {
                    appViewModel.setSuccess(item)
                    pendingQualityItem = nil
                },
                onCancel: {
                    pendingQualityItem = nil
                    appViewModel.reset()
                }
            )
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failure(let message) = appViewModel.flowState {
                Text(message)
            }
        }
    }
}

// MARK: - Quality selection (1080p requires premium)
struct QualitySelectionSheet: View {
    let item: MediaItem
    let onSelect: () -> Void
    let onCancel: () -> Void

    @AppStorage("isPremium") private var isPremium = false
    @State private var showPaywall = false
    @State private var pending1080p = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select quality")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    qualityButton(label: "1080p", subtitle: "Full HD", isPremiumOnly: true) {
                        if isPremium {
                            onSelect()
                        } else {
                            pending1080p = true
                            showPaywall = true
                        }
                    }
                    qualityButton(label: "720p", subtitle: "HD", isPremiumOnly: false) { onSelect() }
                    qualityButton(label: "480p", subtitle: "SD", isPremiumOnly: false) { onSelect() }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .onChange(of: showPaywall) { isVisible in
                if !isVisible && pending1080p {
                    if isPremium {
                        onSelect()
                    }
                    pending1080p = false
                }
            }
        }
    }

    private func qualityButton(label: String, subtitle: String, isPremiumOnly: Bool, action: @escaping () -> Void) -> some View {
        let isLocked = isPremiumOnly && !isPremium
        let showPremiumBadge = isPremiumOnly
        return Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if showPremiumBadge {
                            Text("Premium")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isPremiumOnly {
                    Image(systemName: isLocked ? "lock.fill" : "crown.fill")
                        .font(.title3)
                        .foregroundStyle(isLocked ? .orange : .yellow)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        FetchView()
            .environmentObject(AppViewModel())
    }
}
