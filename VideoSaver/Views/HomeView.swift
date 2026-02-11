//
//  HomeView.swift
//  VideoSaver
//
//  Screen 1 – Fetch: paste video URL (Instagram, Facebook, Pinterest, LinkedIn), tap Fetch Video.
//

import SwiftUI

struct FetchView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var urlInput = ""
    @State private var showEmptyError = false
    @State private var showErrorAlert = false
    @State private var pendingQualityItem: MediaItem?

    private var isAnalyzing: Bool {
        if case .analyzing = appViewModel.flowState { return true }
        return false
    }

    var body: some View {
        ZStack {
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

                    Text("Download Instagram reels quickly and securely.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    TextField("Please enter URL link here", text: $urlInput)
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

// MARK: - Quality selection (UI only; actual quality is one from backend)
struct QualitySelectionSheet: View {
    let item: MediaItem
    let onSelect: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select quality")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    qualityButton(label: "1080p", subtitle: "Full HD") { onSelect() }
                    qualityButton(label: "720p", subtitle: "HD") { onSelect() }
                    qualityButton(label: "480p", subtitle: "SD") { onSelect() }
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
        }
    }

    private func qualityButton(label: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.blue)
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
