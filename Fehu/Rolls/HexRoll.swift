//
//  HexRoll.swift
//  Fehu
//
//  Created by Wolf McNally on 12/6/20.
//

import SwiftUI

final class HexRoll: Roll {
    let id: UUID = UUID()
    let value: UInt8

    init(value: UInt8) {
        self.value = value
    }

    convenience init(highDigit: Int, lowDigit: Int) {
        self.init(value: UInt8((highDigit & 0xf) << 4) | UInt8(lowDigit & 0xf))
    }

    static func random<T>(using generator: inout T) -> HexRoll where T : RandomNumberGenerator {
        HexRoll(value: UInt8.random(in: 0...255))
    }
}

extension HexRoll: ValueViewable {
    static var minimumWidth: CGFloat { 40 }

    var view: AnyView {
        AnyView(
            Text(String(format: "%02X", value))
            .font(regularFont(size: 18))
            .padding(5)
            .background(Color.gray.opacity(0.7))
            .cornerRadius(5)
        )
    }

    static func values(from string: String) -> [HexRoll]? {
        guard let data = Data(hex: string) else { return nil }
        return data.map { HexRoll(value: $0) }
    }

    static func string(from values: [HexRoll]) -> String {
        Data(values.map { $0.value }).hex
    }
}