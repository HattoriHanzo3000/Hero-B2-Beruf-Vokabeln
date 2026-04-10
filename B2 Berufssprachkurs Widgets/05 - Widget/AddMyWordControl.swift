import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct AddMyWordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "AddMyWordControl") {
            ControlWidgetButton(action: AddMyWordControlIntent()) {
                Label(
                    NSLocalizedString("my_words_add_word", tableName: "Localizable", comment: ""),
                    systemImage: "rectangle.stack.fill.badge.plus"
                )
            }
        }
        .displayName(LocalizedStringResource("widget_add_my_word_control_display_name"))
        .description(LocalizedStringResource("widget_add_my_word_control_description"))
    }
}
