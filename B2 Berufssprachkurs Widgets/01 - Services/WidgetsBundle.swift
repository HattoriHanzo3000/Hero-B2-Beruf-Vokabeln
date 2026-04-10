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
