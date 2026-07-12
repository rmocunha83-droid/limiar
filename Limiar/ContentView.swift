@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct ContentView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.scenePhase) private var scenePhase
    @State private var dismissedTrialConversion = false
    @State private var dismissedEssentialModeIntro = false
    @State private var dismissedPostTrialPaywall = false

    private static var forcePaywallForReviewScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForcePaywall")
        #else
        false
        #endif
    }

    private static var forcedConversionScreen: String? {
        #if DEBUG
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-LimiarConversionScreen"),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1) else {
            return nil
        }
        return ProcessInfo.processInfo.arguments[index + 1]
        #else
        return nil
        #endif
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Group {
                if Self.forcedConversionScreen == "D6" {
                    TrialConversionView {}
                } else if Self.forcedConversionScreen == "D7" {
                    EssentialModeIntroView {}
                } else if Self.forcedConversionScreen == "D8" {
                    PaywallView()
                } else if Self.forcePaywallForReviewScreenshot {
                    PaywallView()
                } else if !model.hasCompletedOnboarding {
                    OnboardingView()
                } else if subscription.accessState == .trialNotStarted {
                    FreeTrialStartView()
                } else if subscription.shouldShowTrialConversion && !dismissedTrialConversion {
                    TrialConversionView {
                        dismissedTrialConversion = true
                    }
                } else if subscription.shouldShowPostTrialPaywall && !dismissedPostTrialPaywall {
                    PaywallView {
                        dismissedPostTrialPaywall = true
                    }
                } else if subscription.isEssentialMode && !dismissedEssentialModeIntro {
                    EssentialModeIntroView {
                        dismissedEssentialModeIntro = true
                    }
                } else {
                    DashboardView()
                }
            }
            .preferredColorScheme(.dark)
        }
        .tint(Color.sageButton)
        .statusBarHidden(true)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                subscription.refreshAccessState()
                model.updateAccess(
                    hasPremiumAccess: subscription.hasPremiumAccess,
                    isEssentialMode: subscription.isEssentialMode
                )
                model.prepareFreshPassageForForeground()
            }
        }
        .task {
            subscription.start()
            model.updateAccess(
                hasPremiumAccess: subscription.hasPremiumAccess,
                isEssentialMode: subscription.isEssentialMode
            )
        }
        .onChange(of: subscription.accessState) { _, _ in
            model.updateAccess(
                hasPremiumAccess: subscription.hasPremiumAccess,
                isEssentialMode: subscription.isEssentialMode
            )
        }
    }
}

private struct DashboardView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.requestReview) private var requestReview
    @StateObject private var narration = PassageNarrationService()
    @State private var showingPicker = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var unlockPhase = UnlockButtonPhase.locked
    @State private var unlockAnimationTick = 0

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        Color.clear
                            .frame(height: 1)
                            .id("readingTop")

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Limiar")
                                    .font(.system(size: 48, weight: .regular, design: .serif))
                                    .foregroundStyle(Color.ivory)

                                Text("Reserve alguns minutos para uma leitura que fortaleça sua fé.")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.softText)
                                    .lineSpacing(4)
                            }

                            Spacer()

                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "person")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 46, height: 46)
                                    .glassCircle()
                            }
                            .accessibilityLabel("Abrir configurações")
                        }

                        blockedAppsStrip
                        trialStatusBadge
                        readingRequirementHeader
                        essentialModeNotice
                        readingItemsList
                        chooseAppsButton
                        completionExplanation
                        unlockButton
                        footerAdBanner
                        footer
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 58)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    proxy.scrollTo("readingTop", anchor: .top)
                }
                .onChange(of: model.readingTopResetID) { _, _ in
                    withAnimation(.easeOut(duration: 0.28)) {
                        proxy.scrollTo("readingTop", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showingPaywall) {
            PaywallView()
        }
        .familyActivityPicker(
            headerText: "Escolha apps, categorias ou sites que vão ativar o Limiar.",
            footerText: "Você pode alterar isso depois em Preferências.",
            isPresented: $showingPicker,
            selection: $model.selection
        )
        .onChange(of: model.selection) { _, _ in
            model.saveProfile()
            model.applyBlocking()
        }
        .task {
            model.reapplyBlockIfNeeded()
        }
        .onDisappear {
            narration.stop()
        }
    }

    private var trialStatusBadge: some View {
        Group {
            if subscription.accessState == .trialActive {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.warmGold)

                    Text("Acesso inicial: \(subscription.trialRemainingText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ivory)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
        }
    }

    private var blockedAppsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPS QUE ATIVAM O LIMIAR")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color.warmGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    let tokens = Array(model.selection.applicationTokens)
                    if tokens.isEmpty {
                        InstagramIcon()
                            .frame(width: 58, height: 58)
                            .scaleEffect(1.12)
                            .accessibilityLabel("Instagram")
                    } else {
                        ForEach(tokens, id: \.self) { token in
                            BlockedApplicationIcon(token: token)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .limiarPanel()
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            showingPicker = true
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toque para ajustar os apps que ativam o Limiar.")
        .accessibilityAction {
            showingPicker = true
        }
    }

    private var readingRequirementHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("SEU LIMIAR", systemImage: "book.closed")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.3)
                .foregroundStyle(Color.warmGold)

            Text(model.currentReadingTitle)
                .font(.system(size: 40, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("Leia com calma e reflita sobre sua vida.")
                .font(.system(size: 18))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)
        }
    }

    private var readingItemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.isPreparingReadingContent {
                AIReadingPreparationView()
            } else if model.aiContentState == .fallback && model.currentSpiritualReadingItems.isEmpty {
                AIReadingRetryView {
                    model.retryReadingGeneration()
                }
            } else {
                ForEach(Array(model.currentSpiritualReadingItems.enumerated()), id: \.element.id) { index, item in
                    let explanationSegment = [item.homily, item.practicalConclusion]
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n\n")
                    let narrationSegments = [
                        canonicalPassageNarrationText(reference: item.reference, text: item.text),
                        explanationSegment
                    ]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                    SpiritualReadingCard(
                        item: item,
                        isSaved: model.isFavorite(item),
                        saveAction: {
                            // No Essencial o toque SEMPRE abre o paywall — sem
                            // depender de canShowPaywall (que só liga no dia
                            // seguinte ao fim do trial). Nunca muta favoritos.
                            if model.isEssentialMode {
                                showingPaywall = true
                            } else {
                                model.toggleFavorite(item)
                            }
                        },
                        listenAction: {
                            if model.isEssentialMode {
                                showingPaywall = true
                            } else {
                                narration.toggle(segments: narrationSegments)
                            }
                        },
                        narrationState: model.isEssentialMode ? .idle : narration.state(for: narrationSegments),
                        showsReflection: (model.hasPremiumAccess || model.isEssentialMode) && item.hasExplanationContent,
                        showsNarration: model.canNarrateCurrentReading || model.isEssentialMode,
                        isSaveLocked: model.isEssentialMode
                    )

                    if model.showsAds {
                        LimiarAdBannerSlot(label: "Publicidade")
                    }
                }

                if model.hasPremiumAccess && model.hasVisibleReflection {
                    reflectionSection
                } else if model.isEssentialMode,
                          !model.currentReflection.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    essentialReflectionTeaser
                }
            }
        }
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reflexão breve", systemImage: "sparkle")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.warmGold)
                .padding(.top, 4)
            ReadingBlock(title: "Entenda o significado", text: model.currentReflection.summary)
            ReadingBlock(title: "Sentido espiritual", text: model.currentReflection.spiritualMeaning)
            ReadingBlock(title: "Para levar para o dia", text: model.currentReflection.practicalApplication)
            ReadingBlock(title: "Pergunta para refletir", text: model.currentReflection.meditationQuestion)
        }
    }

    private var essentialReflectionTeaser: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflexão breve", systemImage: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                Text(model.currentReflection.summary)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ivory.opacity(0.58))
                    .lineLimit(1)
                    .blur(radius: 3)
                    .mask(LinearGradient(colors: [.black, .black.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .limiarPanel()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reflexão breve bloqueada. Abrir Limiar completo")
    }

    private var essentialModeNotice: some View {
        Group {
            if model.isEssentialMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.sageButton)

                        Text("Modo Essencial")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ivory)
                    }

                    Text("Você está lendo os trechos principais com explicações essenciais. Narração, maior variedade e experiência sem anúncios ficam no Limiar completo.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)

                    if model.isEssentialMode {
                        NavigationLink {
                            PaywallView()
                        } label: {
                            Text("Ver planos")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.sageButton)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sageButton.opacity(0.18), lineWidth: 1)
                )
            }
        }
    }

    private var footerAdBanner: some View {
        Group {
            if model.showsAds {
                LimiarAdBannerSlot(label: "Publicidade")
                    .padding(.top, 4)
            }
        }
    }

    private var chooseAppsButton: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24, weight: .regular))
                    .frame(width: 52, height: 52)
                    .glassCircle()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Editar apps da pausa")
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                    Text("Escolha quais apps vão abrir com a pausa do Limiar.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.softText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.sageButton)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .limiarPanel()
        .padding(.top, 8)
    }

    private var completionExplanation: some View {
        Text("Após concluir a leitura, os apps selecionados ficarão disponíveis até a próxima manhã.")
            .font(.system(size: 14))
            .foregroundStyle(Color.softText)
            .lineSpacing(5)
            .padding(.horizontal, 2)
    }

    private var unlockButton: some View {
        Button {
            completeReadingWithUnlockAnimation()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: unlockPhase.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.deepInk.opacity(0.70))
                    .scaleEffect(unlockPhase == .opening ? 1.10 : 1)
                    .rotationEffect(.degrees(unlockPhase == .opening ? -4 : 0))
                    .symbolEffect(.bounce, value: unlockAnimationTick)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text(unlockPhase.title)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundStyle(Color.deepInk)
                }
                Spacer()
                Image(systemName: unlockPhase.trailingIconName)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.deepInk)
                    .opacity(unlockPhase == .unlocked ? 0.9 : 1)
            }
            .padding(.horizontal, 34)
            .frame(height: 104)
            .background(unlockPhase.backgroundColor, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(unlockPhase.strokeColor, lineWidth: 1)
            )
            .shadow(color: unlockPhase.shadowColor, radius: unlockPhase == .unlocked ? 18 : 8, x: 0, y: 10)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: unlockPhase)
        }
        .disabled(unlockPhase != .locked)
        .accessibilityLabel(unlockPhase.title)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
            Text("Você no controle. Você escolhe o que atravessar.")
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color.sageButton)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func completeReadingWithUnlockAnimation() {
        guard unlockPhase == .locked else { return }

        unlockPhase = .opening
        unlockAnimationTick += 1
        model.finishReading()
        requestReviewIfEligibleAfterCompletion()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            unlockPhase = .unlocked
            unlockAnimationTick += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            unlockPhase = .locked
        }
    }

    private func requestReviewIfEligibleAfterCompletion() {
        let history = model.history
        let readingWasHealthy = model.aiContentState != .fallback

        // Aguarda o encerramento visual da travessia para não interromper a
        // ação de concluir a leitura.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard subscription.claimReviewRequestIfEligible(
                history: history,
                readingWasHealthy: readingWasHealthy
            ) else {
                return
            }

            requestReview()
        }
    }
}

private enum UnlockButtonPhase: Equatable {
    case locked
    case opening
    case unlocked

    var iconName: String {
        switch self {
        case .locked: "sunrise.fill"
        case .opening: "sparkles"
        case .unlocked: "checkmark.circle.fill"
        }
    }

    var trailingIconName: String {
        switch self {
        case .locked: "arrow.right"
        case .opening: "sparkles"
        case .unlocked: "checkmark"
        }
    }

    var title: String {
        switch self {
        case .locked: "Despausar apps, continuar"
        case .opening: "Travessia concluída"
        case .unlocked: "Apps disponíveis"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .locked: Color.sageButton
        case .opening: Color.warmGold
        case .unlocked: Color(red: 0.78, green: 0.89, blue: 0.80)
        }
    }

    var strokeColor: Color {
        switch self {
        case .locked: Color.ivory.opacity(0.26)
        case .opening: Color.ivory.opacity(0.34)
        case .unlocked: Color.ivory.opacity(0.42)
        }
    }

    var shadowColor: Color {
        switch self {
        case .locked: Color.black.opacity(0.20)
        case .opening: Color.warmGold.opacity(0.22)
        case .unlocked: Color.sageButton.opacity(0.28)
        }
    }
}
