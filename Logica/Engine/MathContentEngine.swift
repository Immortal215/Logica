import Foundation
import SwiftUI
import Combine

enum RepositoryLoadError: Error {
    case missingResource(String)
}

final class BundleMathContentRepository: MathContentRepository {
    var pages: [MathPage] = []
    var pageByID: [String: MathPage] = [:]
    var visualByID: [String: VisualSpec] = [:]
    var derivationByID: [String: DerivationSpec] = [:]

    func load() throws {
        let decodedPages: [MathPage] = try decodeJSON(name: "pages", subdirectory: "Data")
        let decodedDerivations: [DerivationSpec] = try decodeJSON(name: "derivations", subdirectory: "Data")
        let decodedVisuals: [VisualSpec] = try decodeJSON(name: "visuals", subdirectory: "Data")

        try validate(pages: decodedPages, visuals: decodedVisuals, derivations: decodedDerivations)

        pages = decodedPages.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        pageByID = Dictionary(uniqueKeysWithValues: pages.map { ($0.id, $0) })
        visualByID = Dictionary(uniqueKeysWithValues: decodedVisuals.map { ($0.id, $0) })
        derivationByID = Dictionary(uniqueKeysWithValues: decodedDerivations.map { ($0.id, $0) })
    }

    func page(id: String) -> MathPage? {
        pageByID[id]
    }

    func visual(id: String) -> VisualSpec? {
        visualByID[id]
    }

    func derivation(id: String) -> DerivationSpec? {
        derivationByID[id]
    }

    func decodeJSON<T: Decodable>(name: String, subdirectory: String) throws -> T {
        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory),
            Bundle.main.url(forResource: name, withExtension: "json")
        ]

        guard let url = candidateURLs.compactMap({ $0 }).first else {
            throw RepositoryLoadError.missingResource("\(subdirectory)/\(name).json")
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func validate(pages: [MathPage], visuals: [VisualSpec], derivations: [DerivationSpec]) throws {
        var seenPageIDs = Set<String>()

        for page in pages {
            if !seenPageIDs.insert(page.id).inserted {
                throw ValidationErrorKind.duplicatePageID(page.id)
            }
        }

        let visualIDs = Set(visuals.map(\.id))
        let derivationIDs = Set(derivations.map(\.id))
        let pageIDs = Set(pages.map(\.id))

        for page in pages {
            if !visualIDs.contains(page.visualSpecID) {
                throw ValidationErrorKind.missingVisual(pageID: page.id, visualID: page.visualSpecID)
            }

            if page.isEquation {
                guard let derivationID = page.derivationID else {
                    throw ValidationErrorKind.missingDerivation(pageID: page.id, derivationID: "<missing>")
                }
                if !derivationIDs.contains(derivationID) {
                    throw ValidationErrorKind.missingDerivation(pageID: page.id, derivationID: derivationID)
                }
            }

            for relatedID in page.relatedPageIDs where !pageIDs.contains(relatedID) {
                throw ValidationErrorKind.invalidRelatedReference(pageID: page.id, relatedID: relatedID)
            }
        }
    }
}

final class DefaultLinkResolver: LinkResolver {
    struct Token {
        let lower: String
        let range: Range<String.Index>
    }

    let termToPageID: [String: String]
    let maxTermWordCount: Int

    init(pages: [MathPage]) {
        var mapping: [String: String] = [:]

        for page in pages.sorted(by: { $0.title.count > $1.title.count }) {
            let terms = [page.title] + page.aliases
            for term in terms {
                let normalized = term.normalizedSearchKey
                guard !normalized.isEmpty else { continue }
                if mapping[normalized] == nil {
                    mapping[normalized] = page.id
                }
            }
        }

        termToPageID = mapping
        maxTermWordCount = mapping.keys.map { $0.split(separator: " ").count }.max() ?? 1
    }

    func linkedSegments(in text: String, currentPageID: String) -> [LinkedSegment] {
        let tokens = tokenize(text)

        guard !tokens.isEmpty else {
            return [LinkedSegment(text: text)]
        }

        var matches: [(range: Range<String.Index>, targetPageID: String)] = []
        var index = 0

        while index < tokens.count {
            let maxLength = min(maxTermWordCount, tokens.count - index)
            var didMatch = false

            for length in stride(from: maxLength, through: 1, by: -1) {
                let phrase = tokens[index..<(index + length)]
                    .map(\.lower)
                    .joined(separator: " ")

                guard let targetPageID = termToPageID[phrase], targetPageID != currentPageID else {
                    continue
                }

                if length > 1 {
                    let bridgeRange = tokens[index].range.upperBound..<tokens[index + length - 1].range.lowerBound
                    let bridgeText = text[bridgeRange]
                    if bridgeText.contains(where: { !$0.isWhitespace }) {
                        continue
                    }
                }

                let range = tokens[index].range.lowerBound..<tokens[index + length - 1].range.upperBound
                matches.append((range, targetPageID))
                index += length
                didMatch = true
                break
            }

            if !didMatch {
                index += 1
            }
        }

        guard !matches.isEmpty else {
            return [LinkedSegment(text: text)]
        }

        var segments: [LinkedSegment] = []
        var cursor = text.startIndex

        for match in matches {
            if cursor < match.range.lowerBound {
                segments.append(LinkedSegment(text: String(text[cursor..<match.range.lowerBound])))
            }

            segments.append(
                LinkedSegment(
                    text: String(text[match.range]),
                    targetPageID: match.targetPageID
                )
            )

            cursor = match.range.upperBound
        }

        if cursor < text.endIndex {
            segments.append(LinkedSegment(text: String(text[cursor..<text.endIndex])))
        }

        return segments.filter { !$0.text.isEmpty }
    }

    func tokenize(_ text: String) -> [Token] {
        guard let regex = try? NSRegularExpression(pattern: "[A-Za-z0-9]+", options: []) else {
            return []
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return Token(lower: String(text[range]).normalizedSearchKey, range: range)
        }
    }
}

final class DefaultMathSearchEngine: MathSearchEngine {
    let pages: [MathPage]
    let pageByID: [String: MathPage]
    let index: [SearchIndexEntry]

    init(pages: [MathPage]) {
        self.pages = pages
        pageByID = Dictionary(uniqueKeysWithValues: pages.map { ($0.id, $0) })
        index = pages.map {
            SearchIndexEntry(
                pageID: $0.id,
                titleNormalized: $0.title.normalizedSearchKey,
                aliasesNormalized: $0.aliases.map(\.normalizedSearchKey),
                tagsNormalized: $0.tags.map(\.normalizedSearchKey)
            )
        }
    }

    func search(query: String, tags: Set<String>, limit: Int = 40) -> [MathPage] {
        let normalizedQuery = query.normalizedSearchKey
        let normalizedTags = Set(tags.map(\.normalizedSearchKey))

        let scored = index.compactMap { entry -> (MathPage, Int)? in
            guard let page = pageByID[entry.pageID] else { return nil }

            if !normalizedTags.isEmpty {
                let entryTags = Set(entry.tagsNormalized)
                if entryTags.isDisjoint(with: normalizedTags) {
                    return nil
                }
            }

            if normalizedQuery.isEmpty {
                return (page, 1)
            }

            let score = computeScore(entry: entry, query: normalizedQuery)
            guard score > 0 else { return nil }
            return (page, score)
        }

        return scored
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
                }
                return $0.1 > $1.1
            }
            .prefix(limit)
            .map(\.0)
    }

    func computeScore(entry: SearchIndexEntry, query: String) -> Int {
        var score = 0

        if entry.titleNormalized.hasPrefix(query) { score += 120 }
        else if entry.titleNormalized.contains(query) { score += 80 }

        if entry.aliasesNormalized.contains(where: { $0.hasPrefix(query) }) { score += 70 }
        else if entry.aliasesNormalized.contains(where: { $0.contains(query) }) { score += 40 }

        if entry.tagsNormalized.contains(where: { $0.hasPrefix(query) }) { score += 30 }
        else if entry.tagsNormalized.contains(where: { $0.contains(query) }) { score += 15 }

        return score
    }
}

@MainActor
final class MathWikiStore: ObservableObject {
    @Published var query = ""
    @Published var selectedTags: Set<String> = []
    @Published var navigationPath: [String] = []
    @Published var searchResults: [MathPage] = []
    @Published var isLoading = true
    @Published var loadErrorMessage: String?

    let availableTags = ["Algebra", "Calculus", "Statistics"]
    let featuredPageIDs = [
        "quadratic-formula",
        "derivative-definition",
        "normal-distribution",
        "bayes-theorem",
        "pi"
    ]

    let repository: BundleMathContentRepository
    var searchEngine: DefaultMathSearchEngine?
    var linkResolver: DefaultLinkResolver?

    var linkedSummaryCache: [String: AttributedString] = [:]
    var linkedTextCache: [String: AttributedString] = [:]
    var cancellables = Set<AnyCancellable>()

    private var pathSnapshots: [[String]] = [[]]
    private var pathSnapshotCursor = 0
    private var isApplyingPathSnapshot = false

    init(repository: BundleMathContentRepository? = nil) {
        self.repository = repository ?? BundleMathContentRepository()
        bindSearch()
        load()
    }

    var pages: [MathPage] {
        repository.pages
    }

    var pageByID: [String: MathPage] {
        repository.pageByID
    }

    var hasLoadedContent: Bool {
        !pages.isEmpty && loadErrorMessage == nil
    }

    var featuredPages: [MathPage] {
        featuredPageIDs.compactMap { repository.page(id: $0) }
    }

    var homeListPages: [MathPage] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let filtered = selectedTags.isEmpty
                ? pages
                : pages.filter { page in !Set(page.tags).isDisjoint(with: selectedTags) }
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        return searchResults
    }

    var autocompletePages: [MathPage] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        return searchEngine?.search(query: query, tags: selectedTags, limit: 8) ?? []
    }

    func load() {
        isLoading = true
        loadErrorMessage = nil

        do {
            try repository.load()
            searchEngine = DefaultMathSearchEngine(pages: repository.pages)
            linkResolver = DefaultLinkResolver(pages: repository.pages)
            refreshSearch()
            isLoading = false
        } catch {
            loadErrorMessage = String(describing: error)
            isLoading = false
        }
    }

    func bindSearch() {
        Publishers.CombineLatest($query.removeDuplicates(), $selectedTags.removeDuplicates())
            .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
            .sink { [weak self] query, tags in
                self?.refreshSearch(query: query, tags: tags)
            }
            .store(in: &cancellables)
    }

    func refreshSearch() {
        refreshSearch(query: query, tags: selectedTags)
    }

    func refreshSearch(query: String, tags: Set<String>) {
        guard let searchEngine else {
            searchResults = []
            return
        }

        searchResults = searchEngine.search(query: query, tags: tags, limit: 80)
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func page(id: String) -> MathPage? {
        repository.page(id: id)
    }

    func visual(for page: MathPage) -> VisualSpec? {
        repository.visual(id: page.visualSpecID)
    }

    func derivation(for page: MathPage) -> DerivationSpec? {
        guard let derivationID = page.derivationID else { return nil }
        return repository.derivation(id: derivationID)
    }

    func relatedPages(for page: MathPage) -> [MathPage] {
        page.relatedPageIDs.compactMap { repository.page(id: $0) }
    }

    func openPage(_ pageID: String) {
        guard repository.page(id: pageID) != nil else { return }
        navigationPath.append(pageID)
        registerNavigationChangeIfNeeded(navigationPath)
    }

    func registerNavigationChangeIfNeeded(_ path: [String]) {
        guard !isApplyingPathSnapshot else { return }
        guard pathSnapshots[pathSnapshotCursor] != path else { return }

        if pathSnapshotCursor < (pathSnapshots.count - 1) {
            pathSnapshots.removeSubrange((pathSnapshotCursor + 1)..<pathSnapshots.count)
        }

        pathSnapshots.append(path)
        pathSnapshotCursor += 1
    }

    var canGoBack: Bool {
        pathSnapshotCursor > 0
    }

    var canGoForward: Bool {
        pathSnapshotCursor < (pathSnapshots.count - 1)
    }

    func goBack() {
        guard canGoBack else { return }
        pathSnapshotCursor -= 1
        applySnapshot(at: pathSnapshotCursor)
    }

    func goForward() {
        guard canGoForward else { return }
        pathSnapshotCursor += 1
        applySnapshot(at: pathSnapshotCursor)
    }

    func applySnapshot(at index: Int) {
        guard pathSnapshots.indices.contains(index) else { return }
        isApplyingPathSnapshot = true
        navigationPath = pathSnapshots[index]
        isApplyingPathSnapshot = false
    }

    func parseLinkedPageID(from url: URL) -> String? {
        guard url.scheme == "mathwiki" else { return nil }

        if let host = url.host(percentEncoded: false), !host.isEmpty {
            return host
        }

        let trimmed = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? nil : trimmed
    }

    func linkedSummary(for page: MathPage) -> AttributedString {
        if let cached = linkedSummaryCache[page.id] {
            return cached
        }

        let attributed = linkedAttributedText(source: page.summaryMarkdown, cacheKey: "summary:\(page.id)", currentPageID: page.id)
        linkedSummaryCache[page.id] = attributed
        return attributed
    }

    func linkedAttributedText(source: String, cacheKey: String, currentPageID: String) -> AttributedString {
        if let cached = linkedTextCache[cacheKey] {
            return cached
        }

        guard let linkResolver else {
            let plain = AttributedString(source)
            linkedTextCache[cacheKey] = plain
            return plain
        }

        let formattedSource = LatexFormatter.render(source)
        let segments = linkResolver.linkedSegments(in: formattedSource, currentPageID: currentPageID)
        let markdown = segments.map { segment in
            guard let pageID = segment.targetPageID else {
                return segment.text
            }
            return "[\(segment.text.markdownEscaped)](mathwiki://\(pageID))"
        }
        .joined()

        let attributed = (try? AttributedString(markdown: markdown)) ?? AttributedString(formattedSource)
        linkedTextCache[cacheKey] = attributed
        return attributed
    }
}

extension String {
    var normalizedSearchKey: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    var markdownEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
    }
}
