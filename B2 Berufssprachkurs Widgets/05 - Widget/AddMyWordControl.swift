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
                    systemImage: "plus"
                )
            }
        }
        .displayName("Quick Add")
        .description("Add a word from the Lock Screen.")
    }
}
