@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI
import UIKit

private struct LimiarScaledFontModifier: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat

    let weight: Font.Weight
    let design: Font.Design

    init(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design,
        relativeTo textStyle: Font.TextStyle
    ) {
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

enum ReadingTextScalePolicy {
    static let steps = [90, 100, 110, 125, 140, 160]
    static let defaultValue = 100
    static let minimumValue = steps[0]
    static let maximumValue = steps[steps.count - 1]

    static func normalized(_ value: Int) -> Int {
        steps.min { lhs, rhs in
            let lhsDistance = abs(lhs - value)
            let rhsDistance = abs(rhs - value)
            return lhsDistance == rhsDistance ? lhs < rhs : lhsDistance < rhsDistance
        } ?? defaultValue
    }

    static func incremented(_ value: Int) -> Int {
        let current = normalized(value)
        guard let index = steps.firstIndex(of: current), index < steps.count - 1 else {
            return maximumValue
        }
        return steps[index + 1]
    }

    static func decremented(_ value: Int) -> Int {
        let current = normalized(value)
        guard let index = steps.firstIndex(of: current), index > 0 else {
            return minimumValue
        }
        return steps[index - 1]
    }

    /// Compõe a preferência local com o Dynamic Type. O teto numérico é o
    /// fator que o mesmo estilo alcança em `.accessibility3`; assim o ajuste
    /// Aa nunca ultrapassa a categoria máxima escolhida para a leitura.
    static func composedScale(
        value: Int,
        systemScale: Double,
        accessibility3Scale: Double
    ) -> Double {
        let safeSystemScale = max(systemScale, 0)
        let requestedScale = Double(normalized(value)) / 100
        let scaledRequest = max(safeSystemScale * requestedScale, 0.9)
        return min(
            scaledRequest,
            max(accessibility3Scale, 0.9)
        )
    }
}

struct ReadingTextScaleStore {
    static let key = "limiar.reading.textScale"
    nonisolated(unsafe) static let appGroupDefaults = UserDefaults(
        suiteName: ScreenTimePolicyStore.appGroupIdentifier
    ) ?? .standard

    let defaults: UserDefaults

    init(defaults: UserDefaults = appGroupDefaults) {
        self.defaults = defaults
    }

    var value: Int {
        guard defaults.object(forKey: Self.key) != nil else {
            return ReadingTextScalePolicy.defaultValue
        }
        return ReadingTextScalePolicy.normalized(defaults.integer(forKey: Self.key))
    }

    func save(_ value: Int) {
        defaults.set(ReadingTextScalePolicy.normalized(value), forKey: Self.key)
    }
}

private struct LimiarReadingFontModifier: ViewModifier {
    @ScaledMetric private var systemScaledSize: CGFloat

    let baseSize: CGFloat
    let textScale: Int
    let weight: Font.Weight
    let design: Font.Design
    let textStyle: Font.TextStyle

    init(
        size: CGFloat,
        textScale: Int,
        weight: Font.Weight,
        design: Font.Design,
        relativeTo textStyle: Font.TextStyle
    ) {
        _systemScaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        baseSize = size
        self.textScale = textScale
        self.weight = weight
        self.design = design
        self.textStyle = textStyle
    }

    func body(content: Content) -> some View {
        let systemScale = Double(systemScaledSize / baseSize)
        let maximumPointSize = UIFontMetrics(forTextStyle: textStyle.uiTextStyle)
            .scaledValue(
                for: baseSize,
                compatibleWith: UITraitCollection(
                    preferredContentSizeCategory: .accessibilityExtraLarge
                )
            )
        let maximumScale = Double(maximumPointSize / baseSize)
        let composedScale = ReadingTextScalePolicy.composedScale(
            value: textScale,
            systemScale: systemScale,
            accessibility3Scale: maximumScale
        )

        content.font(
            .system(
                size: baseSize * CGFloat(composedScale),
                weight: weight,
                design: design
            )
        )
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .caption: .caption1
        case .caption2: .caption2
        case .footnote: .footnote
        default: .body
        }
    }
}

extension View {
    func limiarFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        modifier(
            LimiarScaledFontModifier(
                size: size,
                weight: weight,
                design: design,
                relativeTo: textStyle
            )
        )
    }

    /// Alias de compatibilidade para as telas de conversão. Mantém a mesma
    /// matemática e evita qualquer mudança visual nos paywalls existentes.
    func conversionFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        limiarFont(size, weight: weight, design: design, relativeTo: textStyle)
    }

    /// Fonte exclusiva da superfície de leitura. Compõe Dynamic Type com o
    /// ajuste local Aa sem alterar títulos, botões ou outro chrome do app.
    func readingFont(
        _ size: CGFloat,
        textScale: Int,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        modifier(
            LimiarReadingFontModifier(
                size: size,
                textScale: textScale,
                weight: weight,
                design: design,
                relativeTo: textStyle
            )
        )
    }
}

struct ReadingTextScaleMenu: View {
    @AppStorage(
        ReadingTextScaleStore.key,
        store: ReadingTextScaleStore.appGroupDefaults
    ) private var storedValue = ReadingTextScalePolicy.defaultValue

    private var value: Int {
        ReadingTextScalePolicy.normalized(storedValue)
    }

    var body: some View {
        Menu {
            ForEach(ReadingTextScalePolicy.steps, id: \.self) { option in
                Button {
                    guard option != value else { return }
                    storedValue = option
                    LimiarAnalytics.trackReadingTextScaleChanged(
                        value: option,
                        method: .aa
                    )
                } label: {
                    if option == value {
                        Label("\(option)%", systemImage: "checkmark")
                    } else {
                        Text("\(option)%")
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("Aa")
                    .limiarFont(15, weight: .bold, relativeTo: .headline)
                Text("\(value)%")
                    .limiarFont(12, weight: .semibold, relativeTo: .caption)
            }
            .foregroundStyle(Color.ivory)
            .padding(.horizontal, 11)
            .frame(minHeight: 38)
            .background(Color.white.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(Color.sageButton.opacity(0.25), lineWidth: 1))
        }
        .accessibilityLabel("Tamanho do texto da leitura")
        .accessibilityValue("\(value) por cento")
        .onAppear {
            if storedValue != value {
                storedValue = value
            }
        }
    }
}

private struct ReadingTextScaleGestureModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(
        ReadingTextScaleStore.key,
        store: ReadingTextScaleStore.appGroupDefaults
    ) private var storedValue = ReadingTextScalePolicy.defaultValue
    @State private var gestureAnchor: CGFloat = 1
    @State private var isGestureActive = false
    @State private var indicatorValue: Int?
    @State private var hideIndicatorTask: Task<Void, Never>?

    private let threshold: CGFloat = 1.12

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                MagnificationGesture(minimumScaleDelta: 0.02)
                    .onChanged(handleMagnification)
                    .onEnded { _ in
                        gestureAnchor = 1
                        isGestureActive = false
                    }
            )
            .overlay(alignment: .topTrailing) {
                if let indicatorValue {
                    Text("Aa \(indicatorValue)%")
                        .limiarFont(13, weight: .bold, relativeTo: .caption)
                        .foregroundStyle(Color.deepInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.sageButton, in: Capsule())
                        .padding(10)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .onDisappear {
                hideIndicatorTask?.cancel()
            }
    }

    private func handleMagnification(_ magnification: CGFloat) {
        if !isGestureActive {
            isGestureActive = true
            gestureAnchor = 1
        }

        let relativeScale = magnification / max(gestureAnchor, 0.01)
        if relativeScale >= threshold {
            changeScale(increasing: true)
            gestureAnchor = magnification
        } else if relativeScale <= 1 / threshold {
            changeScale(increasing: false)
            gestureAnchor = magnification
        }
    }

    private func changeScale(increasing: Bool) {
        let current = ReadingTextScalePolicy.normalized(storedValue)
        let next = increasing
            ? ReadingTextScalePolicy.incremented(current)
            : ReadingTextScalePolicy.decremented(current)
        guard next != current else { return }

        storedValue = next
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        LimiarAnalytics.trackReadingTextScaleChanged(value: next, method: .pinch)
        showIndicator(next)
    }

    private func showIndicator(_ value: Int) {
        hideIndicatorTask?.cancel()
        if reduceMotion {
            indicatorValue = value
        } else {
            withAnimation(.easeOut(duration: 0.16)) {
                indicatorValue = value
            }
        }

        hideIndicatorTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            if reduceMotion {
                indicatorValue = nil
            } else {
                withAnimation(.easeOut(duration: 0.16)) {
                    indicatorValue = nil
                }
            }
        }
    }
}

extension View {
    func readingTextScaleGesture() -> some View {
        modifier(ReadingTextScaleGestureModifier())
    }
}

struct InstagramIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.99, green: 0.80, blue: 0.22), location: 0.00),
                            .init(color: Color(red: 0.98, green: 0.22, blue: 0.32), location: 0.38),
                            .init(color: Color(red: 0.75, green: 0.16, blue: 0.79), location: 0.72),
                            .init(color: Color(red: 0.25, green: 0.32, blue: 0.92), location: 1.00)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white, lineWidth: 3)
                .frame(width: 30, height: 30)

            Circle()
                .stroke(.white, lineWidth: 3)
                .frame(width: 12, height: 12)

            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
                .offset(x: 10, y: -10)
        }
    }
}

struct BlockedApplicationIcon: View {
    let token: ApplicationToken

    var body: some View {
        BlockedSelectionTile {
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(1.22)
        }
        .accessibilityLabel("App selecionado")
    }
}

struct BlockedCategoryIcon: View {
    let token: ActivityCategoryToken

    var body: some View {
        BlockedSelectionTile(width: 150) {
            Label(token)
                .limiarFont(13, weight: .semibold, relativeTo: .footnote)
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .accessibilityLabel("Categoria selecionada")
    }
}

struct BlockedWebDomainIcon: View {
    let token: WebDomainToken

    var body: some View {
        BlockedSelectionTile(width: 150) {
            Label(token)
                .limiarFont(13, weight: .semibold, relativeTo: .footnote)
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .accessibilityLabel("Site selecionado")
    }
}

struct BlockedAppsPlaceholderIcon: View {
    var body: some View {
        BlockedSelectionTile {
            InstagramIcon()
                .frame(width: 42, height: 42)
        }
        .accessibilityLabel("Instagram")
    }
}

private struct BlockedSelectionTile<Content: View>: View {
    let width: CGFloat
    @ViewBuilder let content: Content

    init(width: CGFloat = 58, @ViewBuilder content: () -> Content) {
        self.width = width
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: width)
            .frame(minHeight: 58)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sageButton.opacity(0.20), lineWidth: 1)
            )
    }
}

struct BlockedSelectionHierarchySummary: View {
    let selection: FamilyActivitySelection

    private var categoryTokens: [ActivityCategoryToken] {
        Array(selection.categoryTokens).sorted { "\($0)" < "\($1)" }
    }

    private var applicationTokens: [ApplicationToken] {
        Array(selection.applicationTokens).sorted { "\($0)" < "\($1)" }
    }

    private var webDomainTokens: [WebDomainToken] {
        Array(selection.webDomainTokens).sorted { "\($0)" < "\($1)" }
    }

    private var totalCount: Int {
        categoryTokens.count + applicationTokens.count + webDomainTokens.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("SELEÇÃO ATUAL")
                    .limiarFont(12, weight: .bold, relativeTo: .caption)
                    .tracking(1.3)
                    .foregroundStyle(Color.warmGold)

                Text(selectionCountText)
                    .limiarFont(12, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(Color.softText.opacity(0.78))
            }

            VStack(alignment: .leading, spacing: 14) {
                if !categoryTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: categoryTokens.count == 1 ? "Categoria selecionada" : "Categorias selecionadas",
                        subtitle: categoryTokens.count == 1 ? "Todos os apps desta categoria vão acionar a pausa." : "Todos os apps dessas categorias vão acionar a pausa.",
                        itemCount: categoryTokens.count,
                        systemImage: "square.stack.3d.up.fill"
                    ) {
                        ForEach(Array(categoryTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(isLast: index == categoryTokens.count - 1) {
                                Label(token)
                            }
                        }
                    }
                }

                if !applicationTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: applicationTokens.count == 1 ? "App escolhido" : "Apps escolhidos",
                        subtitle: "Selecionados individualmente no Tempo de Uso.",
                        itemCount: applicationTokens.count,
                        systemImage: "app.badge.fill",
                        showsChildConnectors: false
                    ) {
                        ForEach(Array(applicationTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(
                                isLast: index == applicationTokens.count - 1,
                                showsConnector: false
                            ) {
                                Label(token)
                            }
                        }
                    }
                }

                if !webDomainTokens.isEmpty {
                    BlockedSelectionGroup(
                        title: webDomainTokens.count == 1 ? "Site selecionado" : "Sites selecionados",
                        subtitle: "Domínios selecionados no Tempo de Uso.",
                        itemCount: webDomainTokens.count,
                        systemImage: "globe"
                    ) {
                        ForEach(Array(webDomainTokens.enumerated()), id: \.element) { index, token in
                            TokenChildRow(isLast: index == webDomainTokens.count - 1) {
                                Label(token)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.deepInk.opacity(0.40), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.sageButton.opacity(0.18), lineWidth: 1)
        )
    }

    private var selectionCountText: String {
        totalCount == 1 ? "1 item" : "\(totalCount) itens"
    }
}

struct BlockedSelectionGroup<Content: View>: View {
    let title: String
    let subtitle: String
    let itemCount: Int
    let systemImage: String
    var showsChildConnectors = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .limiarFont(15, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(Color.sageButton)
                    .frame(width: 30, height: 30)
                    .background(Color.sageButton.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(title)
                            .limiarFont(16, weight: .semibold, relativeTo: .headline)
                            .foregroundStyle(Color.ivory)

                        Text(countText)
                            .limiarFont(12, weight: .semibold, relativeTo: .caption)
                            .foregroundStyle(Color.softText.opacity(0.68))
                    }

                    Text(subtitle)
                        .limiarFont(12, weight: .medium, relativeTo: .footnote)
                        .foregroundStyle(Color.softText.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up")
                    .limiarFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Color.sageButton.opacity(0.80))
            }
            .padding(12)
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            if showsChildConnectors {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.sageButton.opacity(0.28))
                            .frame(width: 1.2)
                    }
                    .frame(width: 16)
                    .padding(.leading, 4)

                    childRows
                }
                .padding(.leading, 22)
            } else {
                childRows
            }
        }
    }

    private var childRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(10)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private var countText: String {
        itemCount == 1 ? "· 1 item" : "· \(itemCount) itens"
    }
}

struct TokenChildRow<Content: View>: View {
    let isLast: Bool
    var showsConnector = true
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: showsConnector ? 8 : 0) {
            if showsConnector {
                BranchConnector(isLast: isLast)
                    .frame(width: 18, height: 38)
            }

            content
                .limiarFont(14, weight: .semibold, relativeTo: .subheadline)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color.ivory.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepInk.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct BranchConnector: View {
    let isLast: Bool

    var body: some View {
        GeometryReader { proxy in
            let midY = proxy.size.height / 2

            Path { path in
                path.move(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 8, y: isLast ? midY : proxy.size.height))
                path.move(to: CGPoint(x: 8, y: midY))
                path.addLine(to: CGPoint(x: proxy.size.width, y: midY))
            }
            .stroke(Color.sageButton.opacity(0.26), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct LimiarBackground: View {
    var body: some View {
        ZStack {
            Color.deepInk
                .ignoresSafeArea()

            Image("DoorwayBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.deepInk.opacity(1.0),
                    Color.deepInk.opacity(0.94),
                    Color.deepInk.opacity(0.34),
                    Color.deepInk.opacity(0.78)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.deepInk.opacity(0.18), location: 0.24),
                    .init(color: Color.deepInk.opacity(0.94), location: 0.42),
                    .init(color: Color.deepInk.opacity(0.99), location: 1.0)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct SelectableRow: View {
    @ScaledMetric(relativeTo: .subheadline) private var scaledSubtitleSize: CGFloat = 14

    let title: String
    let subtitle: String
    let emphasizedSubtitleText: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String,
        emphasizedSubtitleText: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.emphasizedSubtitleText = emphasizedSubtitleText
        self.isSelected = isSelected
        self.action = action
    }

    private var styledSubtitle: AttributedString {
        var attributedSubtitle = AttributedString(subtitle)
        attributedSubtitle.font = .system(size: scaledSubtitleSize)
        attributedSubtitle.foregroundColor = Color.softText

        guard let emphasizedSubtitleText,
              let emphasizedRange = attributedSubtitle.range(of: emphasizedSubtitleText)
        else {
            return attributedSubtitle
        }

        attributedSubtitle[emphasizedRange].font = .system(size: scaledSubtitleSize, weight: .bold)
        attributedSubtitle[emphasizedRange].foregroundColor = Color.ivory
        return attributedSubtitle
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.sageButton : Color.softText)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .limiarFont(19, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(Color.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(styledSubtitle)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(isSelected ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.sageButton.opacity(0.62) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

struct ChipGrid: View {
    let items: [String]
    let selected: [String]
    let action: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    action(item)
                } label: {
                    Text(item)
                        .limiarFont(15, weight: .medium, relativeTo: .body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selected.contains(item) ? Color.sageButton.opacity(0.30) : Color.white.opacity(0.08), in: Capsule())
                        .overlay(Capsule().stroke(selected.contains(item) ? Color.sageButton.opacity(0.95) : Color.white.opacity(0.16), lineWidth: selected.contains(item) ? 1.5 : 1))
                        .foregroundStyle(selected.contains(item) ? Color.sageButton : Color.ivory.opacity(0.92))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in arrangement.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? 340
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let measuredSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let size = CGSize(width: min(measuredSize.width, maxWidth), height: measuredSize.height)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

struct LimiarPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .limiarFont(22, design: .serif, relativeTo: .title3)
            .padding(.horizontal, 12)
            .frame(minWidth: 132, minHeight: 58)
            .background(Color.sageButton.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color.deepInk)
    }
}

struct LimiarHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .limiarFont(22, design: .serif, relativeTo: .title3)
            .padding(.horizontal, 12)
            .frame(minWidth: 142, minHeight: 62)
            .background(Color.sageButton.opacity(configuration.isPressed ? 0.76 : 1), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(Color.deepInk)
    }
}

struct ConversionTestimonials: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Testimonial: Identifiable {
        let id: Int
        let quote: String
        let name: String
    }

    // Depoimentos reais de usuários, publicados somente com autorização.
    // Todos vieram de avaliações reais 5 estrelas recebidas por e-mail em
    // agosto/2026, com autorização registrada pelo Romeu. Ao editar, preserve
    // as citações palavra por palavra.
    static let testimonials = [
        Testimonial(id: 0, quote: "Não esperava tanto do aplicativo. Baixei sem grandes expectativas e me surpreendi. Prefiro prestar atenção no que estou fazendo e só depois olhar o celular. Com o Limiar consigo fazer essa pausa espiritual de forma natural. As reflexões personalizadas fazem toda a diferença. Já estou indicando para os amigos da igreja.", name: "Juliana, Belo Horizonte/MG"),
        Testimonial(id: 1, quote: "Produto fantástico para quem quer colocar Deus antes das distrações. As leituras são curtas, claras e aparecem exatamente no momento em que eu mais preciso parar. Uso com os apps de rede social e WhatsApp. Em poucos segundos troco o impulso por uma Palavra. Estou muito satisfeito.", name: "Rafael, Curitiba/PR"),
        Testimonial(id: 2, quote: "Uma pausa pequena, mas que muda o resto do dia. Escolhi os apps que mais me distraem e agora, antes de abrir, tenho aqueles minutos de leitura e reflexão. É simples, bonito e direto. Sinto que estou colocando Deus no centro de novo, sem esforço. Cinco estrelas com sobra!", name: "Pedro, Brasília/DF"),
        Testimonial(id: 3, quote: "O Limiar virou meu lembrete diário de prioridade. Eu queria ler mais a Bíblia, mas sempre acabava enrolando. Agora a pausa chega na hora certa, as leituras são adaptadas à minha tradição e ainda tem a opção de ouvir. Fácil de usar e realmente transforma o começo do dia. Estou muito grato por ter encontrado esse app.", name: "Mariana, Recife/PE"),
        Testimonial(id: 4, quote: "Honestamente eu não esperava tanto do aplicativo. Ele cria aquele segundo de consciência que a gente perde na rotina. A funcionalidade de áudio e a linguagem adaptada fazem toda a diferença. Fico com a mente bem mais leve durante o dia.", name: "Beatriz, Porto Alegre/RS"),
        Testimonial(id: 5, quote: "Baixei pensando que seria só mais um bloqueador de apps, mas a proposta é incrível. Em vez de só bloquear, ele te convida a ler um texto curto com uma reflexão profunda. A narração em áudio é excelente para ouvir na correria da manhã. Recomendo demais!", name: "Lucas, Curitiba/PR"),
        Testimonial(id: 6, quote: "Simplesmente perfeito! Eu sempre abria o Instagram ou TikTok sem pensar e perdia horas. Com o Limiar, antes de qualquer distração aparece uma leitura rápida e uma reflexão. Mudou completamente minha rotina. Consigo começar o dia mais centrado e ainda consigo ler a Bíblia sem forçar.", name: "Ana, Belo Horizonte/MG")
    ]

    static let onboardingTestimonials = Array(testimonials.suffix(3))

    @State private var selectedIndex: Int
    @State private var movementDirection = 1
    private let maximumCount: Int?
    private let usesSmoothTransition: Bool

    init(
        startingIndex: Int = 0,
        maximumCount: Int? = nil,
        usesSmoothTransition: Bool = false
    ) {
        self.maximumCount = maximumCount
        self.usesSmoothTransition = usesSmoothTransition
        let availableCount = min(maximumCount ?? Self.testimonials.count, Self.testimonials.count)
        _selectedIndex = State(initialValue: min(startingIndex, max(0, availableCount - 1)))
    }

    private var displayedTestimonials: [Testimonial] {
        Array(Self.testimonials.prefix(maximumCount ?? Self.testimonials.count))
    }

    var body: some View {
        VStack(spacing: 10) {
            if usesSmoothTransition {
                smoothCarousel
            } else {
                pagedCarousel
            }

            HStack(spacing: 7) {
                ForEach(displayedTestimonials) { testimonial in
                    Capsule()
                        .fill(testimonial.id == selectedIndex ? Color.sageButton : Color(red: 0.23, green: 0.28, blue: 0.26))
                        .frame(width: testimonial.id == selectedIndex ? 16 : 5, height: 5)
                        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
        }
        .task(id: selectedIndex) {
            guard !voiceOverEnabled else { return }
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            advance(by: 1)
        }
    }

    private var pagedCarousel: some View {
        testimonialHeightProbe
            .overlay {
                TabView(selection: $selectedIndex) {
                    ForEach(displayedTestimonials) { testimonial in
                        TestimonialCard(testimonial: testimonial, reservesFlexibleSpace: true)
                            .tag(testimonial.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
    }

    private var smoothCarousel: some View {
        testimonialHeightProbe
            .overlay(alignment: .top) {
                if let testimonial = selectedTestimonial {
                    TestimonialCard(testimonial: testimonial, reservesFlexibleSpace: false)
                        .id(testimonial.id)
                        .transition(testimonialTransition)
                }
            }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard abs(value.translation.width) > 44 else { return }
                    advance(by: value.translation.width < 0 ? 1 : -1)
                }
        )
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: advance(by: 1)
            case .decrement: advance(by: -1)
            @unknown default: break
            }
        }
    }

    private var testimonialHeightProbe: some View {
        ZStack(alignment: .top) {
            ForEach(displayedTestimonials) { testimonial in
                TestimonialCard(testimonial: testimonial, reservesFlexibleSpace: false)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .hidden()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var selectedTestimonial: Testimonial? {
        displayedTestimonials.first { $0.id == selectedIndex } ?? displayedTestimonials.first
    }

    private var testimonialTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let insertionEdge: Edge = movementDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = movementDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private func advance(by offset: Int) {
        guard displayedTestimonials.count > 1,
              let currentOffset = displayedTestimonials.firstIndex(where: { $0.id == selectedIndex }) else {
            return
        }

        movementDirection = offset >= 0 ? 1 : -1
        let count = displayedTestimonials.count
        let nextOffset = (currentOffset + offset + count) % count
        withAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.45)) {
            selectedIndex = displayedTestimonials[nextOffset].id
        }
    }
}

struct TestimonialCard: View {
    let testimonial: ConversionTestimonials.Testimonial
    var reservesFlexibleSpace = false
    var showsRating = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsRating {
                Text("★★★★★")
                    .conversionFont(15, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(Color(red: 0.89, green: 0.70, blue: 0.30))
                    .accessibilityLabel("Cinco estrelas")
            }

            Text("“\(testimonial.quote)”")
                .conversionFont(16, design: .serif)
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if reservesFlexibleSpace {
                Spacer(minLength: 0)
            }

            Text(testimonial.name)
                .conversionFont(13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.softText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(19)
        .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        .padding(.horizontal, 1)
    }
}

extension View {
    func glassCircle() -> some View {
        self
            .foregroundStyle(Color.aquaMist)
            .background(Color.deepInk.opacity(0.58), in: Circle())
            .overlay(Circle().stroke(Color.sageButton.opacity(0.34), lineWidth: 1))
    }

    func limiarPanel() -> some View {
        self
            .background(Color.deepInk.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.sageButton.opacity(0.20), lineWidth: 1)
            )
    }
}

extension Color {
    static let deepInk = Color(red: 0.02, green: 0.04, blue: 0.045)
    static let ivory = Color(red: 0.94, green: 0.91, blue: 0.84)
    static let softText = Color(red: 0.74, green: 0.75, blue: 0.75)
    static let sageButton = Color(red: 0.70, green: 0.81, blue: 0.72)
    static let sageMist = Color(red: 0.58, green: 0.70, blue: 0.63)
    static let warmGold = Color(red: 0.83, green: 0.62, blue: 0.43)
    static let aqua = Color.sageButton
    static let aquaMist = Color.sageMist
    static let gold = Color.warmGold
    static let warmStone = Color(red: 0.43, green: 0.41, blue: 0.35)
}

#Preview {
    ContentView()
        .environment(LimiarAppModel())
}

#Preview("Tiles da seleção") {
    ZStack {
        Color.deepInk.ignoresSafeArea()

        HStack(spacing: 14) {
            BlockedSelectionTile(width: 150) {
                Label("Redes Sociais", systemImage: "square.stack.3d.up.fill")
                    .limiarFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Color.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }

            BlockedAppsPlaceholderIcon()

            BlockedSelectionTile(width: 150) {
                Label("youtube.com", systemImage: "globe")
                    .limiarFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Color.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
        }
        .padding(18)
    }
    .preferredColorScheme(.dark)
}
