//
//  BitKeypad.swift
//  Fehu
//
//  Created by Wolf McNally on 12/6/20.
//

import SwiftUI

struct BitKeypad: View, Keypad {
    typealias TokenType = BitToken

    @ObservedObject var model: KeypadViewModel<BitKeypad>

    static let name: String = "Coin Flips"
    static let entropyBitsPerValue: Double = 1
    @State var selectedValues: [Bool] = []

    init(model: KeypadViewModel<BitKeypad>) {
        self.model = model
    }

    private func sync() {
        guard !selectedValues.isEmpty else { return }
        model.values.append(BitToken(value: selectedValues.first!))
        selectedValues.removeAll()
    }

    private func buttonFor(_ value: Bool, key: KeyEquivalent) -> KeypadButton<Bool> {
        KeypadButton(value: value, selectedValues: $selectedValues, string: BitToken.symbol(for: value), key: key)
    }

    var body: some View {
        VStack {
            HStack {
                buttonFor(true, key: "h")
                buttonFor(false, key: "t")
            }
            KeypadFunctionButtons(model: model) {
                selectedValues.removeAll()
            }
        }
        .onChange(of: selectedValues) { _ in
            self.sync()
        }
        .onChange(of: selectedValues) { _ in
            self.sync()
        }
    }
}