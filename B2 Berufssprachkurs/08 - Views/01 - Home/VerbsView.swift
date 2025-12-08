//
//  VerbsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct VerbsView: View {
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
        dataService.hasAnyVerbenCompleted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBlue").opacity(0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header similar to main screen - no corners, infinite to top
                    ZStack(alignment: .top) {
                        // Background that extends to top edge
                        Rectangle()
                            .fill(Color("AppBlue"))
                            .ignoresSafeArea(edges: .top)
                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        
                        // Content that respects safe area
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                            }
                            
                            Text(Localizable.string(Localizable.verbsWithPrepositions))
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                HapticManager.shared.lightImpact()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(liquidGlassCircle)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Close")
                            .accessibilityHint("Close this view")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top)
                        .padding(.bottom, 24)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // Content area: list of words/sections
                    ZStack(alignment: .bottom) {
                        VerbsListView(dataService: dataService)
                            .padding(.bottom, 87) // Space for footer (border 0.5 + padding 16 + button 50 + padding 20 = 86.5)
                        
                        // Footer with border and button
                        VStack(spacing: 0) {
                            // Thin border line
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 0.5)
                            
                            // Üben button at the bottom
                            Button {
                                HapticManager.shared.mediumImpact()
                                navigateToStudy = true
                            } label: {
                                Text(Localizable.string(Localizable.practice))
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color("AppBlue"))
                                    )
                                    .shadow(color: Color("AppBlue").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(!hasAnySelection)
                            .opacity(hasAnySelection ? 1.0 : 0.5)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToStudy) {
                StudyView(
                    dataService: dataService,
                    filterBySectionId: nil, // Verbs: process all verben sections
                    studyAllMode: dataService.isVerbenCompleted(), // Study all if all verben are checked
                    categoryFilter: "VERBEN_" // Only load VERBEN_ sections
                )
                .environmentObject(dataService)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    VerbsView()
        .environmentObject(DataService())
}

