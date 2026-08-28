import Foundation

enum AppLanguage: String, CaseIterable {
    case system
    case simplifiedChinese
    case english
}

enum L10n {
    private static let languageKey = "preferredLanguage"

    static var language: AppLanguage {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: languageKey),
                  let language = AppLanguage(rawValue: rawValue)
            else { return .system }
            return language
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
        }
    }

    static var isChinese: Bool {
        switch language {
        case .simplifiedChinese:
            return true
        case .english:
            return false
        case .system:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
        }
    }

    static var locale: Locale {
        Locale(identifier: isChinese ? "zh_CN" : "en_US")
    }

    static func text(_ chinese: String, _ english: String) -> String {
        isChinese ? chinese : english
    }

    static func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return text("跟随系统", "Follow System")
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
}
