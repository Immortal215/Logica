import SwiftUI

struct HomeView: View {
    @ObservedObject var store: MathWikiStore
    let openPage: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explore linked concepts, equations, and numbers with live visuals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                searchBar
                tagChips

                if store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    featuredSection
                }

                resultSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    var searchBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search equations, concepts, and numbers", text: $store.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                if !store.query.isEmpty {
                    Button {
                        store.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            if !store.autocompletePages.isEmpty {
                LazyVStack(spacing: 6) {
                    ForEach(store.autocompletePages, id: \.id) { page in
                        Button {
                            openPage(page.id)
                        } label: {
                            HStack {
                                Text(page.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(page.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var tagChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.availableTags, id: \.self) { tag in
                    let isSelected = store.selectedTags.contains(tag)
                    Button {
                        store.toggleTag(tag)
                    } label: {
                        Text(tag)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Featured")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.featuredPages, id: \.id) { page in
                        Button {
                            openPage(page.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(page.title)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                Text(page.type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 170, alignment: .leading)
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.query.isEmpty ? "All Pages" : "Results")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(store.homeListPages, id: \.id) { page in
                    Button {
                        openPage(page.id)
                    } label: {
                        pageCard(page)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func pageCard(_ page: MathPage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(page.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(page.type.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }

            Text(LatexFormatter.render(page.summaryMarkdown))
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(page.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemBackground), in: Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
