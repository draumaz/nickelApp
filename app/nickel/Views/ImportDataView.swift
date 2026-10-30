//
//  ImportDataView.swift
//  nickel
//
//  Created by Rafael Soh on 21/8/23.
//

import ConfettiSwiftUI
import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ColumnLabel {
    let image: String
    let label: String
}

enum ProcessingState {
    case loading, success, error
}

struct MatchedCategory: Hashable {
    let excelValue: String
    var income: Bool
    var category: Category?

    mutating func toggleIncome() {
        income = !income
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController

    @State private var importing = false

    @State private var data = ""
    @State private var rows = [[String]]()
    @State private var numberOfRows: Int = 0
    @State private var displayedColumns = [[String]]()
    @State private var columns = [[String]]()

    @State private var remainingColumns = [Int]()
    @State private var selectedColumns = [Int]()

    var indexColumnWidth: CGFloat {
        let additionalPadding: Double

        if dynamicTypeSize > .xLarge {
            additionalPadding = 10
        } else {
            additionalPadding = 0
        }

        if numberOfRows < 10 {
            return "9".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        } else if numberOfRows < 100 {
            return "99".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        } else {
            return "999".widthOfRoundedString(size: 15, weight: .bold) + 16.0 + additionalPadding
        }
    }

    @State var progress = 1

    @State var selectedColumn = 0
    @State var columnSelectionCompleted = false
    @State var sampleDateString = ""
    @State var dateFormatString = ""
    @State var validDateFormatString = false
    @State var uniqueCategories: [MatchedCategory] = .init()

    @State var processingState = ProcessingState.loading
    @State var errorMessage = "Invalid dates in date column."
    @State var confettiNumber = 0

    /// Number of categories created automatically for CSV values that matched no existing category.
    @State var createdCategoryCount = 0

    @State var showToast = false
    @State var toastMessage: String = "Invalid File"

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var columnWidth: CGFloat {
        if dynamicTypeSize > .xLarge {
            return 150
        } else {
            return 100
        }
    }

    let instructions: [InstructionHeadings] = [
        InstructionHeadings(title: "Import transactions", subtitle: "Begin by adding a CSV file with 4 columns: amount, note, date, and category."),
        InstructionHeadings(title: "Assign category column", subtitle: "Select a column from your import that corresponds to the categories of your transactions."),
        InstructionHeadings(title: "Assign note column", subtitle: "Select a column from your import that corresponds to the notes/subtitles of your transactions."),
        InstructionHeadings(title: "Assign date column", subtitle: "Select a column from your import that corresponds to the dates of your transactions."),
        InstructionHeadings(title: "Assign amount column", subtitle: "Select a column from your import that corresponds to the values of your transactions."),
        InstructionHeadings(title: "Indicate date format", subtitle: "Referencing this article, state the format of the dates in the assigned column."),
        InstructionHeadings(title: "Processing import", subtitle: "Please wait while we process your new transactions.")
    ]

    let labels: [ColumnLabel] = [
        ColumnLabel(image: "square.grid.2x2.fill", label: "Category"),
        ColumnLabel(image: "doc.plaintext.fill", label: "Note"),
        ColumnLabel(image: "calendar", label: "Date"),
        ColumnLabel(image: "dollarsign.circle.fill", label: "Amount")
    ]

    let pointers = ["Ensure that the values in the 'Amount' column do not contain any currency symbols.", "All dates should be of a consistent, recognizable format. If no timestamps are provided, the time of transaction will default to 12:00 am.", "Remove all commas in the 'Note' and 'Category' columns as they would disrupt the parsing of your file."]

    /// Total steps before processing begins, for the progress indicator.
    private let stepCount = 6

    var body: some View {
        VStack(spacing: 0) {
            if progress == 8 {
                VStack(spacing: 15) {
                    switch processingState {
                    case .loading:
                        ProgressView()
                            .controlSize(.large)
                            .scaleEffect(0.8)

                        Text("Processing Import")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.IncomeGreen)
                            .symbolEffect(.bounce, value: processingState)

                        Text("Import Successful")
                            .font(.system(.title2, design: .rounded).weight(.semibold))

                        if createdCategoryCount > 0 {
                            Text("^[\(createdCategoryCount) new category](inflect: true) created")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    case .error:
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.AlertRed)
                            .symbolEffect(.bounce, value: processingState)

                        Text("Import Failed")
                            .font(.system(.title2, design: .rounded).weight(.semibold))

                        Text(errorMessage)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Button {
                        if progress == 2 {
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                progress -= 1
                            }
                        } else if progress > 2 {
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                if let removedColumn = selectedColumns.popLast() {
                                    remainingColumns.append(removedColumn)
                                    remainingColumns.sort()
                                    selectedColumn = remainingColumns[0]
                                    columnSelectionCompleted = false

                                    progress -= 1
                                }
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: progress > 1 ? "chevron.left" : "xmark")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                            .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol))
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(progress > 1 ? "Back" : "Close")

                    Spacer()

                    ProgressView(value: Double(progress), total: Double(stepCount))
                        .progressViewStyle(.linear)
                        .tint(.primary)
                        .frame(width: 60)
                        .accessibilityLabel("Step \(progress) of \(stepCount)")
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

                .overlay {
                    if showToast {
                        HStack(spacing: 6.5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.AlertRed)

                            Text(toastMessage)
                                .font(.system(.callout, design: .rounded).weight(.semibold))

//                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.AlertRed)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .glassEffect(.regular.tint(Color.AlertRed.opacity(0.15)), in: .capsule)
                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                        .frame(width: 250)
                    }
                }
                .padding(.bottom, 50)
                .animation(.easeInOut, value: progress > 1)

                VStack(alignment: .leading, spacing: 5) {
                    if progress == 6 {
                        HStack {
                            Text("Indicate date format")
                                .foregroundColor(.PrimaryText)
                                .font(.system(.title2, design: .rounded).weight(.semibold))

//                                .font(.system(size: 26, weight: .semibold, design: .rounded))

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        Text("Referencing \(makeAttributedString()), state the format of the dates in the assigned column.")
                            .foregroundColor(.SubtitleText)
                            .font(.system(.body, design: .rounded).weight(.medium))

//                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            Text(instructions[progress - 1].title)
                                .foregroundColor(Color.PrimaryText)
                                .font(.system(.title2, design: .rounded).weight(.semibold))

//                                .font(.system(size: 26, weight: .semibold, design: .rounded))

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        Text(instructions[progress - 1].subtitle)
                            .foregroundColor(.SubtitleText)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: UIScreen.currentBounds.size.height / (dynamicTypeSize > .xLarge ? 5.3 : 5.8), alignment: .top)
                .padding(.bottom, 10)

                if progress == 1 {
                    Label("Additional Pointers", systemImage: "info.circle.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 14)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            ForEach(pointers.indices, id: \.self) { index in
                                PointerView(number: index + 1, text: pointers[index])
                            }
                        }
                    }
                } else if progress < 6 {
                    VStack(spacing: 10) {
                        Text("Sampled Rows from Import CSV")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    ForEach(0 ..< (numberOfRows + 1), id: \.self) { number in
                                        if number == 0 {
                                            Rectangle()
                                                .fill(Color.PrimaryBackground)
                                                .frame(width: indexColumnWidth, height: 30, alignment: .leading)
                                        } else {
                                            Text("\(number)")
                                                .foregroundStyle(Color.SubtitleText)
                                                .font(.system(.subheadline, design: .rounded).weight(.bold))

//                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 8)
                                                .frame(width: indexColumnWidth, height: 30, alignment: .leading)
                                                .overlay(Rectangle().stroke(Color.Outline, lineWidth: 1))
                                        }
                                    }
                                }
                                .background(Color.SecondaryBackground.opacity(0.6))

                                HStack(spacing: 0) {
                                    ForEach(displayedColumns.indices, id: \.self) { columnIndex in

                                        VStack(spacing: 0) {
                                            if selectedColumns.contains(columnIndex) {
                                                if let index = selectedColumns.firstIndex(of: columnIndex) {
                                                    HStack(spacing: 4.5) {
                                                        Image(systemName: labels[index].image)
                                                            .font(.system(.caption, design: .rounded).weight(.semibold))

//                                                            .font(.system(size: 12, weight: .semibold, design: .rounded))

                                                        Text(labels[index].label)
                                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .frame(width: columnWidth, height: 30, alignment: .leading)
                                                    .foregroundColor(Color(labels[index].label))
                                                    .background(Color(labels[index].label).opacity(0.23), in: RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                                                }
                                            } else {
                                                Rectangle()
                                                    .fill(Color.PrimaryBackground)
                                                    .frame(width: columnWidth, height: 30, alignment: .leading)
                                            }

                                            VStack(spacing: 0) {
                                                ForEach(displayedColumns[columnIndex], id: \.self) { value in
                                                    Text(value)
                                                        .foregroundStyle(Color.PrimaryText)
                                                        .font(.system(.subheadline, design: .rounded).weight(.medium))

//                                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                                        .padding(.horizontal, 8)
                                                        .frame(width: columnWidth, height: 30, alignment: .leading)
                                                        .overlay(Rectangle().stroke(Color.Outline, lineWidth: 1))
                                                    //
                                                }
                                            }
                                            .onTapGesture {
                                                if progress >= 2 {
                                                    if remainingColumns.contains(columnIndex) {
                                                        withAnimation {
                                                            selectedColumn = columnIndex
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .overlay(alignment: .leading) {
                                    if !columnSelectionCompleted && progress < 6 {
                                        VStack(spacing: 0) {
                                            HStack(spacing: 4.5) {
                                                Image(systemName: labels[progress - 2].image)
                                                    .font(.system(.caption, design: .rounded).weight(.semibold))

//                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))

                                                Text(labels[progress - 2].label)
                                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 10)
                                            .frame(width: columnWidth + 2, height: 30, alignment: .leading)
                                            .foregroundColor(Color.LightIcon)
                                            .background(Color.DarkBackground, in: RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                                            Rectangle()
                                                .stroke(Color.DarkBackground, lineWidth: 2)
                                                .frame(width: columnWidth)
                                                .frame(maxHeight: .infinity)
                                        }
                                        .offset(x: CGFloat(CGFloat(selectedColumn) * columnWidth))
                                    }
                                }
                            }
                            .padding(2)
                        }
                    }
                } else if progress == 6 {
                    VStack(spacing: 10) {
                        Text("Sample from 'Date' Column")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))

//                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.SubtitleText)

                        Text(sampleDateString)
                            .font(.system(.title3, design: .rounded).weight(.semibold))

//                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: 300, height: 48)
                            .background(.fill.quaternary, in: .rect(cornerRadius: 16))
                            .padding(.bottom, 30)

                        HStack(spacing: 7) {
                            Image(systemName: "calendar")
                                .font(.system(.callout, design: .rounded).weight(.semibold))

//                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.SubtitleText)

                            TextField("Date Format", text: $dateFormatString)
                                .foregroundColor(Color.PrimaryText)
                                .font(.system(.title3, design: .rounded).weight(.semibold))

//                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)

                            if validDateFormatString {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(.callout, design: .rounded).weight(.semibold))

//                                        .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.IncomeGreen)
                            } else if !validDateFormatString && dateFormatString != "" {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(width: 300, height: 48)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
                        .onChange(of: dateFormatString) { _, newValue in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = newValue

                            if dateFormatter.date(from: sampleDateString) != nil {
                                validDateFormatString = true
                            } else {
                                validDateFormatString = false
                            }
                        }
                    }
                }

                Spacer()

                if progress == 1 {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()

                        importing = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)

                } else {
                    Button {
                        if progress == 6 {
                            // Categories are matched or created automatically, so go straight to processing.
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                progress = 8
                            }

                            importData()
                        } else {
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.8)) {
                                guard !remainingColumns.isEmpty else { return }

                                if progress == 4 {
                                    let sample = displayedColumns[selectedColumn][0]

                                    guard sample.containsDigits else {
                                        showToast = true
                                        toastMessage = "Invalid Column"
                                        return
                                    }
                                }

                                if progress == 5 {
                                    let stringColumn = displayedColumns[selectedColumn]

                                    guard validateDoubles(strings: stringColumn) else {
                                        showToast = true
                                        toastMessage = "Invalid Column"
                                        return
                                    }
                                }

                                // remove from possible pool
                                let index = remainingColumns.firstIndex(of: selectedColumn) ?? 0
                                remainingColumns.remove(at: index)

                                // add to holding pool
                                selectedColumns.append(selectedColumn)

                                if progress < 5 {
                                    guard !remainingColumns.isEmpty else {
                                        showToast = true
                                        toastMessage = "Insufficient Columns"
                                        return
                                    }
                                    selectedColumn = remainingColumns[0]
                                }

                                // reset selected column

                                if progress == 5 {
                                    let dateColumnIndex = selectedColumns[2]
                                    sampleDateString = displayedColumns[dateColumnIndex][0]

                                    if let deducedFormat = deduceDateFormat(from: sampleDateString) {
                                        dateFormatString = deducedFormat
                                        validDateFormatString = true
                                    }

                                    uniqueCategories = matchedCategories()

                                    columnSelectionCompleted = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            progress += 1
                                        }
                                    }
                                } else {
                                    progress += 1
                                }
                            }
                        }
                    } label: {
                        Text(progress == 6 ? "Import" : "Continue")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(20)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard)
        .background(Color.PrimaryBackground)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            switch result {
            case let .success(file):
                do {
                    if file.startAccessingSecurityScopedResource() {
                        guard let message = try String(data: Data(contentsOf: file), encoding: .utf8) else {
                            showToast = true
                            toastMessage = "Invalid File"
                            return
                        }

                        data = message

                        processCSV()

                        do {
                            file.stopAccessingSecurityScopedResource()
                        }
                    }
                } catch {}
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showToast)
        .onChange(of: showToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showToast = false
                }
            }
        }
        .onChange(of: processingState) { _, newValue in
            if newValue == .success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .confettiCannon(counter: $confettiNumber, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
    }

    func validateDoubles(strings: [String]) -> Bool {
        strings.allSatisfy { Double($0) != nil }
    }

    func processCSV() {
        guard data.containsDigits else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        var holdingRows = data.components(separatedBy: .newlines).filter { $0 != "" }

        if !holdingRows[0].containsDigits {
            holdingRows.removeFirst()
        }

        guard !holdingRows.isEmpty else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        let values = holdingRows.map { $0.components(separatedBy: ",") }.filter { !$0.isEmpty }

        rows = values

        // Transpose rows to columns
        let maxColumnCount = values.map { $0.count }.max() ?? 0
//
        guard maxColumnCount > 3 else {
            showToast = true
            toastMessage = "Invalid File"
            return
        }

        var holdingColumns: [[String]] = Array(repeating: [], count: maxColumnCount)

        for row in values {
            for (index, value) in row.enumerated() {
                holdingColumns[index].append(value)
            }
        }

        columns = holdingColumns

        displayedColumns = holdingColumns.map { $0.prefix(8).map { $0 } }

        numberOfRows = displayedColumns[0].count

        remainingColumns = Array(0 ..< maxColumnCount)

        withAnimation {
            progress += 1
        }
    }

    func importData() {
        let categoryColumnIndex = selectedColumns[0]
        let noteColumnIndex = selectedColumns[1]
        let dateColumnIndex = selectedColumns[2]
        let amountColumnIndex = selectedColumns[3]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormatString

        let categoryDictionary = resolveCategories()

        rows.forEach { row in
//            let rowCategory = categoryDictionary[row[categoryColumnIndex]]
            if let transactionDate = dateFormatter.date(from: row[dateColumnIndex]) {
                if let rowCategory = categoryDictionary[row[categoryColumnIndex]] {
                    if let transactionAmount = Double(row[amountColumnIndex]) {
                        _ = dataController.newTransaction(note: row[noteColumnIndex], category: rowCategory, income: rowCategory.income, amount: abs(transactionAmount), date: transactionDate, repeatType: 0, repeatCoefficient: 1, delay: false)
                    } else {
                        processingState = .error
                        errorMessage = "Invalid values in amount column."
                        return
                    }
                } else {
                    processingState = .error
                    errorMessage = "Error occurred while matching categories."
                    return
                }
            } else {
                processingState = .error
                errorMessage = "Invalid dates in date column."
                return
            }
        }

        dataController.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                processingState = .success
                confettiNumber += 1
            }
        }
    }

    /// Index of an unassigned column whose values are all "Income" or "Expense", if the file has one.
    func typeColumnIndex() -> Int? {
        remainingColumns.first { index in
            let values = rows.map { $0.indices.contains(index) ? $0[index].trimmingCharacters(in: .whitespaces).lowercased() : "" }
            return !values.isEmpty && values.allSatisfy { $0 == "income" || $0 == "expense" }
        }
    }

    /// The distinct values of the category column, each marked income or expense. The type comes
    /// from a Type column when present (by majority for that value); otherwise it defaults to expense.
    func matchedCategories() -> [MatchedCategory] {
        let categoryColumnIndex = selectedColumns[0]
        let typeIndex = typeColumnIndex()

        var incomeVotes = [String: Int]()
        if let typeIndex {
            for row in rows where row.indices.contains(categoryColumnIndex) && row.indices.contains(typeIndex) {
                let isIncome = row[typeIndex].trimmingCharacters(in: .whitespaces).lowercased() == "income"
                incomeVotes[row[categoryColumnIndex], default: 0] += isIncome ? 1 : -1
            }
        }

        return columns[categoryColumnIndex].unique().map { value in
            MatchedCategory(excelValue: value, income: (incomeVotes[value] ?? -1) > 0)
        }
    }

    /// Maps every category value in the CSV to a Nickel category: an existing one with the same name
    /// (ignoring case and surrounding spaces) and type, or a newly created one.
    func resolveCategories() -> [String: Category] {
        let normalize = { (name: String) in name.trimmingCharacters(in: .whitespaces).lowercased() }

        var existing = dataController.getAllCategories(income: false) + dataController.getAllCategories(income: true)
        var unusedColours = Color.colorArray.filter { colour in !existing.contains { $0.wrappedColour == colour } }
        let suggestions = SuggestedCategory.expenses + SuggestedCategory.incomes

        var resolved = [String: Category]()
        var created = 0

        for matched in uniqueCategories {
            let name = matched.excelValue.trimmingCharacters(in: .whitespaces)
            let key = normalize(name)

            if let match = existing.first(where: { normalize($0.wrappedName) == key && $0.income == matched.income }) {
                resolved[matched.excelValue] = match
                continue
            }

            let category = Category(context: dataController.container.viewContext)
            category.name = name.isEmpty ? String(localized: "Other") : name
            category.emoji = suggestions.first { normalize($0.name) == key }?.emoji ?? "🏷️"
            category.dateCreated = Date.now
            category.id = UUID()
            category.income = matched.income

            if matched.income {
                category.colour = "#76FBB0"
            } else {
                if unusedColours.isEmpty {
                    unusedColours = Color.colorArray
                }
                category.colour = unusedColours.removeFirst()
            }

            let sameType = existing.filter { $0.income == matched.income }
            category.order = (sameType.map(\.order).max() ?? -1) + 1

            existing.append(category)
            resolved[matched.excelValue] = category
            created += 1
        }

        createdCategoryCount = created
        return resolved
    }

    func deduceDateFormat(from dateString: String) -> String? {
        let dateFormats = ["yyyy-MM-dd", "dd-MM-yyyy", "MM-dd-yyyy",
                           "yyyy/MM/dd", "dd/MM/yyyy", "MM/dd/yyyy",
                           "yyyyMMdd", "ddMMyyyy", "MMddyyyy", "yyyy-MM-dd HH:mm:ss Z",
                           "dd/MM/yyyy HH:mm:ss"]

        let dateFormatter = DateFormatter()

        for dateFormat in dateFormats {
            dateFormatter.dateFormat = dateFormat
            if dateFormatter.date(from: dateString) != nil {
                return dateFormat
            }
        }

        return nil
    }

    func makeAttributedString() -> AttributedString {
        var string = AttributedString("this article")
        string.foregroundColor = Color.PrimaryText
        string.link = URL(string: "https://pro.arcgis.com/en/pro-app/latest/help/mapping/time/convert-string-or-numeric-time-values-into-data-format.htm")
        string.underlineColor = UIColor(Color.PrimaryText)
        string.underlineStyle = .single

        return string
    }

    @ViewBuilder
    func PointerView(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.fill.tertiary, in: .circle)

            Text(text)
                .font(.system(.body, design: .rounded).weight(.medium))

//                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
