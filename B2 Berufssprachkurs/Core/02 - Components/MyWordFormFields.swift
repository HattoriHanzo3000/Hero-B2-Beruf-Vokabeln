//
//  MyWordFormFields.swift
//  B2 Berufssprachkurs
//
//  Shared form fields for add / edit “My Words” sheets.
//

import SwiftUI

enum MyWordFormFieldHelpers {
    @ViewBuilder
    static func multilineField(
        _ placeholder: String,
        text: Binding<String>,
        focusedField: FocusState<MyWordSheetField?>.Binding,
        field: MyWordSheetField,
        autocapitalize: TextInputAutocapitalization? = nil
    ) -> some View {
        if let style = autocapitalize {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .textInputAutocapitalization(style)
                .focused(focusedField, equals: field)
        } else {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .focused(focusedField, equals: field)
        }
    }
}

enum MyWordSheetField: Int, CaseIterable {
    case german
    case translation
    case example
    case explanation
    case synonym

    var previous: Self? {
        guard rawValue > 0 else { return nil }
        return Self(rawValue: rawValue - 1)
    }

    var next: Self? {
        Self(rawValue: rawValue + 1)
    }
}

struct MyWordFormFields: View {
    @Binding var german: String
    @Binding var translation: String
    @Binding var example: String
    @Binding var explanation: String
    @Binding var synonym: String
    let focusedField: FocusState<MyWordSheetField?>.Binding

    var body: some View {
        SwiftUI.Section {
            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.myWordsWordOrPhrase),
                text: $german,
                focusedField: focusedField,
                field: .german,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.translation),
                text: $translation,
                focusedField: focusedField,
                field: .translation,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.myWordsExampleLabel),
                text: $example,
                focusedField: focusedField,
                field: .example,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.explanation),
                text: $explanation,
                focusedField: focusedField,
                field: .explanation,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.synonym),
                text: $synonym,
                focusedField: focusedField,
                field: .synonym,
                autocapitalize: .never
            )
        }
    }
}
