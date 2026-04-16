//
//  WidgetsBundle.swift
//  B2 Berufssprachkurs
//
//  Widget bundle entry point for the Hero B2 widget extension.
//  Created: 08.04.26.
//

import SwiftUI
import WidgetKit

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        WordOfTheDayWidget()
        FlashCardsLockWidget()
        if #available(iOS 18.0, *) {
            AddMyWordControl()
        }
    }
}
