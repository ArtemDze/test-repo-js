import XCTest
@testable import newFirstApp

final class PatternEngineTests: XCTestCase {
    func testSeededGenerationIsDeterministic() {
        var a = PatternParameters.default
        a.seed = 12345
        a.geometry = .starburst
        a.asymmetry = 0.2
        a.distortion = 0.15
        let size = CGSize(width: 400, height: 400)
        let first = PatternEngine.primitives(for: a, in: size)
        let second = PatternEngine.primitives(for: a, in: size)
        XCTAssertEqual(first.count, second.count)
        XCTAssertEqual(first.first?.points, second.first?.points)
    }

    func testParameterClamping() {
        var p = PatternParameters.default
        p.symmetryCount = 99
        p.scale = 9
        p.opacity = -1
        p.asymmetry = 4
        p.clamp()
        XCTAssertEqual(p.symmetryCount, 24)
        XCTAssertEqual(p.scale, 1.25)
        XCTAssertEqual(p.opacity, 0.05)
        XCTAssertEqual(p.asymmetry, 1)
    }

    func testMotifCatalogIsDeterministic() {
        let motif = MotifCatalog.all[0]
        let size = CGSize(width: 400, height: 400)
        let a = PatternEngine.primitives(for: motif.parameters, in: size)
        let b = PatternEngine.primitives(for: motif.parameters, in: size)
        XCTAssertFalse(a.isEmpty)
        XCTAssertEqual(a.count, b.count)
        XCTAssertEqual(MotifCatalog.all.count, 10)
    }

    func testLayoutsProducePrimitives() {
        let size = CGSize(width: 500, height: 500)
        for layout in PatternLayout.allCases {
            var p = PatternParameters.default
            p.layout = layout
            p.seed = 99
            let result = PatternEngine.primitives(for: p, in: size)
            XCTAssertFalse(result.isEmpty, "Layout \(layout.title) should draw something")
        }
    }

    func testExportPixelSize() {
        let square = PatternEngine.exportPixelSize(ratio: .square, quality: .high)
        XCTAssertEqual(square.width, 2160)
        XCTAssertEqual(square.height, 2160)
        let portrait = PatternEngine.exportPixelSize(ratio: .portrait, quality: .standard)
        XCTAssertEqual(portrait.width, 1080)
        XCTAssertEqual(portrait.height, 1440)
    }

    func testPaletteGenerationCount() {
        XCTAssertEqual(PaletteService.colors(baseHue: 0.1, kind: .complementary).count, 2)
        XCTAssertEqual(PaletteService.colors(baseHue: 0.1, kind: .triadic).count, 3)
        XCTAssertEqual(PaletteService.colors(baseHue: 0.1, kind: .monochrome).count, 4)
    }

    func testDailyPromptStableForSameDay() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 30))!
        let a = DailyPromptService.prompt(for: date)
        let b = DailyPromptService.prompt(for: date)
        XCTAssertEqual(a.id, b.id)
        XCTAssertEqual(a.title, b.title)
    }

    func testCollectionFilteringAndSorting() {
        let p1 = StudioProject(title: "Alpha", parameters: .default)
        p1.isFavorite = true
        p1.updatedAt = Date(timeIntervalSince1970: 100)
        var diamond = PatternParameters.default
        diamond.geometry = .diamond
        let p2 = StudioProject(title: "Beta", parameters: diamond)
        p2.updatedAt = Date(timeIntervalSince1970: 200)
        let result = CollectionQuery.filter([p1, p2], search: "bet", sort: .title, filter: .all)
        XCTAssertEqual(result.map(\.title), ["Beta"])
        let favorites = CollectionQuery.filter([p1, p2], search: "", sort: .favoritesFirst, filter: .favorites)
        XCTAssertEqual(favorites.first?.title, "Alpha")
    }

    func testProjectDuplicationCopiesParameters() {
        var params = PatternParameters.default
        params.seed = 777
        params.geometry = .mask
        let original = StudioProject(title: "Original", parameters: params)
        let copy = original.duplicate()
        XCTAssertEqual(copy.parameters.seed, 777)
        XCTAssertEqual(copy.parameters.geometry, .mask)
        XCTAssertTrue(copy.title.contains("Copy"))
        XCTAssertNotEqual(copy.id, original.id)
    }
}
