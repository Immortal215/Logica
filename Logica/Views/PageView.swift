import SwiftUI

struct PageView: View {
    let page: MathPage

    @ObservedObject var store: MathWikiStore
    let openPage: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                summarySection

                if let visual = store.visual(for: page) {
                    VisualSectionView(spec: visual)
                }

                if page.isEquation, let derivation = store.derivation(for: page) {
                    DerivationPlayerView(page: page, derivation: derivation, visual: store.visual(for: page), store: store)
                }

                relatedSection
            }
            .padding(16)
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .environment(\.openURL, OpenURLAction { url in
            guard let linkedID = store.parseLinkedPageID(from: url) else {
                return .systemAction
            }
            openPage(linkedID)
            return .handled
        })
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(page.type.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.14), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(page.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground), in: Capsule())
                    }
                }
            }
        }
    }

    var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)

            Text(store.linkedSummary(for: page))
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    var relatedSection: some View {
        let related = store.relatedPages(for: page)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Related Pages")
                .font(.headline)

            if related.isEmpty {
                Text("No related pages listed yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(related, id: \.id) { item in
                    Button {
                        openPage(item.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(item.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
