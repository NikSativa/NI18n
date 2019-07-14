import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NI18n

private struct Options: OptionSet {
    public let rawValue: Int

    static let emptyFile = Options(rawValue: 1 << 0)
    static let unusedAppKeys = Options(rawValue: 1 << 1)
    static let unusedFileKeys = Options(rawValue: 1 << 2)

    static let correct: Options = [.unusedAppKeys, .unusedFileKeys]
}

class I18nKeysSpec: QuickSpec {
    func test<Key: I18nKeys>(_: Key.Type, bundle: Bundle = .main, fileName: String) {
        test(Key.self, bundle: bundle, fileName: fileName, options: .correct)
    }

    fileprivate func test<Key: I18nKeys>(_: Key.Type, bundle: Bundle = .main, fileName: String, options: Options) {
        describe(String(describing: Key.self) + " " + fileName) {
            var fromFile: [String: String]!
            var allKeys: [String]!

            beforeEach {
                if let url = bundle.url(forResource: fileName, withExtension: "strings") {
                    fromFile = (NSDictionary(contentsOf: url) as? [String: String]) ?? [:]
                }

                allKeys = Key.allCases.map { $0.rawValue }
            }

            if options.contains(.emptyFile) {
                it("should be empty") {
                    let unique = Set(fromFile.keys)
                    expect(unique).to(beEmpty())
                }
            } else {
                it("should not be empty") {
                    let unique = Set(fromFile.keys)
                    expect(unique).toNot(beEmpty())
                }

                it("should not contain duplicates in app keys") {
                    let unique = Set(allKeys)
                    expect(unique.count).to(equal(allKeys.count))
                }

                it("should not contain duplicates in file keys") {
                    let unique = Set(fromFile.keys)
                    expect(unique.count).to(equal(fromFile.count))
                }

                if options.contains(.unusedFileKeys) {
                    it("should not contain unused strings in file") {
                        var filtered = fromFile
                        allKeys.forEach { filtered?.removeValue(forKey: $0) }
                        expect(filtered).to(beEmpty(), description: "unused keys: " + String(describing: filtered))
                    }
                }

                if options.contains(.unusedAppKeys) {
                    it("should not contain unused strings in app") {
                        let filtered = allKeys.filter {
                            fromFile[$0] == nil
                        }
                        expect(filtered).to(beEmpty(), description: "unused keys: " + String(describing: filtered))
                    }
                }
            }
        }
    }
}

class TestI18nKeysSpec: I18nKeysSpec {
    enum TestI18n: String, I18nKeys {
        case forTest
    }

    enum TestI18n2: String, I18nKeys {
        case forTest
        case forTest2
    }

    override func spec() {
        test(TestI18n.self,
             bundle: Bundle(for: TestI18nKeysSpec.self),
             fileName: "TestI18nCorrect",
             options: .correct)
        test(TestI18n.self,
             bundle: Bundle(for: TestI18nKeysSpec.self),
             fileName: "TestI18nEmpty",
             options: .emptyFile)
        test(TestI18n.self,
             bundle: Bundle(for: TestI18nKeysSpec.self),
             fileName: "TestI18nUnused",
             options: Options.correct.subtracting(.unusedFileKeys))
        test(TestI18n2.self,
             bundle: Bundle(for: TestI18nKeysSpec.self),
             fileName: "TestI18nUndefined",
             options: Options.correct.subtracting(.unusedAppKeys))
    }
}