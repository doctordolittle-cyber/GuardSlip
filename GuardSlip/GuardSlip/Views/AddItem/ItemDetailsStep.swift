import SwiftUI

struct ItemDetailsStep: View {
    @ObservedObject var viewModel: AddItemViewModel
    @State private var showingBarcodeScanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                nameField
                storeAndBrandFields
                categoryPicker
                purchaseDatePicker
                warrantyDurationPicker
                priceField
                serialNumberField
                notesField
                reminderSection
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { code in
                viewModel.serialNumber = code
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Item Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("TextSecondary"))
                Text("*")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color("StatusExpired"))
            }

            TextField("e.g. MacBook Pro 14\"", text: $viewModel.name)
                .textFieldStyle(DarkTextFieldStyle())
        }
    }

    private var storeAndBrandFields: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Store / Seller")
                TextField("e.g. Apple Store", text: $viewModel.store)
                    .textFieldStyle(DarkTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Brand")
                TextField("e.g. Apple", text: $viewModel.brand)
                    .textFieldStyle(DarkTextFieldStyle())
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Category")

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 90), spacing: 8)
            ], spacing: 8) {
                ForEach(Category.allCases) { category in
                    categoryButton(category)
                }
            }
        }
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = viewModel.category == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.category = category
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 16))
                Text(category.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Color("AccentPrimary") : Color("TextSecondary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color("AccentPrimary") : Color("DividerColor"), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
    }

    private var purchaseDatePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                fieldLabel("Purchase Date")
                if viewModel.detectedDate != nil {
                    Text("Detected from receipt")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("AccentSecondary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("AccentSecondary").opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            DatePicker("", selection: $viewModel.purchaseDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color("AccentPrimary"))
                .padding(12)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .colorScheme(.dark)
        }
    }

    private var warrantyDurationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Warranty Duration")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WarrantyDuration.allCases) { duration in
                        durationChip(duration)
                    }
                }
            }

            if viewModel.warrantyDuration == .custom {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom Expiry Date")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color("TextTertiary"))

                    DatePicker("", selection: $viewModel.customExpiryDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Color("AccentPrimary"))
                        .padding(12)
                        .background(Color("BackgroundSecondary"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .colorScheme(.dark)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func durationChip(_ duration: WarrantyDuration) -> some View {
        let isSelected = viewModel.warrantyDuration == duration
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.warrantyDuration = duration
            }
        } label: {
            Text(duration.rawValue)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color("BackgroundPrimary") : Color("TextSecondary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color("AccentPrimary") : Color("BackgroundSecondary"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color("DividerColor"), lineWidth: 0.5)
                )
        }
    }

    private var priceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Price (optional)")

            HStack(spacing: 0) {
                Menu {
                    ForEach(CurrencyOption.all) { currency in
                        Button {
                            viewModel.selectedCurrency = currency.code
                        } label: {
                            HStack {
                                Text("\(currency.symbol) \(currency.code)")
                                if viewModel.selectedCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(CurrencyOption.find(by: viewModel.selectedCurrency).symbol)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(Color("AccentPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }

                Rectangle()
                    .fill(Color("DividerColor"))
                    .frame(width: 0.5)
                    .padding(.vertical, 6)

                TextField("0.00", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(Color("TextPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var serialNumberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Serial Number (optional)")

            HStack(spacing: 8) {
                TextField("Enter serial number", text: $viewModel.serialNumber)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(Color("TextPrimary"))

                Button {
                    showingBarcodeScanner = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("AccentPrimary"))
                }
            }
            .padding(12)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                fieldLabel("Notes (optional)")
                Spacer()
                Text("\(viewModel.notes.count)/500")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("TextTertiary"))
            }

            TextEditor(text: $viewModel.notes)
                .font(.system(size: 14))
                .foregroundColor(Color("TextPrimary"))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(10)
                .background(Color("BackgroundSecondary"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: viewModel.notes) { newValue in
                    if newValue.count > 500 {
                        viewModel.notes = String(newValue.prefix(500))
                    }
                }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color("DividerColor"))
                .frame(height: 0.5)

            Toggle(isOn: $viewModel.remindBeforeExpiry) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color("AccentPrimary"))
                    Text("Remind me before expiry")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("TextPrimary"))
                }
            }
            .tint(Color("AccentPrimary"))

            if viewModel.remindBeforeExpiry {
                HStack(spacing: 8) {
                    ForEach([30, 14, 7, 1], id: \.self) { offset in
                        reminderChip(offset)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func reminderChip(_ days: Int) -> some View {
        let isSelected = viewModel.selectedReminderOffsets.contains(days)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    viewModel.selectedReminderOffsets.remove(days)
                } else {
                    viewModel.selectedReminderOffsets.insert(days)
                }
            }
        } label: {
            Text("\(days)d")
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .monospaced))
                .foregroundColor(isSelected ? Color("BackgroundPrimary") : Color("TextSecondary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color("AccentPrimary") : Color("BackgroundSecondary"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color("DividerColor"), lineWidth: 0.5)
                )
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("TextSecondary"))
    }
}

struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(.system(size: 15))
            .foregroundColor(Color("TextPrimary"))
            .padding(12)
            .background(Color("BackgroundSecondary"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .autocorrectionDisabled()
    }
}
