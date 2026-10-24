//
//  FontRegistrar.swift
//  AIChat2
//

import CoreText
import Foundation

/// Регистрирует Inter из бандла. Info.plist генерируется Xcode (`UIAppFonts` туда
/// не попадает), поэтому шрифты подключаем в рантайме при запуске.
enum FontRegistrar {
    private static let fontNames = ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold"]
    
    static func registerFonts(in bundle: Bundle = .main) {
        for name in fontNames {
            guard let url = bundle.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
