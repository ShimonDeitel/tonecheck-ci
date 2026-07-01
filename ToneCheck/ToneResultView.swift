import SwiftUI

struct ToneResultView: View {
    let result: ToneResult
    let isPro: Bool
    var onSave: (() -> Void)? = nil
    var onUpgrade: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Primary tone + grade badge
            HStack(alignment: .firstTextBaseline) {
                Text(result.primaryTone)
                    .font(.title.weight(.bold))
                Spacer()
                GradeBadge(grade: result.grade)
            }

            // Sub-tones (Pro only)
            if isPro || !result.subTones.isEmpty {
                if isPro {
                    subToneChips
                } else {
                    // Teaser: show blurred chips
                    subToneTeaser
                }
            }

            Divider().background(Color.tcHair)

            // Verdict
            VStack(alignment: .leading, spacing: 4) {
                Text("Verdict")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(result.verdict)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Rewrite suggestion (Pro only, teaser for free)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Rewrite Suggestion")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    if !isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if isPro {
                    Text(result.rewriteSuggestion)
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.tcCard2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Button(action: { onUpgrade?() }) {
                        Text("Upgrade to Pro to see the rewrite suggestion")
                            .font(.subheadline)
                            .foregroundStyle(Color.tcAccent)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.tcCard2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            // Save button (Pro)
            if isPro, let onSave {
                Button(action: onSave) {
                    Label("Save to History", systemImage: "bookmark")
                }
                .softButton()
            }
        }
        .padding(16)
        .background(Color.tcCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Sub-tone chips

    private var subToneChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(result.subTones, id: \.self) { tone in
                Text(tone)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .tcPill()
            }
        }
    }

    private var subToneTeaser: some View {
        Text("Tap to unlock sub-tones")
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.tcCard2, in: Capsule())
    }
}

// MARK: - Grade badge

struct GradeBadge: View {
    let grade: String

    var body: some View {
        Text(grade.uppercased())
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Color.gradeColor(for: grade), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Simple flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
        _ = maxWidth // suppress unused warning
    }
}
