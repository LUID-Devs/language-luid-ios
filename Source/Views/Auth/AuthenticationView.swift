//
//  AuthenticationView.swift
//  LanguageLuid
//
//  Main authentication container with tab switcher
//  Provides smooth transitions between Login and Register views
//

import SwiftUI

/// Main authentication view with tab navigation
struct AuthenticationView: View {
    // MARK: - Properties

    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: AuthTab = .login
    @State private var showForgotPassword = false
    @State private var showVerifyEmail = false
    @State private var verificationEmail = ""
    @Namespace private var animation

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Authentication Tabs

    enum AuthTab: String, CaseIterable {
        case login = "Login"
        case register = "Register"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LLColors.background.color(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LLSpacing.xl) {
                    // Logo and Branding
                    brandingHeader

                    // Tab Switcher
                    tabSwitcher

                    // Content
                    TabView(selection: $selectedTab) {
                        LoginView(
                            authViewModel: authViewModel,
                            onForgotPassword: {
                                showForgotPassword = true
                            },
                            onNeedVerification: { email in
                                verificationEmail = email
                                showVerifyEmail = true
                            }
                        )
                        .tag(AuthTab.login)

                        RegisterView(
                            authViewModel: authViewModel,
                            onSuccess: { email in
                                verificationEmail = email
                                showVerifyEmail = true
                            }
                        )
                        .tag(AuthTab.register)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: selectedTab == .login ? 500 : 850)
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                .padding(.horizontal, LLSpacing.screenPaddingHorizontal)
                .padding(.vertical, LLSpacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showVerifyEmail) {
            VerifyEmailView(
                authViewModel: authViewModel,
                email: verificationEmail
            )
        }
    }

    // MARK: - Branding Header

    private var brandingHeader: some View {
        VStack(spacing: LLSpacing.md) {
            // App Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                LLColors.primary.color(for: colorScheme),
                                LLColors.primary.color(for: colorScheme).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(
                        color: LLColors.primary.color(for: colorScheme).opacity(0.3),
                        radius: 20,
                        y: 10
                    )

                Image(systemName: "globe.americas.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
            }
            .padding(.top, LLSpacing.xl)

            // App Name
            VStack(spacing: LLSpacing.xs) {
                Text("LanguageLuid")
                    .font(LLTypography.h1())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .tracking(-0.5)

                Text("Master any language, naturally")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: LLSpacing.sm) {
                        Text(tab.rawValue)
                            .font(LLTypography.buttonLarge())
                            .foregroundColor(
                                selectedTab == tab
                                    ? LLColors.primary.color(for: colorScheme)
                                    : LLColors.mutedForeground.color(for: colorScheme)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LLSpacing.sm)

                        // Active Indicator
                        if selectedTab == tab {
                            Capsule()
                                .fill(LLColors.primary.color(for: colorScheme))
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab_indicator", in: animation)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, LLSpacing.md)
    }
}

// MARK: - Preview

#Preview("Authentication View - Light") {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Authentication View - Dark") {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Authentication View - Register Tab") {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}
