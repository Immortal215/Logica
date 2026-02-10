import Foundation

enum LatexFormatter {
    static let commandMap: [String: String] = [
        "\\\\cdot": "·",
        "\\\\times": "×",
        "\\\\pm": "±",
        "\\\\to": "→",
        "\\\\rightarrow": "→",
        "\\\\leftarrow": "←",
        "\\\\neq": "≠",
        "\\\\leq": "≤",
        "\\\\geq": "≥",
        "\\\\approx": "≈",
        "\\\\infty": "∞",
        "\\\\sum": "Σ",
        "\\\\prod": "Π",
        "\\\\pi": "π",
        "\\\\mu": "μ",
        "\\\\sigma": "σ",
        "\\\\alpha": "α",
        "\\\\beta": "β",
        "\\\\gamma": "γ",
        "\\\\delta": "δ",
        "\\\\theta": "θ",
        "\\\\lambda": "λ"
    ]

    static let superscriptMap: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
        "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
        "a": "ᵃ", "b": "ᵇ", "c": "ᶜ", "d": "ᵈ", "e": "ᵉ", "f": "ᶠ", "g": "ᵍ", "h": "ʰ", "i": "ⁱ", "j": "ʲ", "k": "ᵏ", "l": "ˡ", "m": "ᵐ", "n": "ⁿ", "o": "ᵒ", "p": "ᵖ", "r": "ʳ", "s": "ˢ", "t": "ᵗ", "u": "ᵘ", "v": "ᵛ", "w": "ʷ", "x": "ˣ", "y": "ʸ", "z": "ᶻ"
    ]

    static let subscriptMap: [Character: Character] = [
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
        "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎",
        "a": "ₐ", "e": "ₑ", "h": "ₕ", "i": "ᵢ", "j": "ⱼ", "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ", "o": "ₒ", "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ", "v": "ᵥ", "x": "ₓ"
    ]

    static func render(_ raw: String) -> String {
        var text = raw

        for (pattern, replacement) in commandMap {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }

        text = replaceRegex("\\\\frac\\\\{([^{}]+)\\\\}\\\\{([^{}]+)\\\\}", in: text) { match in
            guard match.count >= 3 else { return match[0] }
            return "(\(match[1]))/(\(match[2]))"
        }

        text = replaceRegex("\\\\sqrt\\\\{([^{}]+)\\\\}", in: text) { match in
            guard match.count >= 2 else { return match[0] }
            return "√(\(match[1]))"
        }

        text = replaceRegex("\\^\\{([^{}]+)\\}", in: text) { match in
            guard match.count >= 2 else { return match[0] }
            return convertScript(match[1], map: superscriptMap, fallbackPrefix: "^(", fallbackSuffix: ")")
        }

        text = replaceRegex("_\\{([^{}]+)\\}", in: text) { match in
            guard match.count >= 2 else { return match[0] }
            return convertScript(match[1], map: subscriptMap, fallbackPrefix: "_(", fallbackSuffix: ")")
        }

        text = replaceRegex("\\^([A-Za-z0-9+\\-=()])", in: text) { match in
            guard match.count >= 2 else { return match[0] }
            return convertScript(match[1], map: superscriptMap, fallbackPrefix: "^(", fallbackSuffix: ")")
        }

        text = replaceRegex("_([A-Za-z0-9+\\-=()])", in: text) { match in
            guard match.count >= 2 else { return match[0] }
            return convertScript(match[1], map: subscriptMap, fallbackPrefix: "_(", fallbackSuffix: ")")
        }

        text = text
            .replacingOccurrences(of: "\\\\", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")

        return text
    }

    static func replaceRegex(_ pattern: String, in text: String, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        guard !matches.isEmpty else { return text }

        var output = text

        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            var groups: [String] = []
            for index in 0..<match.numberOfRanges {
                let groupRange = match.range(at: index)
                if let swiftRange = Range(groupRange, in: output) {
                    groups.append(String(output[swiftRange]))
                } else {
                    groups.append("")
                }
            }
            let replacement = transform(groups)
            output.replaceSubrange(range, with: replacement)
        }

        return output
    }

    static func convertScript(_ value: String, map: [Character: Character], fallbackPrefix: String, fallbackSuffix: String) -> String {
        let converted = value.map { map[$0.lowercased().first ?? $0] }
        if converted.contains(nil) {
            return "\(fallbackPrefix)\(value)\(fallbackSuffix)"
        }
        return String(converted.compactMap { $0 })
    }
}
