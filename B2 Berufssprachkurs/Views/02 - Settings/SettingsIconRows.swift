//
//  SettingsIconRows.swift
//  B2 Berufssprachkurs
//
//  Reusable row components used throughout Settings sections.
//  Created: 05.04.26.
//

import SwiftUI

// MARK: - Base Row

struct SettingsIconRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor)
                )

            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(title)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

// MARK: - Navigation Row

struct NavigationIconRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let destination: () -> Destination

    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, @ViewBuilder destination: @escaping () -> Destination) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination()) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
        }
    }
}

// MARK: - Toggle Row

struct ToggleIconRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var tintColor: Color = .green

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor)
        }
    }
}

// MARK: - Menu Row

struct MenuIconRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let options: [String]
    @Binding var selection: String
    var displayMapping: ((String) -> String)?

    init(icon: String, iconColor: Color, title: String, options: [String], selection: Binding<String>, displayMapping: ((String) -> String)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.options = options
        self._selection = selection
        self.displayMapping = displayMapping
    }

    private func displayText(for key: String) -> String {
        displayMapping?(key) ?? key
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(displayText(for: option))
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(displayText(for: selection))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Destructive Row

struct DestructiveIconRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            SettingsIconRow(icon: icon, iconColor: .red, title: title)
        }
    }
}

// MARK: - External Link Row

/// Opens a link in the in-app legal web sheet flow, or runs a custom action (e.g. system Settings).
struct SettingsExternalLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var showsTrailingArrow: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                SettingsIconRow(icon: icon, iconColor: iconColor, title: title)
                if showsTrailingArrow {
                    Image(systemName: "arrow.up.right")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
