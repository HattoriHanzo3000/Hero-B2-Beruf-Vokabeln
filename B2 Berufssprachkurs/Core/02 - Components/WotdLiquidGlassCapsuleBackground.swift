//
//  WotdLiquidGlassCapsuleBackground.swift
//  B2 Berufssprachkurs
//
//  Cockpit WOTD rows: regular material + App Green tint. Üben controls use separate styling.
//

import SwiftUI

struct WotdLiquidGlassCapsuleBackground: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
            Capsule(style: .continuous)
                .fill(Color("AppGreen").opacity(0.75))
        }
    }
}
