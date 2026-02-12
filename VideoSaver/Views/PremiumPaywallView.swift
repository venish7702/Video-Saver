//
//  PremiumPaywallView.swift
//  VideoSaver
//
//  Minimal premium paywall: single screen, no scroll, Apple-style.
//

import SwiftUI

enum PremiumPlan: String, CaseIterable {
    case weekly
    case monthly
    case yearly

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .weekly: return "₹299"
        case .monthly: return "₹699"
        case .yearly: return "₹1,899"
        }
    }

    var period: String {
        switch self {
        case .weekly: return "week"
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }

    var caption: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return "₹175/week"
        case .yearly: return "₹36/week"
        }
    }

    var badge: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return nil
        case .yearly: return "Best Value"
        }
    }
}

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremium") private var isPremium = false
    @State private var selectedPlan: PremiumPlan = .monthly
    @State private var isPurchasing = false
    @State private var showRestoreFeedback = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.blue.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topSection
                pricingCardsSection
                featuresLine
                Spacer(minLength: 16)
                continueButton
                footerSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 32)
        }
        .overlay(alignment: .topTrailing) {
            Button("Close") { dismiss() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, 12)
                .padding(.trailing, 20)
        }
        .alert("Restore", isPresented: $showRestoreFeedback) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Restore complete.")
        }
    }

    // MARK: - Top

    private var topSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Video Saver Pro")
                .font(.title.bold())
            Text("No ads. Unlimited downloads.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Pricing Cards

    private var pricingCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(PremiumPlan.allCases, id: \.self) { plan in
                planCard(plan)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPlan = plan
                        }
                    }
            }
        }
    }

    private func planCard(_ plan: PremiumPlan) -> some View {
        let isSelected = selectedPlan == plan
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.title)
                        .font(.headline)
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(plan.price)
                        .font(.title2.bold())
                    Text("/\(plan.period)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let cap = plan.caption {
                    Text(cap)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color.white)
                .shadow(color: .black.opacity(isSelected ? 0.06 : 0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isSelected ? Color.blue : Color.gray.opacity(0.25),
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }

    // MARK: - Features Line

    private var featuresLine: some View {
        Text("Includes: Ad-free • All qualities • Save to Photos")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 20)
    }

    // MARK: - Button

    private var continueButton: some View {
        Button {
            performPurchase()
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isPurchasing)
        .padding(.top, 8)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("Cancel anytime")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Restore Purchases") {
                showRestoreFeedback = true
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - Actions

    private func performPurchase() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPremium = true
            isPurchasing = false
            dismiss()
        }
    }
}

#Preview {
    PremiumPaywallView()
}
