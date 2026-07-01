import SwiftUI

/// Reusable label for displaying a tone verdict badge inline.
struct VerdictBadge: View {
    let verdict: ToneVerdict

    private var color: Color {
        switch verdict.color {
        case "danger":  return Color(uiColor: .systemRed)
        case "caution": return Color(uiColor: .systemOrange)
        default:        return Color(uiColor: .systemGreen)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: verdict.sfSymbol)
                .font(.system(size: 13, weight: .semibold))
            Text(verdict.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
    }
}

/// A simple score ring view showing 0-100.
struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 60

    private var fraction: CGFloat { CGFloat(score) / 100.0 }

    private var ringColor: Color {
        if score < 31 { return Color(uiColor: .systemGreen) }
        if score < 61 { return Color(uiColor: .systemOrange) }
        return Color(uiColor: .systemRed)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .systemFill), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.7), value: score)
            Text("\(score)")
                .font(.system(size: size * 0.28, weight: .heavy, design: .rounded))
                .foregroundStyle(ringColor)
        }
        .frame(width: size, height: size)
    }
}
