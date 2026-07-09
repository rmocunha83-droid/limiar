@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct OnboardingView: View {
    @Environment(LimiarAppModel.self) private var model
    @State private var step: Int
    @State private var status = ""
    @State private var readingPreferenceMessage = ""
    @State private var showingPicker = false
    @State private var didApplyDebugTradition = false

    private enum Layout {
        static let horizontalInset: CGFloat = 28
        static let verticalInset: CGFloat = 22
    }

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let stepFlagIndex = arguments.firstIndex(of: "-LimiarOnboardingStep"),
           arguments.indices.contains(stepFlagIndex + 1),
           let debugStep = Int(arguments[stepFlagIndex + 1]) {
            _step = State(initialValue: min(max(debugStep, 0), 5))
            return
        }
        #endif

        _step = State(initialValue: 0)
    }

    var body: some View {
        @Bindable var model = model

        ZStack {
            if step == 0 {
                WelcomeHeroScreen {
                    withAnimation { step = 1 }
                }
            } else {
                LimiarBackground()

                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 18)

                    Group {
                        switch displayedStep {
                        case 1:
                            tradition
                        case 2:
                            readingStyles
                        case 3:
                            spiritualThemes
                        case 4:
                            reflectionDepth
                        case 5:
                            screenTime
                        default:
                            screenTime
                        }
                    }
                    .id(displayedStep)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.22), value: step)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    HStack(spacing: 12) {
                        Button {
                            moveToPreviousStep()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 21, weight: .regular))
                                .frame(width: 46, height: 46)
                                .glassCircle()
                        }
                        .accessibilityLabel("Voltar")

                        HStack(spacing: 6) {
                            ForEach(Array(visibleSteps.enumerated()), id: \.offset) { index, _ in
                                Capsule()
                                    .fill(index == progressIndex ? Color.sageButton : Color.white.opacity(0.18))
                                    .frame(width: index == progressIndex ? 26 : 7, height: 7)
                            }
                        }
                        .frame(width: 106, alignment: .leading)

                        Spacer(minLength: 8)

                        Button {
                            advance()
                        } label: {
                            HStack(spacing: 10) {
                                Text(displayedStep == finalOnboardingStep ? "Começar" : "Continuar")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                if displayedStep != finalOnboardingStep {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .regular))
                                }
                            }
                        }
                        .buttonStyle(LimiarPrimaryButtonStyle())
                    }
                    .padding(.horizontal, Layout.horizontalInset)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .familyActivityPicker(
            headerText: "Escolha quais apps vão ativar o Limiar.",
            footerText: "O Limiar usa o seletor nativo do Tempo de Uso.",
            isPresented: $showingPicker,
            selection: $model.selection
        )
        .onAppear {
            applyDebugTraditionIfNeeded()
            normalizeCurrentStepForTradition()
        }
        .onChange(of: model.selection) { _, _ in
            model.saveProfile()
        }
        .onChange(of: model.faithProfile.tradition) { _, _ in
            normalizeCurrentStepForTradition()
        }
    }

    private var finalOnboardingStep: Int { 5 }

    private var visibleSteps: [Int] {
        [0, 1, 2, 3, 4, 5]
    }

    private var displayedStep: Int { step }

    private var progressIndex: Int {
        visibleSteps.firstIndex(of: displayedStep) ?? 0
    }

    private var screenTimeIsAuthorizedForDisplay: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarScreenTimeAuthorized") { return true }
        #endif
        return model.hasAuthorizedScreenTime
    }

    private var screenTimeHasSelectionForDisplay: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarBlockedAppsSelected") { return true }
        #endif
        return model.hasBlockedAppsSelection
    }

    private var tradition: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(eyebrow: "TRADIÇÃO", title: "Qual linguagem espiritual guia sua leitura?")
                ForEach(FaithTradition.allCases) { tradition in
                    SelectableRow(
                        title: tradition.title,
                        subtitle: tradition.subtitle,
                        isSelected: model.faithProfile.tradition == tradition
                    ) {
                        selectTradition(tradition)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Layout.horizontalInset)
        .padding(.vertical, Layout.verticalInset)
    }

    private var spiritualThemes: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(eyebrow: "TEMAS", title: "Quais temas você quer cultivar nas pausas?")
                ChipGrid(
                    items: SpiritualTheme.standaloneOptions(for: model.faithProfile.tradition).map(\.title),
                    selected: model.faithProfile.favoriteThemes
                        .filter { SpiritualTheme.standaloneOptions(for: model.faithProfile.tradition).contains($0) }
                        .map(\.title)
                ) { title in
                    toggleTheme(title)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.vertical, Layout.verticalInset)
        }
    }

    private var readingStyles: some View {
        let config = model.faithProfile.tradition.readingConfig
        let selectedCount = model.faithProfile.selectedReadingCategoryCount

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingTitle(eyebrow: "LEITURAS", title: config.question)

                Text(config.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(config.categories) { category in
                        ReadingStyleChip(
                            category: category,
                            isSelected: model.faithProfile.isCategorySelected(category.id)
                        ) {
                            model.toggleReadingCategory(category.id)
                            readingPreferenceMessage = ""
                        }
                    }
                }

                Text(selectedCount == 1
                    ? "1 selecionado · escolha ao menos \(config.minSelected)"
                    : "\(selectedCount) selecionados · escolha ao menos \(config.minSelected)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selectedCount >= config.minSelected ? Color.softText : Color.warmGold)

                OptionalBooksRefinement(config: config)

                if !readingPreferenceMessage.isEmpty {
                    Label(readingPreferenceMessage, systemImage: "info.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.sageButton)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.vertical, Layout.verticalInset)
        }
        .id(model.faithProfile.tradition)
    }

    private var reflectionDepth: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingTitle(eyebrow: "REFLEXÕES", title: "Qual tamanho de reflexão combina com sua rotina?")
                ForEach(ExplanationDepth.allCases) { depth in
                    SelectableRow(
                        title: depth.title,
                        subtitle: reflectionDepthSubtitle(for: depth),
                        isSelected: model.faithProfile.explanationDepth == depth
                    ) {
                        model.selectExplanationDepth(depth)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.vertical, Layout.verticalInset)
        }
    }

    private var screenTime: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingTitle(eyebrow: "ATIVAÇÃO", title: "Ative o Limiar")

                Text("Siga estas 2 etapas para começar.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.sageButton)
                    .lineSpacing(5)

                ScreenTimeSetupPanel(
                    isAuthorized: screenTimeIsAuthorizedForDisplay,
                    hasSelection: screenTimeHasSelectionForDisplay,
                    authorizeAction: {
                        Task { status = await model.requestAuthorization() }
                    },
                    selectAppsAction: {
                        showingPicker = true
                    }
                )

                if model.hasBlockedAppsSelection {
                    BlockedSelectionHierarchySummary(selection: model.selection)
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.sageButton)
                        .padding(.top, 1)

                    Text(status.isEmpty ? "O iOS pedirá permissão antes de ativar as pausas." : status)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                }

                Button {
                    status = "Você poderá autorizar o Tempo de Uso depois em Configurações."
                    model.saveProfile()
                    model.completeOnboarding()
                } label: {
                    Text("Fazer isso depois")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.sageButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Layout.horizontalInset)
            .padding(.vertical, Layout.verticalInset)
        }
    }

    private func selectTradition(_ tradition: FaithTradition) {
        model.selectTradition(tradition)
        readingPreferenceMessage = ""
    }

    private func applyDebugTraditionIfNeeded() {
        #if DEBUG
        guard !didApplyDebugTradition else { return }
        didApplyDebugTradition = true
        let arguments = ProcessInfo.processInfo.arguments
        guard let traditionFlagIndex = arguments.firstIndex(of: "-LimiarTradition"),
              arguments.indices.contains(traditionFlagIndex + 1),
              let tradition = FaithTradition(rawValue: arguments[traditionFlagIndex + 1])
        else {
            return
        }
        model.selectTradition(tradition)
        #endif
    }

    private func toggleTheme(_ title: String) {
        let options = SpiritualTheme.standaloneOptions(for: model.faithProfile.tradition)
        guard let theme = options.first(where: { $0.title == title }) else { return }
        model.toggleTheme(theme)
    }

    private func reflectionDepthSubtitle(for depth: ExplanationDepth) -> String {
        switch depth {
        case .short:
            return "Uma pausa breve, direta e fácil de concluir."
        case .medium:
            return "Equilíbrio recomendado para começar."
        case .deep:
            return "Mais contexto, aplicação e pergunta de meditação."
        }
    }

    private func advance() {
        if step == 2, !model.faithProfile.hasSelectedReadingPreferences {
            readingPreferenceMessage = "Escolha ao menos 1 estilo de leitura para continuar."
            return
        }

        if step == 5 {
            model.saveProfile()
            advanceFromScreenTime()
            return
        }

        model.saveProfile()
        if let nextStep = nextStep(after: displayedStep) {
            withAnimation { step = nextStep }
        } else {
            model.completeOnboarding()
        }
    }

    private func advanceFromScreenTime() {
        if !model.hasAuthorizedScreenTime {
            Task { status = await model.requestAuthorization() }
            return
        }

        if !model.hasBlockedAppsSelection {
            status = "Agora escolha os apps ou categorias que vão ativar o Limiar."
            showingPicker = true
            return
        }

        model.completeOnboarding()
    }

    private func moveToPreviousStep() {
        guard let previousStep = previousStep(before: displayedStep) else { return }
        withAnimation { step = previousStep }
    }

    private func nextStep(after currentStep: Int) -> Int? {
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep) else { return nil }
        let nextIndex = currentIndex + 1
        guard visibleSteps.indices.contains(nextIndex) else { return nil }
        return visibleSteps[nextIndex]
    }

    private func previousStep(before currentStep: Int) -> Int? {
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep), currentIndex > 0 else { return nil }
        return visibleSteps[currentIndex - 1]
    }

    private func normalizeCurrentStepForTradition() {
        // Todas as tradições passam pelos mesmos passos.
    }
}

struct ScreenTimeSetupPanel: View {
    let isAuthorized: Bool
    let hasSelection: Bool
    let authorizeAction: () -> Void
    let selectAppsAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 0) {
                ScreenTimeStepBadge(
                    label: "1",
                    isComplete: isAuthorized,
                    isEnabled: true
                )

                Rectangle()
                    .fill(Color.sageButton.opacity(0.45))
                    .frame(width: 1, height: 62)
                    .overlay {
                        VStack(spacing: 7) {
                            ForEach(0..<5, id: \.self) { _ in
                                Circle()
                                    .fill(Color.deepInk.opacity(0.78))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }

                ScreenTimeStepBadge(
                    label: "2",
                    isComplete: hasSelection,
                    isEnabled: isAuthorized
                )
            }
            .padding(.top, 2)

            VStack(spacing: 22) {
                ScreenTimeSetupStep(
                    title: "1. Autorizar Tempo de Uso",
                    subtitle: "Permite que o Limiar crie pausas antes dos apps selecionados.",
                    buttonTitle: isAuthorized ? "Autorizado" : "Autorizar",
                    systemImage: isAuthorized ? "checkmark.shield.fill" : "checkmark.shield",
                    state: isAuthorized ? .completed : .available,
                    allowsCompletedAction: false,
                    action: authorizeAction
                )

                Divider()
                    .overlay(Color.white.opacity(0.10))

                ScreenTimeSetupStep(
                    title: "2. Escolher apps que ativam o Limiar",
                    subtitle: "Selecione apps ou categorias que vão acionar essa pausa.",
                    buttonTitle: !isAuthorized ? "Disponível após a autorização" : (hasSelection ? "Apps escolhidos" : "Escolher apps"),
                    systemImage: !isAuthorized ? "hourglass" : (hasSelection ? "checkmark.circle" : "square.grid.2x2"),
                    state: appSelectionState,
                    allowsCompletedAction: true,
                    action: selectAppsAction
                )
            }
        }
        .padding(18)
        .limiarPanel()
    }

    private var appSelectionState: ScreenTimeStepActionState {
        if !isAuthorized { return .disabled }
        return hasSelection ? .completed : .available
    }
}

enum ScreenTimeStepActionState {
    case available
    case disabled
    case completed
}

struct ScreenTimeStepBadge: View {
    let label: String
    let isComplete: Bool
    let isEnabled: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isEnabled ? Color.sageButton.opacity(0.82) : Color.softText.opacity(0.34), lineWidth: 2)
                .frame(width: 54, height: 54)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(Color.sageButton)
            } else {
                Text(label)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(isEnabled ? Color.sageButton : Color.softText.opacity(0.70))
            }
        }
    }
}

struct ScreenTimeSetupStep: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let systemImage: String
    let state: ScreenTimeStepActionState
    let allowsCompletedAction: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(titleForeground)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(subtitleForeground)
                .lineSpacing(4)

            Button(action: action) {
                Label(buttonTitle, systemImage: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(buttonBackground, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(buttonForeground)
            }
            .disabled(!isInteractive)
            .accessibilityLabel(buttonTitle)
        }
    }

    private var isInteractive: Bool {
        switch state {
        case .available:
            true
        case .disabled:
            false
        case .completed:
            allowsCompletedAction
        }
    }

    private var titleForeground: Color {
        switch state {
        case .available, .completed:
            Color.ivory
        case .disabled:
            Color.ivory.opacity(0.72)
        }
    }

    private var subtitleForeground: Color {
        switch state {
        case .available:
            Color.softText
        case .disabled, .completed:
            Color.softText.opacity(0.78)
        }
    }

    private var buttonBackground: Color {
        switch state {
        case .available:
            Color.sageButton
        case .disabled:
            Color.white.opacity(0.10)
        case .completed:
            Color.white.opacity(0.12)
        }
    }

    private var buttonForeground: Color {
        switch state {
        case .available:
            Color.deepInk
        case .disabled:
            Color.softText.opacity(0.68)
        case .completed:
            Color.softText.opacity(0.82)
        }
    }
}

struct WelcomeHeroScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let action: () -> Void

    @State private var showLight = false
    @State private var showLogo = false
    @State private var showWelcome = false
    @State private var showTitle = false
    @State private var visibleBodyLineCount = 0
    @State private var showButton = false
    @State private var backgroundZoom = false
    @State private var logoBreathing = false
    @State private var didStartEntrance = false

    private let bodyLines = [
        "Antes de voltar às distrações,",
        "reserve alguns minutos",
        "para uma",
        "leitura que fortaleça sua fé."
    ]

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 28
            let contentWidth = max(proxy.size.width - (horizontalInset * 2), 1)

            ZStack {
                LimiarBackground()
                    .scaleEffect(reduceMotion ? 1 : (backgroundZoom ? 1.03 : 1))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 8), value: backgroundZoom)
                    .overlay {
                        Rectangle()
                            .fill(Color.deepInk.opacity(showLight ? 0.03 : 0.28))
                            .ignoresSafeArea()
                    }
                    .overlay(alignment: .trailing) {
                        RadialGradient(
                            colors: [
                                Color.warmGold.opacity(showLight ? 0.18 : 0.04),
                                Color.clear
                            ],
                            center: .trailing,
                            startRadius: 18,
                            endRadius: proxy.size.width * 0.72
                        )
                        .blur(radius: 18)
                        .ignoresSafeArea()
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: proxy.size.height * 0.24)

                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84, height: 84, alignment: .leading)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? (logoBreathing && !reduceMotion ? 1.015 : 1) : 0.95)

                    Text("B E M - V I N D O")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.warmGold)
                        .padding(.top, 14)
                        .opacity(showWelcome ? 1 : 0)

                    Text("Limiar")
                        .font(.system(size: 76, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.top, 16)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: reduceMotion ? 0 : (showTitle ? 0 : 12))

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(bodyLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(size: 27, weight: .regular))
                                .foregroundStyle(Color.softText)
                                .opacity(visibleBodyLineCount > index ? 1 : 0)
                                .offset(y: reduceMotion ? 0 : (visibleBodyLineCount > index ? 0 : 8))
                        }
                    }
                        .padding(.top, 26)

                    Spacer()

                    HStack(alignment: .center, spacing: 12) {
                        HStack(spacing: 13) {
                            Capsule()
                                .fill(Color.sageButton)
                                .frame(width: 42, height: 7)
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.24))
                                    .frame(width: 9, height: 9)
                            }
                        }

                        Spacer()

                        Button(action: action) {
                            HStack(spacing: 14) {
                                Text("Continuar")
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 22, weight: .regular))
                            }
                        }
                        .buttonStyle(LimiarHeroButtonStyle())
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.bottom, 42)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (showButton ? 0 : 10))
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, horizontalInset)
                .ignoresSafeArea(edges: .top)
            }
            .clipped()
        }
        .onAppear(perform: startEntranceAnimation)
    }

    private func startEntranceAnimation() {
        guard !didStartEntrance else { return }
        didStartEntrance = true

        if reduceMotion || UIAccessibility.isReduceMotionEnabled {
            withAnimation(.easeOut(duration: 0.45)) {
                showLight = true
                showLogo = true
                showWelcome = true
                showTitle = true
                visibleBodyLineCount = bodyLines.count
                showButton = true
            }
            return
        }

        backgroundZoom = true

        withAnimation(.easeInOut(duration: 2.6)) {
            showLight = true
        }

        animate(after: 0.65, duration: 0.72) {
            showLogo = true
        }
        animate(after: 1.18, duration: 0.62) {
            showWelcome = true
        }
        animate(after: 1.68, duration: 0.72) {
            showTitle = true
        }

        for index in bodyLines.indices {
            animate(after: 2.14 + (Double(index) * 0.22), duration: 0.58) {
                visibleBodyLineCount = index + 1
            }
        }

        animate(after: 3.25, duration: 0.72) {
            showButton = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.85) {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                logoBreathing = true
            }
        }
    }

    private func animate(after delay: TimeInterval, duration: TimeInterval, changes: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: duration)) {
                changes()
            }
        }
    }
}

struct OnboardingTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(size: 13, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Color.warmGold)
            Text(title)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
                .lineLimit(4)
                .minimumScaleFactor(0.90)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Chip de categoria do passo "Leituras": selecionado = preenchimento sage
/// sólido + check + texto escuro; não selecionado = contorno sutil.
struct ReadingStyleChip: View {
    let category: ReadingStyleCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? Color.deepInk : Color.softText.opacity(0.55))

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.deepInk : Color.ivory)
                        .multilineTextAlignment(.leading)

                    Text(category.hint)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color.deepInk.opacity(0.72) : Color.softText)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.sageButton : Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.sageButton : Color.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(category.hint)
    }
}

/// Passo opcional recolhido: afinar por livros específicos. Não conta para o
/// mínimo. Mostra apenas livros das categorias já selecionadas.
struct OptionalBooksRefinement: View {
    @Environment(LimiarAppModel.self) private var model
    @State private var isExpanded = false
    let config: TraditionReadingConfig

    var body: some View {
        let pool = model.faithProfile.refinementBookPool

        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text("Afinar por livros específicos (opcional)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ivory)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.softText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isExpanded ? [.isSelected] : [])

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Se marcar livros, suas leituras priorizam exatamente esses.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)

                    if pool.isEmpty {
                        Text("Escolha um estilo acima para ver os livros.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.softText.opacity(0.8))
                    } else {
                        FlowLayout(spacing: 10) {
                            ForEach(pool) { book in
                                let isSelected = model.faithProfile.isRefinedBookSelected(book)
                                Button {
                                    model.toggleRefinedBook(book)
                                } label: {
                                    HStack(spacing: 6) {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        Text(config.bookDisplayTitle(book, tradition: model.faithProfile.tradition))
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(isSelected ? Color.deepInk : Color.ivory)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .frame(minHeight: 44)
                                    .background(
                                        Capsule().fill(isSelected ? Color.sageButton : Color.white.opacity(0.045))
                                    )
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.sageButton : Color.white.opacity(0.16), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
