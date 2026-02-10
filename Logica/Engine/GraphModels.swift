import Foundation

struct GraphViewport {
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>
}

enum GraphModelRegistry {
    static func model(for modelID: String) -> GraphRenderableModel {
        switch modelID {
        case "linear": return LinearGraphModel()
        case "quadratic": return QuadraticGraphModel()
        case "cubic": return CubicGraphModel()
        case "exponential": return ExponentialGraphModel()
        case "logarithm": return LogarithmGraphModel()
        case "sine": return SineGraphModel()
        case "normal": return NormalDistributionModel()
        case "regression": return RegressionModel()
        case "bayes": return BayesProbabilityModel()
        default: return LinearGraphModel()
        }
    }

    static func defaultParameters(for spec: VisualSpec) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: spec.parameters.map { ($0.id, $0.defaultValue) })
    }

    static func viewport(for spec: VisualSpec) -> GraphViewport {
        let xMin = spec.metadata["xMin"].flatMap(Double.init) ?? -10
        let xMax = spec.metadata["xMax"].flatMap(Double.init) ?? 10
        let yMin = spec.metadata["yMin"].flatMap(Double.init) ?? -10
        let yMax = spec.metadata["yMax"].flatMap(Double.init) ?? 10

        return GraphViewport(xRange: xMin...xMax, yRange: yMin...yMax)
    }
}

struct LinearGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 0
        return (a * x) + b
    }
}

struct QuadraticGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 0
        let c = params["c"] ?? 0
        return (a * x * x) + (b * x) + c
    }
}

struct CubicGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 0
        let c = params["c"] ?? 0
        let d = params["d"] ?? 0
        return (a * x * x * x) + (b * x * x) + (c * x) + d
    }
}

struct ExponentialGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 1
        return a * Foundation.exp(b * x)
    }
}

struct LogarithmGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 1
        let shifted = x + b
        guard shifted > 0 else { return nil }
        return a * Foundation.log(shifted)
    }
}

struct SineGraphModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let a = params["a"] ?? 1
        let b = params["b"] ?? 1
        let c = params["c"] ?? 0
        let d = params["d"] ?? 0
        return a * Foundation.sin((b * x) + c) + d
    }
}

struct NormalDistributionModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let mu = params["mu"] ?? 0
        let sigma = max(params["sigma"] ?? 1, 0.0001)
        let coefficient = 1 / (sigma * Foundation.sqrt(2 * .pi))
        let exponent = -Foundation.pow(x - mu, 2) / (2 * Foundation.pow(sigma, 2))
        return coefficient * Foundation.exp(exponent)
    }
}

struct RegressionModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let m = params["m"] ?? 1
        let b = params["b"] ?? 0
        return (m * x) + b
    }
}

struct BayesProbabilityModel: GraphRenderableModel {
    func yValue(x: Double, params: [String: Double]) -> Double? {
        let prior = min(max(x, 0.0001), 0.9999)
        let sensitivity = min(max(params["sensitivity"] ?? 0.9, 0.0001), 0.9999)
        let falsePositive = min(max(params["falsePositive"] ?? 0.1, 0.0001), 0.9999)

        let denominator = (sensitivity * prior) + (falsePositive * (1 - prior))
        guard denominator > 0 else { return 0 }
        return (sensitivity * prior) / denominator
    }
}
