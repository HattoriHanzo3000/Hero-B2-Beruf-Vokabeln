//
//  AdjectivesView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AdjectivesView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToStudy = false
    
    private var liquidGlassCircle: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    var hasAnySelection: Bool {
        dataService.hasAnyAdjektiveCompleted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.purple.opacity(0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.purple)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(.white.opacity(0.25), lineWidth: 0.6)
                                )
                            Image(systemName: "square.stack.3d.up.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                        }
                        
                        Text(Localizable.string(Localizable.adjectivesWithPrepositions))
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            HapticManager.shared.lightImpact()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(liquidGlassCircle)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityLabel("Close")
                        .accessibilityHint("Close this view")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .top)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 12)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    ZStack(alignment: .bottom) {
                        AdjectivesListView(dataService: dataService)
                            .padding(.top, 12)
                            .padding(.bottom, 90) // Space for button
                        
                        // Üben button at the bottom
                        Button {
                            HapticManager.shared.mediumImpact()
                            navigateToStudy = true
                        } label: {
                            Text(Localizable.string(Localizable.practice))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.purple)
                                )
                                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!hasAnySelection)
                        .opacity(hasAnySelection ? 1.0 : 0.5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToStudy) {
                StudyView(
                    dataService: dataService,
                    filterBySectionId: nil, // Adjectives: process all adjektive sections
                    studyAllMode: dataService.isAdjektiveCompleted(), // Study all if all adjektive are checked
                    categoryFilter: "ADJEKTIVE_" // Only load ADJEKTIVE_ sections
                )
                .environmentObject(dataService)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AdjectivesView()
        .environmentObject(DataService())
}

