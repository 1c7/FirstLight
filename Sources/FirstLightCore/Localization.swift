import Foundation

/// 用户可以为 FirstLight 单独选择的显示语言。
///
/// `.system` 不缓存某一种具体语言，而是在每次读取时解析 macOS 当前的
/// 首选语言。因此用户修改系统语言后，应用无需重启即可跟随变化。
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese
    case english

    var id: String { rawValue }
}

/// 应用内轻量级本地化入口。
///
/// 当前产品只支持中英双语，使用成对文案比引入资源包更直观。所有界面应通过
/// `text(_:_:)` 获取文案，不要直接根据 `Locale.current` 分支，避免“跟随系统”
/// 与应用内指定语言出现不一致。
enum L10n {
    private static let languageKey = "preferredLanguage"

    /// 用户保存的语言偏好；首次运行或旧版本没有该字段时默认跟随系统。
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

    /// 当前实际使用的语言。暂时将所有中文地区统一映射为简体中文。
    static var isChinese: Bool {
        resolvesChinese(language: language)
    }

    /// 将保存的偏好和系统首选语言解析成实际语言。
    ///
    /// 参数可注入，便于单元测试，不需要在测试中修改用户电脑的语言设置。
    static func resolvesChinese(
        language: AppLanguage,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> Bool {
        switch language {
        case .simplifiedChinese:
            return true
        case .english:
            return false
        case .system:
            return preferredLanguages.first?.lowercased().hasPrefix("zh") == true
        }
    }

    /// 供数字、日期等 Foundation 格式化器使用的区域设置。
    static var locale: Locale {
        Locale(identifier: isChinese ? "zh_CN" : "en_US")
    }

    /// 根据当前实际语言返回中文或英文文案。
    static func text(_ chinese: String, _ english: String) -> String {
        isChinese ? chinese : english
    }

    /// 语言选择器中显示的本地化名称。
    ///
    /// `displayedIn` 明确指定设置页当前使用的界面语言，避免原生菜单在切换过程中
    /// 读取到旧的全局状态，出现“界面已是英文、选项仍是中文”的混合显示。
    static func languageName(
        _ option: AppLanguage,
        displayedIn interfaceLanguage: AppLanguage = language
    ) -> String {
        let useChinese = resolvesChinese(language: interfaceLanguage)
        switch option {
        case .system:
            return useChinese ? "跟随系统" : "Follow System"
        case .simplifiedChinese:
            return useChinese ? "中文" : "Chinese"
        case .english:
            return useChinese ? "英语" : "English"
        }
    }
}
