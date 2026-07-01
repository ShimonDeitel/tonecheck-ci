import SwiftUI
import UIKit

// MARK: - Minimalist, Apple-native color system
// Flat surfaces, system semantic colors (Light AND Dark both look right),
// single Apple-blue accent. No gradients.

extension Color {
    static let tcAccent = Color(hex: "#007AFF")
    static let tcCard = Color(uiColor: .secondarySystemBackground)
    static let tcCard2 = Color(uiColor: .tertiarySystemBackground)
    static let tcField = Color(uiColor: .tertiarySystemFill)
    static let tcHair = Color(uiColor: .separator)

    // Grade colors
    static let gradeA = Color(hex: "#34C759")   // green
    static let gradeB = Color(hex: "#30D158")   // light green
    static let gradeC = Color(hex: "#FF9F0A")   // amber
    static let gradeD = Color(hex: "#FF6B35")   // orange
    static let gradeF = Color(hex: "#FF3B30")   // red
}

// MARK: - Card / pill helpers

extension View {
    func tcCard(cornerRadius: CGFloat = 16) -> some View {
        self.padding(16)
            .background(Color.tcCard, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func tcPill() -> some View {
        self.padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.tcCard2, in: Capsule())
    }

    func prominentButton() -> some View { self.buttonStyle(FilledAccentButtonStyle()) }
    func softButton() -> some View { self.buttonStyle(SoftButtonStyle()) }
}

struct FilledAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.tcAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.tcAccent)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.tcCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Background

struct TCBackground: View {
    var body: some View { Color(uiColor: .systemBackground).ignoresSafeArea() }
}

// MARK: - Haptics

enum Haptics {
    static func tap()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Grade color helper (runtime)

extension Color {
    static func gradeColor(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A": return .gradeA
        case "B": return .gradeB
        case "C": return .gradeC
        case "D": return .gradeD
        default:  return .gradeF
        }
    }
}
