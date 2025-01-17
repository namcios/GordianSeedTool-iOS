//
//  BackupPage.swift
//  Gordian Seed Tool
//
//  Created by Wolf McNally on 2/11/21.
//

import SwiftUI
import URUI

struct BackupPage<Subject, Footer>: View where Subject: ModelObject, Footer: View {
    let subject: Subject
    let footer: Footer

    let margins: CGFloat = pointsPerInch * 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 0.25 * pointsPerInch) {
                identity
                Spacer()
                qrCode
            }
            .frame(height: pointsPerInch * 2.0)

            footer

            Spacer()
        }
        .padding(margins)
        .environment(\.sizeCategory, .extraLarge)
    }
    
    var identity: some View {
        ModelObjectIdentity(model: .constant(subject), allowLongPressCopy: false, generateLifeHashAsync: false, lifeHashWeight: 0.5)
    }
    
    var qrCode: some View {
        let message = subject.sizeLimitedURString.uppercased().data
        let uiImage = makeQRCodeImage(message, correctionLevel: .low)
        let scaledImage = uiImage.scaled(by: 8)
        return Image(uiImage: scaledImage)
            .renderingMode(.template)
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#if DEBUG

import WolfLorem

struct BackupPage_Previews: PreviewProvider {
    static let seed: Seed = { Lorem.seed() }()
    static let privateKey: HDKey = { HDKey(seed: seed) }()
    
    static var previews: some View {
        BackupPage(subject: seed, footer: EmptyView())
            .previewLayout(.fixed(width: 8.5 * pointsPerInch, height: 11 * pointsPerInch))
    }
}

#endif
