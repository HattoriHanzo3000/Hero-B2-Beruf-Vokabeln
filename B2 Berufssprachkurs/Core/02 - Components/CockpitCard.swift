//
//  CockpitCard.swift
//  B2 Berufssprachkurs
//
//  Shared cockpit chrome — 20pt continuous corners, glass gradient (matches promo banner).
//

import SwiftUI

struct CockpitCard<Content: View>: View {
    let titleIcon: String
    let title: String
    let subtitle: AnyView?
    let useGlassEffect: Bool
    private let titleTrailing: AnyView?
    @ViewBuilder let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        titleIcon: String,
        title: String,
        subtitle: AnyView? = nil,
        useGlassEffect: Bool = true,
        titleTrailing: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.titleIcon = titleIcon
        self.title = title
        self.subtitle = subtitle
        self.useGlassEffect = useGlassEffect
        self.titleTrailing = titleTrailing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: titleIcon)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        LinearGradient(
                            colors: [Color("AppGreen"), Color("AppBlue").opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                Text(title)
                    .font(.system(.title3, design: .default, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                if let titleTrailing {
                    titleTrailing
                }
            }

            if let subtitle {
                subtitle
                    .font(AppFont.subheadlineCondensedRegular(dynamicTypeSize: dynamicTypeSize))
                    .foregroundColor(.secondary)
            }

            content
        }
        .padding(16)
        .background(
            Group {
                if useGlassEffect {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color("AppGreenExtraLight"))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("AppGreenExtraLight"))
                }
            }
        )
        .overlay(
            Group {
                if useGlassEffect {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.35),
                                    .white.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                }
            }
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}
