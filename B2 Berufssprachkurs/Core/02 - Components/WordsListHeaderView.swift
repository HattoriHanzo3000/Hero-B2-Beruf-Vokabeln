//
//  WordsListHeaderView.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct WordsListHeaderView: View {
    let stackColor: Color
    let stackIcon: String
    let lectionTitle: String
    let sectionTitle: String
    let lectionNumber: String
    let sectionLetter: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stackColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 0.6)
                    )
                Image(systemName: stackIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 6) {
                if !lectionTitle.isEmpty && !sectionTitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if !lectionNumber.isEmpty {
                                Text(lectionNumber)
                                    .font(.system(.title3, design: .default, weight: .regular))
                                    .foregroundColor(.primary)
                            }
                            Text(lectionTitle)
                                .font(.system(.title3, design: .default, weight: .regular))
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: 6) {
                            if !sectionLetter.isEmpty {
                                Text(sectionLetter.uppercased())
                                    .font(.system(.headline, design: .default, weight: .light))
                                    .foregroundColor(.primary)
                            }
                            Text(sectionTitle)
                                .font(.system(.headline, design: .default, weight: .light))
                                .foregroundColor(.primary)
                        }
                    }
                } else if !sectionTitle.isEmpty {
                    Text(sectionTitle)
                        .font(.system(.title2, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 16)
    }
}
