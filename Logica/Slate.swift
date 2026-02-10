import Foundation

enum PageType: String, Codable, CaseIterable, Identifiable {
    case concept
    case equation
    case number

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .concept: return "Concept"
        case .equation: return "Equation"
        case .number: return "Number"
        }
    }
}

enum VisualKind: String, Codable {
    case graph2D
    case animation
    case lattice
    case timeline
}

struct MathPage: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let type: PageType
    let summaryMarkdown: String
    let aliases: [String]
    let tags: [String]
    let relatedPageIDs: [String]
    let visualSpecID: String
    let derivationID: String?

    var isEquation: Bool {
        type == .equation
    }
}

struct DerivationStep: Codable, Hashable, Identifiable {
    let equation: String
    let explanationMarkdown: String
    let animationHint: String?

    var id: String {
        "\(equation)|\(explanationMarkdown)"
    }
}

struct DerivationSpec: Codable, Hashable, Identifiable {
    let id: String
    let steps: [DerivationStep]
    let interactiveModelID: String?
}

struct VisualParameter: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let min: Double
    let max: Double
    let step: Double
    let defaultValue: Double
}

struct VisualSpec: Codable, Hashable, Identifiable {
    let id: String
    let kind: VisualKind
    let modelID: String
    let parameters: [VisualParameter]
    let metadata: [String: String]
}

struct SearchIndexEntry: Hashable {
    let pageID: String
    let titleNormalized: String
    let aliasesNormalized: [String]
    let tagsNormalized: [String]
}

struct LinkedSegment: Identifiable, Hashable {
    let id: UUID
    let text: String
    let targetPageID: String?

    init(id: UUID = UUID(), text: String, targetPageID: String? = nil) {
        self.id = id
        self.text = text
        self.targetPageID = targetPageID
    }
}

enum ValidationErrorKind: Error, Hashable {
    case duplicatePageID(String)
    case missingVisual(pageID: String, visualID: String)
    case missingDerivation(pageID: String, derivationID: String)
    case invalidRelatedReference(pageID: String, relatedID: String)
}

protocol MathContentRepository {
    var pages: [MathPage] { get }
    var pageByID: [String: MathPage] { get }
    var visualByID: [String: VisualSpec] { get }
    var derivationByID: [String: DerivationSpec] { get }

    func load() throws
    func page(id: String) -> MathPage?
    func visual(id: String) -> VisualSpec?
    func derivation(id: String) -> DerivationSpec?
}

protocol LinkResolver {
    func linkedSegments(in text: String, currentPageID: String) -> [LinkedSegment]
}

protocol MathSearchEngine {
    func search(query: String, tags: Set<String>, limit: Int) -> [MathPage]
}

protocol GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double?
}

protocol DerivationPlaybackController: AnyObject {
    var currentStep: Int { get set }
    var isPlaying: Bool { get set }
    var stepCount: Int { get }

    func reset()
    func tick()
}
