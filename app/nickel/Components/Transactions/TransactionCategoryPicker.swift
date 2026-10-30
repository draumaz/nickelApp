//
//  TransactionCategoryPicker.swift
//  nickel
//
//  Created by Rafael Soh on 20/11/23.
//

import CoreData
import Foundation
import SwiftUI

struct NewCategoryPickerView: View {
    @Binding var category: Category?
    @Binding var showPicker: Bool
    @Binding var showingCategoryView: Bool
    @FetchRequest private var categories: FetchedResults<Category>

    let layout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: layout, spacing: 10) {
                ForEach(categories) { item in
                    categoryButton(for: item)
                }
            }
        }
        // The Edit control floats above the grid in the controls layer, so the grid scrolls
        // beneath it with a soft scroll edge effect rather than a hand-drawn shadow.
        .safeAreaBar(edge: .bottom) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPicker = false
                showingCategoryView = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .padding(.vertical, 10)
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .keyboardAwareHeight(showToolbar: false)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// A tinted chip for a single category. Chips are content, so they use the category colour
    /// rather than Liquid Glass, which is reserved for the floating controls above them.
    private func categoryButton(for item: Category) -> some View {
        let colour = Color(hex: item.wrappedColour)
        let isSelected = item == category

        return Button {
            withAnimation {
                category = item
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showPicker = false
                }
            }
        } label: {
            HStack(spacing: 7) {
                Text(item.wrappedEmoji)
                    .font(.system(.subheadline, design: .rounded))

                Text(item.wrappedName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundStyle(colour)
            .background(colour.opacity(isSelected ? 0.45 : 0.3), in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(colour, lineWidth: 2)
                }
            }
            .contentShape(.rect(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .id(item.id)
        .opacity(category == nil || isSelected ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    init(
        category: Binding<Category?>?, showPicker: Binding<Bool>, showSheet: Binding<Bool>,
        income: Bool
    ) {
        _categories = FetchRequest<Category>(
            sortDescriptors: [
                SortDescriptor(\.order, order: .reverse)
            ], predicate: NSPredicate(format: "income = %d", income))

        _category = category ?? Binding.constant(nil)
        _showPicker = showPicker
        _showingCategoryView = showSheet
    }
}
