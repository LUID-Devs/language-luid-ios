//
//  LanguageLuidApp.swift
//  LanguageLuid
//
//  Main application entry point with authentication routing
//  Manages app lifecycle and global state
//

import SwiftUI

/// Main application entry point
@main
struct LanguageLuidApp: App {

    // MARK: - State Objects

    /// Authentication view model - manages user authentication state
    @StateObject private var authViewModel = AuthViewModel()

    // MARK: - Scene Configuration

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light) // Can be changed to support system preference
        }
    }
}

// MARK: - Root View

/// Root view that handles authentication routing
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            if authViewModel.isLoading {
                // Show splash screen while checking authentication
                SplashView()
            } else if authViewModel.isAuthenticated {
                // User is authenticated - show main app
                TabBarView()
            } else {
                // User is not authenticated - show auth flow
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoading)
    }
}

// MARK: - Splash View

/// Splash screen shown during initial app load
struct SplashView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background
            LLColors.background.color(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: LLSpacing.xl) {
                // App Logo/Icon
                ZStack {
                    Circle()
                        .fill(LLColors.primary.color(for: colorScheme))
                        .frame(width: 120, height: 120)
                        .shadow(
                            color: LLColors.primary.color(for: colorScheme).opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                    Image(systemName: "globe.americas.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                }
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

                // App Name
                VStack(spacing: LLSpacing.xs) {
                    Text("Language Luid")
                        .font(LLTypography.h2())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("Learn languages naturally")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                // Loading Spinner
                LLSpinner(size: .lg)
                    .padding(.top, LLSpacing.lg)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview Support

#Preview("Splash Screen") {
    SplashView()
}

#Preview("Root View - Loading") {
    RootView()
        .environmentObject(AuthViewModel.mockLoading())
}

#Preview("Root View - Not Authenticated") {
    RootView()
        .environmentObject(AuthViewModel())
}

#Preview("Root View - Authenticated") {
    RootView()
        .environmentObject(AuthViewModel.mock())
}
