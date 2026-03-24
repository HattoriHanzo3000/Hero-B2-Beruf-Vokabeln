//
//  DynamicTypeSizeLimiter.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

extension View {
    func limitDynamicTypeSize() -> some View {
        // Limit Dynamic Type scale up to XXXLarge to preserve layout integrity
        self.dynamicTypeSize(.xSmall ... .xxxLarge)
    }
}

