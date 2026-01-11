import Foundation

// MARK: - Models used by the parser

struct ParsedRecipe {
    var servings: Int
    var ingredients: [IngredientLine]
    var steps: [String]
}

struct IngredientLine: Identifiable {
    let id = UUID()
    var amount: Double?
    var unit: String?
    var name: String
}

// MARK: - Parser (tailored for your Recipe Card Blocks PRO output)

final class RecipeCardBlocksParser {

    // MARK: Public API

    /// Parses servings, ingredients and steps from `post.content.rendered` (HTML).
    static func parseFromPostContent(_ html: String) -> ParsedRecipe {
        let servings = parseServings(html) ?? 2

        // INGREDIENTS: everything between "Zutaten" and "Anweisungen" (robust)
        let ingredientItemsHtml = extractListItemsBetween(
            startHeading: "Zutaten",
            endHeadings: ["Anweisungen", "Notizen", "Tipps", "Kommentare", "Comments"],
            in: html
        )

        let ingredients = ingredientItemsHtml
            .map(stripHtml)
            .map { normalizeSpaces($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !isSectionLabelLine($0) } // removes lines like "für den Nudelteig"
            .map(parseIngredientLine)

        // STEPS: everything between "Anweisungen" and the next heading block
        let stepItemsHtml = extractListItemsBetween(
            startHeading: "Anweisungen",
            endHeadings: ["Notizen", "Tipps", "Kommentare", "Comments", "Zutaten"],
            in: html
        )

        var steps = stepItemsHtml
            .map(stripHtml)
            .map { normalizeSpaces($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 2 }

        // If we still didn't find steps, fallback to paragraphs (limited)
        if steps.isEmpty {
            steps = extractParagraphs(in: html)
                .map(stripHtml)
                .map { normalizeSpaces($0) }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 20 }
                .prefix(20)
                .map { String($0) }
        }

        return ParsedRecipe(servings: servings, ingredients: ingredients, steps: steps)
    }

    // MARK: Servings ("Portionen ... <zahl> ... Personen")

    private static func parseServings(_ html: String) -> Int? {
        // Matches: Portionen ... 5 ... Personen  (works even with tags/newlines between)
        let pattern = #"Portionen[\s\S]{0,400}?(\d{1,2})[\s\S]{0,120}?Personen"#
        guard let s = firstMatchGroup(pattern: pattern, group: 1, in: html) else { return nil }
        return Int(s)
    }

    // MARK: Ingredients/Steps extraction

    /// Robustly extracts <li> items between a start heading and the nearest next heading in `endHeadings`.
    /// This covers cases where the list isn't immediately after the heading, but there are paragraphs/subheadings in between.
    private static func extractListItemsBetween(
        startHeading: String,
        endHeadings: [String],
        in html: String
    ) -> [String] {

        // Find start heading (h2/h3/h4) containing the keyword
        let startPattern = #"<h[2-4][^>]*>[\s\S]*?"# + escapeForRegex(startHeading) + #"[\s\S]*?</h[2-4]>"#
        guard let startRange = regexRange(pattern: startPattern, in: html) else { return [] }

        let afterStart = String(html[startRange.upperBound...])

        // Find the earliest next "end heading"
        var earliestEnd: String.Index? = nil
        for end in endHeadings {
            let endPattern = #"<h[2-4][^>]*>[\s\S]*?"# + escapeForRegex(end) + #"[\s\S]*?</h[2-4]>"#
            if let r = regexRange(pattern: endPattern, in: afterStart) {
                if earliestEnd == nil || r.lowerBound < earliestEnd! {
                    earliestEnd = r.lowerBound
                }
            }
        }

        let sectionHtml = earliestEnd == nil ? afterStart : String(afterStart[..<earliestEnd!])

        // Extract all <li> items from that section
        let liPattern = #"<li[^>]*>([\s\S]*?)</li>"#
        let items = allMatchGroups(pattern: liPattern, group: 1, in: sectionHtml)

        // Fallback: if there are no <li> at all, try to find a single list block first and extract from that
        if !items.isEmpty { return items }

        let listPattern = #"<(ul|ol)[^>]*>([\s\S]*?)</(ul|ol)>"#
        if let listInner = firstMatchGroup(pattern: listPattern, group: 2, in: sectionHtml) {
            return allMatchGroups(pattern: liPattern, group: 1, in: listInner)
        }

        return []
    }

    private static func extractParagraphs(in html: String) -> [String] {
        let pPattern = #"<p[^>]*>([\s\S]*?)</p>"#
        return allMatchGroups(pattern: pPattern, group: 1, in: html)
    }

    // MARK: Ingredient line parsing (simple but effective)

    private static func parseIngredientLine(_ line: String) -> IngredientLine {
        // Examples:
        // "250 Gramm Nudeln"
        // "200 ml Milch"
        // "1 EL Olivenöl"
        // "1,5 TL Salz"
        //
        // Handles:
        // - amount as number with comma or dot
        // - unit as word/token (incl. ÄÖÜß)
        // - remainder as ingredient name
        let pattern = #"^(\d+(?:[.,]\d+)?)\s+([A-Za-zÄÖÜäöüßµ\.]+)\s+(.*)$"#
        if let amountStr = firstMatchGroup(pattern: pattern, group: 1, in: line),
           let unitStr = firstMatchGroup(pattern: pattern, group: 2, in: line),
           let nameStr = firstMatchGroup(pattern: pattern, group: 3, in: line) {

            let amount = Double(amountStr.replacingOccurrences(of: ",", with: "."))
            return IngredientLine(
                amount: amount,
                unit: unitStr.isEmpty ? nil : unitStr,
                name: nameStr.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        // Fallback: no numeric start (e.g. "Salz nach Geschmack", "etwas Wasser")
        return IngredientLine(amount: nil, unit: nil, name: line)
    }

    // MARK: Section-label filtering (e.g., "für den Nudelteig")

    private static func isSectionLabelLine(_ s: String) -> Bool {
        let l = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Common labels in your recipes:
        // "für den Nudelteig", "für die Pilzfüllung", "für die Soße", etc.
        if l.hasPrefix("für ") { return true }

        // Also filter pure labels ending with ":" (rare but safe)
        if l.hasSuffix(":") && l.count < 40 { return true }

        return false
    }

    // MARK: HTML/text helpers

    static func stripHtml(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#8217;", with: "’")
            .replacingOccurrences(of: "&#8220;", with: "“")
            .replacingOccurrences(of: "&#8221;", with: "”")
            .replacingOccurrences(of: "&#8230;", with: "…")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
    }

    private static func normalizeSpaces(_ s: String) -> String {
        var out = s
        // collapse repeated spaces
        while out.contains("  ") {
            out = out.replacingOccurrences(of: "  ", with: " ")
        }
        // improve punctuation spacing (optional)
        out = out.replacingOccurrences(of: " :", with: ":")
        out = out.replacingOccurrences(of: " ,", with: ",")
        out = out.replacingOccurrences(of: " .", with: ".")
        return out
    }

    private static func escapeForRegex(_ s: String) -> String {
        NSRegularExpression.escapedPattern(for: s)
    }

    // MARK: Regex helpers

    private static func regexRange(pattern: String, in text: String) -> Range<String.Index>? {
        guard let re = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let ns = text as NSString
        guard let match = re.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return Range(match.range(at: 0), in: text)
    }

    private static func firstMatchGroup(pattern: String, group: Int, in text: String) -> String? {
        guard let re = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let ns = text as NSString
        guard let match = re.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        guard match.numberOfRanges > group else { return nil }

        let r = match.range(at: group)
        guard r.location != NSNotFound else { return nil }
        return ns.substring(with: r)
    }

    private static func allMatchGroups(pattern: String, group: Int, in text: String) -> [String] {
        guard let re = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return [] }

        let ns = text as NSString
        let matches = re.matches(in: text, range: NSRange(location: 0, length: ns.length))

        return matches.compactMap { m in
            guard m.numberOfRanges > group else { return nil }
            let r = m.range(at: group)
            guard r.location != NSNotFound else { return nil }
            return ns.substring(with: r)
        }
    }
}

