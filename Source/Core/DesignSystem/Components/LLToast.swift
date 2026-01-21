//
//  LLToast.swift
//  LanguageLuid
//
//  Design System - Toast Notification Component
//  Temporary notification messages with auto-dismiss
//

import SwiftUI

/// Toast notification style variants
enum LLToastStyle {
    case success
    case error
    case warning
    case info
    case loading

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .loading: return "clock.fill"
        }
    }

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .success:
            return LLColors.success.color(for: colorScheme)
        case .error:
            return LLColors.destructive.color(for: colorScheme)
        case .warning:
            return LLColors.warning.color(for: colorScheme)
        case .info:
            return LLColors.info.color(for: colorScheme)
        case .loading:
            return LLColors.muted.color(for: colorScheme)
        }
    }

    func foregroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .success:
            return LLColors.successForeground.color(for: colorScheme)
        case .error:
            return LLColors.destructiveForeground.color(for: colorScheme)
        case .warning:
            return LLColors.warningForeground.color(for: colorScheme)
        case .info:
            return LLColors.infoForeground.color(for: colorScheme)
        case .loading:
            return LLColors.foreground.color(for: colorScheme)
        }
    }
}

/// Toast notification view
struct LLToast: View {
    // MARK: - Properties

    let message: String
    let style: LLToastStyle
    let duration: TimeInterval
    @Binding var isPresented: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    // MARK: - Initializer

    init(
        message: String,
        style: LLToastStyle = .info,
        duration: TimeInterval = 3.0,
        isPresented: Binding<Bool>
    ) {
        self.message = message
        self.style = style
        self.duration = duration
        self._isPresented = isPresented
    }

    // MARK: - Body

    var body: some View {
        if isPresented {
            HStack(spacing: LLSpacing.sm) {
                // Icon
                Image(systemName: style.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(style.foregroundColor(for: colorScheme))

                // Message
                Text(message)
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(style.foregroundColor(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Dismiss button
                Button {
                    dismissToast()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(style.foregroundColor(for: colorScheme).opacity(0.7))
                }
            }
            .padding(.horizontal, LLSpacing.md)
            .padding(.vertical, LLSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(style.backgroundColor(for: colorScheme))
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .padding(.horizontal, LLSpacing.md)
            .offset(y: offset)
            .opacity(opacity)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = 0
                    opacity = 1
                }

                // Auto dismiss
                if style != .loading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        dismissToast()
                    }
                }
            }
            .zIndex(LLSpacing.zIndexToast)
        }
    }

    // MARK: - Methods

    private func dismissToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            offset = -100
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

/// Toast modifier for easy integration
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastConfig?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let toast = toast {
                LLToast(
                    message: toast.message,
                    style: toast.style,
                    duration: toast.duration,
                    isPresented: Binding(
                        get: { self.toast != nil },
                        set: { if !$0 { self.toast = nil } }
                    )
                )
                .padding(.top, LLSpacing.safeAreaTop + LLSpacing.md)
            }
        }
    }
}

/// Toast configuration model
struct ToastConfig: Equatable {
    let message: String
    let style: LLToastStyle
    let duration: TimeInterval

    init(message: String, style: LLToastStyle = .info, duration: TimeInterval = 3.0) {
        self.message = message
        self.style = style
        self.duration = duration
    }

    // Success helper
    static func success(_ message: String, duration: TimeInterval = 3.0) -> ToastConfig {
        ToastConfig(message: message, style: .success, duration: duration)
    }

    // Error helper
    static func error(_ message: String, duration: TimeInterval = 4.0) -> ToastConfig {
        ToastConfig(message: message, style: .error, duration: duration)
    }

    // Warning helper
    static func warning(_ message: String, duration: TimeInterval = 3.5) -> ToastConfig {
        ToastConfig(message: message, style: .warning, duration: duration)
    }

    // Info helper
    static func info(_ message: String, duration: TimeInterval = 3.0) -> ToastConfig {
        ToastConfig(message: message, style: .info, duration: duration)
    }

    // Loading helper
    static func loading(_ message: String) -> ToastConfig {
        ToastConfig(message: message, style: .loading, duration: .infinity)
    }
}

// MARK: - View Extension

extension View {
    /// Show toast notifications
    func toast(_ toast: Binding<ToastConfig?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview("Toast Notifications") {
    VStack(spacing: LLSpacing.xl) {
        LLButton("Show Success") {
            print("Success toast")
        }
        .padding(.top, 100)

        LLToast(
            message: "Credits purchased successfully!",
            style: .success,
            isPresented: .constant(true)
        )

        LLToast(
            message: "Failed to load transaction history",
            style: .error,
            isPresented: .constant(true)
        )

        LLToast(
            message: "Your subscription will renew soon",
            style: .warning,
            isPresented: .constant(true)
        )

        LLToast(
            message: "You have 100 credits remaining",
            style: .info,
            isPresented: .constant(true)
        )

        Spacer()
    }
    .padding()
}
