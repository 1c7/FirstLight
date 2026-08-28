import XCTest
@testable import FirstLightCore

/// 语言解析规则是设置页和所有窗口本地化的基础，必须保持可预测。
final class LocalizationTests: XCTestCase {
    func testSystemLanguageFollowsChinesePreference() {
        XCTAssertTrue(L10n.resolvesChinese(
            language: .system,
            preferredLanguages: ["zh-Hans-CN", "en-US"]
        ))
    }

    func testSystemLanguageFallsBackToEnglish() {
        XCTAssertFalse(L10n.resolvesChinese(
            language: .system,
            preferredLanguages: ["en-US", "zh-Hans-CN"]
        ))
    }

    func testExplicitLanguageOverridesSystemPreference() {
        XCTAssertTrue(L10n.resolvesChinese(
            language: .simplifiedChinese,
            preferredLanguages: ["en-US"]
        ))
        XCTAssertFalse(L10n.resolvesChinese(
            language: .english,
            preferredLanguages: ["zh-Hans-CN"]
        ))
    }

    func testLanguageOptionNamesFollowCurrentInterfaceLanguage() {
        XCTAssertEqual(
            AppLanguage.allCases.map {
                L10n.languageName($0, displayedIn: .simplifiedChinese)
            },
            ["跟随系统", "中文", "英语"]
        )
        XCTAssertEqual(
            AppLanguage.allCases.map {
                L10n.languageName($0, displayedIn: .english)
            },
            ["Follow System", "Chinese", "English"]
        )
    }
}
