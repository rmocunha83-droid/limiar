import XCTest
@testable import Limiar

final class OnboardingContentTests: XCTestCase {
    func testDefaultOnboardingThemesComeFromTraditionSet() {
        for tradition in FaithTradition.allCases {
            let defaults = SpiritualTheme.defaultOnboardingThemes(for: tradition)
            let allowed = Set(SpiritualTheme.standaloneOptions(for: tradition))

            XCTAssertFalse(defaults.isEmpty, "\(tradition) sem temas pré-selecionados")
            XCTAssertLessThanOrEqual(defaults.count, 8)
            XCTAssertTrue(
                defaults.allSatisfy { allowed.contains($0) },
                "\(tradition) pré-seleciona tema fora do conjunto da tradição"
            )
        }
    }

    func testSpiritistPreselectionSurvivesNormalization() {
        // O defeito original: pré-seleção derivada do conjunto global deixava
        // a tradição espírita com só 2 temas após a normalização.
        var profile = UserFaithProfile.starter
        profile.tradition = .spiritist
        profile.favoriteThemes = SpiritualTheme.defaultOnboardingThemes(for: .spiritist)
        profile.normalizeStandaloneThemesForCurrentTradition()

        XCTAssertEqual(profile.favoriteThemes.count, 8)
    }

    @MainActor
    func testFavoriteCapKeepsMostRecent() {
        XCTAssertEqual(LimiarAppModel.maximumFavoritePassages, 200)
    }
}
