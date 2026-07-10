// FilesView.swift
// navycare — Documents Feature
//
// Root view for the secure document vault. Orchestrates the animated
// background, header, search, smart dashboard, category filter,
// document grid, upload FAB, and empty state.

import SwiftUI

struct FilesView: View {

    @State private var viewModel = FilesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 0 — animated background
                AnimatedVaultBackground()

                if viewModel.isEmpty && viewModel.searchText.isEmpty {
                    // Empty state
                    EmptyVaultView {
                        viewModel.showingUploadMenu = true
                    }
                } else {
                    mainContent
                }

                // FAB — bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        UploadFABView(
                            isExpanded: $viewModel.showingUploadMenu,
                            actions:    viewModel.uploadActions,
                            onAction:   { action in
                                // TODO: Wire to upload handlers
                                print("Upload action: \(action.label)")
                            }
                        )
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        // Document detail sheet
        .sheet(isPresented: $viewModel.showingDetail) {
            if let doc = viewModel.selectedDocument {
                FileDetailView(
                    document:  doc,
                    onFavorite: { viewModel.toggleFavorite(doc) },
                    onShare:   {
                        viewModel.showingDetail = false
                        viewModel.showingShare  = true
                    },
                    onDelete: {
                        viewModel.deleteDocument(doc)
                        viewModel.showingDetail = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
        // Share sheet
        .sheet(isPresented: $viewModel.showingShare) {
            if let doc = viewModel.selectedDocument {
                FileShareView(document: doc)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Safe area top spacer
                Spacer(minLength: 60)

                // Header
                StorageHeaderView(
                    storageUsed:     viewModel.formattedStorage,
                    storageProgress: viewModel.storageProgress,
                    layoutMode:      viewModel.layoutMode,
                    onLayoutToggle: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.layoutMode = viewModel.layoutMode == .grid ? .list : .grid
                        }
                    }
                )
                .padding(.bottom, 20)

                // Search
                FilesSearchBarView(
                    searchText:     $viewModel.searchText,
                    isSearchActive: $viewModel.isSearchActive
                )
                .padding(.bottom, 20)

                // AI Suggestions
                SmartSuggestionsView(
                    suggestions: viewModel.suggestions,
                    onDismiss:   viewModel.dismissSuggestion
                )
                .padding(.bottom, 16)

                // Smart Dashboard — hidden during active search
                if !viewModel.isSearchActive {
                    SmartDashboardView(cards: viewModel.smartCards)
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Category filter
                CategoryBubbleView(selectedCategory: $viewModel.selectedCategory)
                    .padding(.bottom, 16)

                // Document grid
                DocumentGridView(
                    documents:  viewModel.filteredDocuments,
                    layoutMode: viewModel.layoutMode,
                    onTap:      { viewModel.selectDocument($0) },
                    onFavorite: { viewModel.toggleFavorite($0) }
                )
                .padding(.bottom, 120) // bottom padding for FAB
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSearchActive)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Preview

#Preview {
    FilesView()
}
