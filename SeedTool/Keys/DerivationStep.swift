//
//  DerivationStep.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 1/22/21.
//

import Foundation
import URKit

struct DerivationStep {
    let childIndexSpec: ChildIndexSpec
    let isHardened: Bool
    
    init(_ childIndexSpec: ChildIndexSpec, isHardened: Bool) {
        self.childIndexSpec = childIndexSpec
        self.isHardened = isHardened
    }
    
    init(_ index: UInt32, isHardened: Bool) {
        try! self.init(ChildIndexSpec.index(ChildIndex(index)), isHardened: isHardened)
    }
    
    var array: [CBOR] {
        [childIndexSpec.cbor, CBOR.boolean(isHardened)]
    }
    
    func childNum() throws -> UInt32 {
        guard case let ChildIndexSpec.index(childIndex) = childIndexSpec else {
            throw GeneralError("Inspecific child number in derivation path.")
        }
        return isHardened ? childIndex.value | 0x80000000 : childIndex.value
    }
}

extension DerivationStep: CustomStringConvertible {
    var description: String {
        childIndexSpec.description + (isHardened ? "'" : "")
    }
}
