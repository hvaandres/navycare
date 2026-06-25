//
//  DocumentsView.swift
//  navycare
//
//  Documents — medical records, reports, and files.
//

import SwiftUI

struct DocumentsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    Text("Documents")
                        .font(.title2.bold())

                    Text("Your medical records and files will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("Documents")
        }
    }
}

#Preview {
    DocumentsView()
}
