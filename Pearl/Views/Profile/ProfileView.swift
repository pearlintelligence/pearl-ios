import SwiftUI

// MARK: - Profile View ("You" tab)

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                        
                        // Quick stats
                        quickStats
                        
                        // Settings sections
                        settingsSections
                        
                        // Version info
                        versionInfo
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(PearlColors.gold)
                        Text("You")
                            .font(PearlFonts.oracleMedium(18))
                            .foregroundColor(PearlColors.goldLight)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(PearlColors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(PearlColors.goldGradient.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(PearlColors.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 80, height: 80)
                
                if let blueprint = viewModel.blueprint {
                    Text(blueprint.sunSign.symbol)
                        .font(.system(size: 36))
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(PearlColors.textMuted)
                }
            }
            
            // Name & sign
            VStack(spacing: 6) {
                if let profile = viewModel.userProfile {
                    Text(profile.name)
                        .font(PearlFonts.oracleSemiBold(22))
                        .foregroundColor(PearlColors.goldLight)
                }
                
                if let blueprint = viewModel.blueprint {
                    Text("\(blueprint.sunSign.displayName) ☉ · \(blueprint.moonSign.displayName) ☽")
                        .font(PearlFonts.body(15))
                        .foregroundColor(PearlColors.textSecondary)
                    
                    let hd = blueprint.humanDesign
                    Text("\(hd.type.rawValue) · \(hd.profile)")
                        .font(PearlFonts.body(14))
                        .foregroundColor(PearlColors.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "bubble.left.fill",
                value: "\(viewModel.conversationCount)",
                label: "Conversations"
            )
            StatCard(
                icon: "eye.fill",
                value: "\(viewModel.insightCount)",
                label: "Insights"
            )
            StatCard(
                icon: "calendar",
                value: viewModel.daysSinceJoined,
                label: "Days"
            )
        }
    }
    
    // MARK: - Settings Sections
    
    private var settingsSections: some View {
        VStack(spacing: 16) {
            // Birth data
            PearlCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "calendar",
                        title: "Birth Data",
                        detail: viewModel.birthDataSummary
                    ) {
                        // Navigate to edit
                    }
                    
                    Divider().background(PearlColors.surface)
                    
                    SettingsRow(
                        icon: "mappin.circle.fill",
                        title: "Birth Location",
                        detail: viewModel.userProfile?.birthLocationName ?? "Not set"
                    ) {
                        // Navigate to edit
                    }
                }
            }
            
            // Preferences
            PearlCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        detail: "Weekly insights"
                    ) {
                        // Navigate
                    }
                    
                    Divider().background(PearlColors.surface)
                    
                    NavigationLink {
                        ConversationHistoryView()
                    } label: {
                        SettingsRowLabel(
                            icon: "clock.arrow.circlepath",
                            title: "Conversation History",
                            detail: "\(viewModel.conversationCount) conversations"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Account
            PearlCard(padding: 0) {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "crown.fill",
                        title: "Pearl Premium",
                        detail: viewModel.isPremium ? "Active" : "Upgrade"
                    ) {
                        // Navigate to paywall
                    }
                    
                    Divider().background(PearlColors.surface)
                    
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        title: "Share Pearl",
                        detail: ""
                    ) {
                        viewModel.sharePearl()
                    }
                }
            }
        }
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("✦")
                .font(.system(size: 12))
                .foregroundColor(PearlColors.gold.opacity(0.3))
            
            Text("Pearl v1.0")
                .font(PearlFonts.caption)
                .foregroundColor(PearlColors.textMuted)
        }
        .padding(.top, 20)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        PearlCard(padding: 12) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(PearlColors.gold)
                
                Text(value)
                    .font(PearlFonts.oracleSemiBold(20))
                    .foregroundColor(PearlColors.goldLight)
                
                Text(label)
                    .font(PearlFonts.caption)
                    .foregroundColor(PearlColors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowLabel(icon: icon, title: title, detail: detail)
        }
    }
}

struct SettingsRowLabel: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(PearlColors.gold)
                .frame(width: 24)
            
            Text(title)
                .font(PearlFonts.bodyMedium(15))
                .foregroundColor(PearlColors.textPrimary)
            
            Spacer()
            
            Text(detail)
                .font(PearlFonts.body(14))
                .foregroundColor(PearlColors.textMuted)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(PearlColors.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Conversation History View

struct ConversationHistoryView: View {
    var body: some View {
        ZStack {
            CosmicBackground()
            
            VStack {
                Text("Conversation History")
                    .font(PearlFonts.screenTitle)
                    .foregroundColor(PearlColors.goldLight)
                
                Text("Coming soon")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
            }
        }
        .navigationTitle("History")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            CosmicBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Account section
                    PearlCard(padding: 0) {
                        VStack(spacing: 0) {
                            SettingsRow(icon: "person.fill", title: "Account", detail: "") { }
                            Divider().background(PearlColors.surface)
                            SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", detail: "") { }
                            Divider().background(PearlColors.surface)
                            SettingsRow(icon: "doc.text.fill", title: "Terms of Service", detail: "") { }
                        }
                    }
                    
                    // Danger zone
                    PearlCard(padding: 0) {
                        VStack(spacing: 0) {
                            Button {
                                appState.hasCompletedOnboarding = false
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(PearlColors.warning)
                                    Text("Reset Onboarding")
                                        .font(PearlFonts.bodyMedium(15))
                                        .foregroundColor(PearlColors.warning)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            
                            Divider().background(PearlColors.surface)
                            
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(PearlColors.error)
                                    Text("Delete Account")
                                        .font(PearlFonts.bodyMedium(15))
                                        .foregroundColor(PearlColors.error)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle account deletion
            }
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
    }
}
