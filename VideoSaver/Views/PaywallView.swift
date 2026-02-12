//
//  PaywallView.swift
//  VideoSaver
//
//  Premium paywall: plans, features, legal, restore. App Store–compliant wording.
//

import SwiftUI

// MARK: - Plan Model

struct PaywallPlan: Identifiable {
    let id: String
    let title: String
    let price: String
    let period: String
    let subtitle: String?
    let comparisonText: String?
    let badge: String?
}

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremium") private var isPremium = false
    @State private var selectedPlanId: String = "month"
    @State private var isPurchasing = false
    @State private var showRestoreFeedback = false

    private let plans: [PaywallPlan] = [
        PaywallPlan(
            id: "week",
            title: "Weekly",
            price: "₹299",
            period: "week",
            subtitle: "Perfect for short-term use",
            comparisonText: nil,
            badge: nil
        ),
        PaywallPlan(
            id: "month",
            title: "Monthly",
            price: "₹699",
            period: "month",
            subtitle: nil,
            comparisonText: "Just ₹175 / week",
            badge: "Most Popular"
        ),
        PaywallPlan(
            id: "year",
            title: "Yearly",
            price: "₹1,899",
            period: "year",
            subtitle: nil,
            comparisonText: "Only ₹36 / week",
            badge: "Best Value"
        )
    ]

    private var selectedPlan: PaywallPlan? {
        plans.first { $0.id == selectedPlanId }
    }

    private let features: [(icon: String, text: String)] = [
        ("checkmark.circle.fill", "Ad-free experience"),
        ("checkmark.circle.fill", "Download videos in any quality"),
        ("checkmark.circle.fill", "480p / 720p / 1080p supported"),
        ("checkmark.circle.fill", "Save videos directly to Photos"),
        ("checkmark.circle.fill", "Faster downloads"),
        ("checkmark.circle.fill", "No watermarks")
    ]

    private let privacyURL = URL(string: "https://privacypolicydownloader1.blogspot.com/p/downloader-privacy-policy.html?m=1")!
    private let termsURL = URL(string: "https://sites.google.com/view/terms-of-use-00/home")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        planCardsSection
                        featuresSection
                        ctaSection
                        legalSection
                        restoreSection
                        disclaimerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Restore", isPresented: $showRestoreFeedback) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Restore complete. If you had an active subscription, premium is now enabled.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Video Saver Pro")
                .font(.title.bold())
            Text("Unlimited downloads, no ads, priority support.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(plans) { plan in
                planCard(plan)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPlanId = plan.id
                        }
                    }
            }
        }
    }

    private func planCard(_ plan: PaywallPlan) -> some View {
        let isSelected = selectedPlanId == plan.id
        let isYearly = plan.id == "year"
        let isWeekly = plan.id == "week"

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? .blue : .secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.title)
                        .font(.headline)
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isYearly ? Color.orange : Color.blue)
                            .clipShape(Capsule())
                    }
                }
                if let subtitle = plan.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(plan.price)
                        .font(.title2.bold())
                    Text("/ \(plan.period)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let comp = plan.comparisonText {
                    Text(comp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isYearly ? Color.orange.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? (isYearly ? Color.orange : Color.blue) : Color.clear,
                    lineWidth: 2
                )
        )
        .opacity(isWeekly ? 0.92 : 1)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium benefits")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.body)
                            .foregroundStyle(.green)
                        Text(item.text)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Button {
                performPurchase()
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(selectedPlan.map { "Start Free Trial · \($0.price)/\($0.period)" } ?? "Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isPurchasing)

            Text("Cancel anytime")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment will be charged to your Apple ID.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Subscription auto-renews unless cancelled.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Manage subscription in Apple ID settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: privacyURL)
                    .font(.caption2)
                Link("Terms of Use", destination: termsURL)
                    .font(.caption2)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button("Restore Purchases") {
            restorePurchases()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Text("Only download content you own or have permission to use.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }

    // MARK: - Actions (Dummy)

    private func performPurchase() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPremium = true
            isPurchasing = false
            dismiss()
        }
    }

    private func restorePurchases() {
        showRestoreFeedback = true
    }
}

#Preview {
    PaywallView()
}
