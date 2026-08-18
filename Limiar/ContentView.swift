@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import StoreKit
import SwiftUI
import UIKit

/// Dispara a ação quando o marcador do topo sai de vista (a pessoa rolou até
/// a leitura). No iOS 17, sem onScrollVisibilityChange, mantém a semântica
/// antiga de disparar na aparição — impreciso, mas restrito a uma fatia
/// pequena e decrescente de aparelhos.
private struct TraversalScrollTrigger: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollVisibilityChange(threshold: 0.1) { isVisible in
                if !isVisible {
                    action()
                }
            }
        } else {
            content.onAppear(perform: action)
        }
    }
}

func narrationExplanationSegments(_ parts: [String]) -> [String] {
    parts.flatMap { part in
        part
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

func readingNarrationSegments(for item: SpiritualReadingItem) -> [String] {
    [
        canonicalPassageNarrationText(reference: item.reference, text: item.text)
    ] + narrationExplanationSegments([item.homily])
}

private extension SubscriptionWinbackPhase {
    var analyticsPhase: LimiarAnalytics.WinbackPhase {
        switch self {
        case .trial: .trial
        case .paid: .paid
        }
    }
}

struct ContentView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(LimiarNotificationCoordinator.self) private var notifications
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(
        ConversionFunnelPersistence.d6DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedTrialConversion = false
    @AppStorage(
        ConversionFunnelPersistence.d7DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedEssentialModeIntro = false
    @AppStorage(
        ConversionFunnelPersistence.d8DismissedKey,
        store: UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard
    ) private var dismissedPostTrialPaywall = false
    @State private var presentedFunnelInterstitialThisSession = false
    @State private var attemptedNextCyclePrewarmThisForeground = false

    private static var forcePaywallForReviewScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForcePaywall")
        #else
        false
        #endif
    }

    private static var forceEssentialModeForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceEssential")
        #else
        false
        #endif
    }

    private static var forceFreeTrialStartForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceFreeTrialStart")
        #else
        false
        #endif
    }

    private static var forceSubscriptionGateForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceSubscriptionGate")
        #else
        false
        #endif
    }

    private static var forceCompletionScreenForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceCompletionScreen")
        #else
        false
        #endif
    }

    private static var forceLocalSessionForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceLocalSession")
        #else
        false
        #endif
    }

    private var effectiveHasPremiumAccess: Bool {
        if Self.forceLocalSessionForDebugging { return true }
        return Self.forceEssentialModeForDebugging ? false : subscription.hasPremiumAccess
    }

    private var effectiveIsEssentialMode: Bool {
        Self.forceEssentialModeForDebugging ? true : subscription.isEssentialMode
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
                if Self.forceCompletionScreenForDebugging {
                    DashboardView()
                } else if Self.forceLocalSessionForDebugging {
                    DashboardView()
                } else if Self.forceSubscriptionGateForDebugging {
                    SubscriptionGateView()
                        .transition(onboardingForwardTransition)
                } else if Self.forceFreeTrialStartForDebugging {
                    FreeTrialStartView()
                } else if Self.forcedConversionScreen == "D6" {
                    TrialConversionView {}
                } else if Self.forcedConversionScreen == "D7" {
                    EssentialModeIntroView {}
                } else if Self.forcedConversionScreen == "D8" {
                    PaywallView(analyticsOrigin: .d8)
                } else if Self.forcePaywallForReviewScreenshot {
                    PaywallView(analyticsOrigin: .settings)
                } else if Self.forceEssentialModeForDebugging {
                    DashboardView()
                } else if !model.hasCompletedOnboarding {
                    OnboardingView()
                        .transition(onboardingForwardTransition)
                } else if subscription.requiresSubscriptionGate {
                    SubscriptionGateView()
                        .transition(onboardingForwardTransition)
                } else if notifications.shieldBridgeRouteID != nil {
                    // O toque na ponte do shield é uma intenção explícita de
                    // atravessar. Para usuários com acesso ele entra direto no
                    // dashboard e não é interceptado pelo funil legado.
                    DashboardView()
                } else if subscription.cohort == .legacy,
                          subscription.accessState == .trialNotStarted {
                    FreeTrialStartView()
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.shouldShowTrialConversion,
                          !dismissedTrialConversion {
                    TrialConversionView {
                        dismissedTrialConversion = true
                        presentedFunnelInterstitialThisSession = true
                    }
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.shouldShowPostTrialPaywall,
                          !dismissedPostTrialPaywall {
                    PaywallView(analyticsOrigin: .d8) {
                        dismissedPostTrialPaywall = true
                        presentedFunnelInterstitialThisSession = true
                    }
                } else if !presentedFunnelInterstitialThisSession,
                          subscription.isEssentialMode,
                          !dismissedEssentialModeIntro {
                    EssentialModeIntroView {
                        dismissedEssentialModeIntro = true
                        presentedFunnelInterstitialThisSession = true
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
                notifications.handleAppDidBecomeActive()
                subscription.refreshAccessState()
                Task { await subscription.recoverIfNeeded() }
                model.updateAccess(
                    hasPremiumAccess: effectiveHasPremiumAccess,
                    isEssentialMode: effectiveIsEssentialMode
                )
                model.prepareFreshPassageForForeground()
                attemptNextCyclePrewarmForForeground()
            } else if phase == .background {
                attemptedNextCyclePrewarmThisForeground = false
                LimiarPrewarmCoordinator.shared.schedule()
            } else if phase == .inactive {
                // A próxima ativação (inclusive após interrupções do sistema)
                // recebe no máximo uma nova tentativa silenciosa.
                attemptedNextCyclePrewarmThisForeground = false
            }
        }
        .task {
            subscription.start()
            if model.hasCompletedOnboarding {
                MetaAppEvents.requestTrackingPermissionIfNeeded()
            }
            model.updateAccess(
                hasPremiumAccess: effectiveHasPremiumAccess,
                isEssentialMode: effectiveIsEssentialMode
            )
            syncAnalyticsUserProperties()
            if scenePhase == .active {
                attemptNextCyclePrewarmForForeground()
            }
        }
        .onChange(of: subscription.accessState) { _, _ in
            // A trava efêmera acima impede que outro interstício do funil seja
            // empilhado nesta abertura; flags persistentes só mudam no dismiss.
            model.updateAccess(
                hasPremiumAccess: effectiveHasPremiumAccess,
                isEssentialMode: effectiveIsEssentialMode
            )
            syncAnalyticsUserProperties()
        }
        .onChange(of: model.faithProfile) { _, _ in
            syncAnalyticsUserProperties()
        }
    }

    private var onboardingForwardTransition: AnyTransition {
        OnboardingPageMotion.transition(
            direction: .forward,
            reduceMotion: reduceMotion
        )
    }

    private func attemptNextCyclePrewarmForForeground() {
        guard !attemptedNextCyclePrewarmThisForeground else { return }
        attemptedNextCyclePrewarmThisForeground = true
        model.prewarmNextCycleFromForeground()
    }

    private func syncAnalyticsUserProperties() {
        LimiarAnalytics.syncUserProperties(
            profile: model.faithProfile,
            cohort: subscription.cohort,
            access: subscription.analyticsAccess
        )
    }
}

private struct DashboardView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.requestReview) private var requestReview
    @ObservedObject private var narration = PassageNarrationService.shared
    @State private var showingPicker = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingManageSubscriptions = false
    @State private var showingCompletionScreen = false
    @State private var selectedRevisitFavorite: FavoritePassageItem?

    private static var forceCompletionScreenForDebugging: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarForceCompletionScreen")
        #else
        false
        #endif
    }

    private static var forceEssentialBannerScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarEssentialBannerScreenshot")
        #else
        false
        #endif
    }

    private static var forceEssentialMiddleScreenshot: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarEssentialMiddleScreenshot")
        #else
        false
        #endif
    }

    private static var forcedWinbackPhase: SubscriptionWinbackPhase? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-LimiarForceWinbackTrial") {
            return .trial
        }
        if ProcessInfo.processInfo.arguments.contains("-LimiarForceWinbackPaid") {
            return .paid
        }
        #endif
        return nil
    }

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
                            .modifier(TraversalScrollTrigger {
                                markTraversalStartedByInteraction()
                            })

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Limiar")
                                    .limiarFont(48, design: .serif, relativeTo: .largeTitle)
                                    .foregroundStyle(Color.ivory)

                                Text("Reserve alguns minutos para uma leitura que fortaleça sua fé.")
                                    .limiarFont(18, relativeTo: .body)
                                    .foregroundStyle(Color.softText)
                                    .lineSpacing(4)
                            }

                            Spacer()

                            Button {
                                showingSettings = true
                            } label: {
                                ProfileAvatarView(
                                    store: model.profileImageStore,
                                    size: 46
                                )
                            }
                            .accessibilityLabel("Abrir perfil")
                        }
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)

                        blockedAppsStrip
                        winbackBanner
                        savedPassageRevisit
                        weeklyPauseSummary
                        readingRequirementHeader
                        essentialModeNotice
                        readingItemsList
                        if model.showsAds {
                            LimiarMRECAdSlot()
                                .id("essentialMREC")
                        }
                        chooseAppsButton
                        completionExplanation
                        unlockButton
                        footer
                    }
                    .padding(.horizontal, 24)
                    .containerRelativeFrame(.horizontal, alignment: .leading)
                    .padding(.top, 58)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    proxy.scrollTo("readingTop", anchor: .top)
                    if Self.forceCompletionScreenForDebugging {
                        showingCompletionScreen = true
                    }
                }
                .task {
                    guard Self.forceEssentialBannerScreenshot || Self.forceEssentialMiddleScreenshot else { return }
                    if Self.forceEssentialBannerScreenshot {
                        // O MREC pode levar mais tempo para responder no primeiro
                        // boot de um simulador novo; a espera existe apenas no
                        // caminho DEBUG usado pelas capturas automatizadas.
                        try? await Task.sleep(for: .seconds(24))
                        proxy.scrollTo("essentialMREC", anchor: .center)
                    } else {
                        try? await Task.sleep(for: .seconds(7))
                        proxy.scrollTo("essentialMiddle", anchor: .center)
                    }
                }
                .onChange(of: model.readingTopResetID) { _, _ in
                    showingCompletionScreen = false
                    withAnimation(.easeOut(duration: 0.28)) {
                        proxy.scrollTo("readingTop", anchor: .top)
                    }
                }
            }

            if showingCompletionScreen {
                completionScreen
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.showsAds && !showingCompletionScreen {
                // O safeAreaInset mantem o anuncio fixo e reduz a area rolavel
                // pela altura real do slot. Assim o CTA nunca fica encoberto.
                LimiarAnchoredAdSlot()
                    .background(Color.deepInk.opacity(0.98))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.large)
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showingPaywall) {
            PaywallView(analyticsOrigin: .dashboard)
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .sheet(item: $selectedRevisitFavorite) { favorite in
            NavigationStack {
                FavoritePassageDetailView(favorite: favorite, isPresentedModally: true)
            }
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
        .onChange(of: showingManageSubscriptions) { wasPresented, isPresented in
            guard wasPresented, !isPresented else { return }
            Task {
                await subscription.recoverIfNeeded()
            }
        }
        .task {
            model.reapplyBlockIfNeeded()
        }
        .onDisappear {
            narration.stop()
        }
    }

    /// A travessia "começa" quando a pessoa interage com a leitura (rolagem
    /// no conteúdo ou narração), não na simples aparição do dashboard — senão
    /// abrir e fechar o app conta como travessia iniciada e infla o funil
    /// started→completed. O dedupe por ciclo continua no LimiarAnalytics.
    private func markTraversalStartedByInteraction() {
        LimiarAnalytics.trackTraversalStarted(
            turn: model.pauseCycleTurn,
            cycleKey: ScreenTimePolicyStore.cycleDayKey(
                hour: model.pauseCycleTurn.rawValue
            )
        )
    }

    private var winbackPhase: SubscriptionWinbackPhase? {
        if let forcedPhase = Self.forcedWinbackPhase {
            return forcedPhase
        }
        return SubscriptionWinbackPolicy.phase(
            cohort: subscription.cohort,
            hasActiveSubscription: subscription.hasActiveSubscription,
            autoRenewIsOff: subscription.autoRenewIsOff,
            isIntroductoryTrial: subscription.activeEntitlementIsIntroductoryTrial
        )
    }

    @ViewBuilder
    private var winbackBanner: some View {
        if let phase = winbackPhase {
            let remainingText = SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: Self.forcedWinbackPhase == nil
                    ? subscription.currentPeriodEndsAt
                    : Calendar.current.date(byAdding: .day, value: 3, to: Date())
            )

            VStack(alignment: .leading, spacing: 14) {
                Label("ACESSO COMPLETO", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .limiarFont(13, weight: .bold, relativeTo: .caption)
                    .tracking(1.3)
                    .foregroundStyle(Color.warmGold)

                Text(
                    phase == .trial
                        ? "Seu acesso completo termina \(remainingText)"
                        : "Sua assinatura termina \(remainingText)"
                )
                .limiarFont(23, design: .serif, relativeTo: .title2)
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)

                Text("Reative para não perder suas pausas, narrações e trechos salvos.")
                    .limiarFont(15, relativeTo: .body)
                    .foregroundStyle(Color.softText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    LimiarAnalytics.trackWinbackBannerTapped(phase: phase.analyticsPhase)
                    showingManageSubscriptions = true
                } label: {
                    Text("Reativar assinatura")
                        .limiarFont(16, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(Color.deepInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .limiarPanel()
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .onAppear {
                LimiarAnalytics.trackWinbackBannerShown(phase: phase.analyticsPhase)
            }
        }
    }

    private var blockedAppsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPS QUE ATIVAM O LIMIAR")
                .limiarFont(13, weight: .bold, relativeTo: .caption)
                .tracking(1.5)
                .foregroundStyle(Color.warmGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    let categoryTokens = Array(model.selection.categoryTokens)
                        .sorted { "\($0)" < "\($1)" }
                    let applicationTokens = Array(model.selection.applicationTokens)
                        .sorted { "\($0)" < "\($1)" }
                    let webDomainTokens = Array(model.selection.webDomainTokens)
                        .sorted { "\($0)" < "\($1)" }

                    if categoryTokens.isEmpty,
                       applicationTokens.isEmpty,
                       webDomainTokens.isEmpty {
                        BlockedAppsPlaceholderIcon()
                    } else {
                        ForEach(categoryTokens, id: \.self) { token in
                            BlockedCategoryIcon(token: token)
                        }

                        ForEach(applicationTokens, id: \.self) { token in
                            BlockedApplicationIcon(token: token)
                        }

                        ForEach(webDomainTokens, id: \.self) { token in
                            BlockedWebDomainIcon(token: token)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .limiarPanel()
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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

    @ViewBuilder
    private var savedPassageRevisit: some View {
        if let suggestion = model.savedPassageRevisitSuggestion {
            let readingItem = favoriteReadingItem(suggestion.favorite)
            let segments = readingNarrationSegments(for: readingItem)

            VStack(alignment: .leading, spacing: 13) {
                Label(suggestion.reason.eyebrow, systemImage: "bookmark.fill")
                    .limiarFont(12, weight: .bold, relativeTo: .caption)
                    .tracking(1.1)
                    .foregroundStyle(Color.warmGold)

                Text(suggestion.favorite.reference)
                    .limiarFont(25, design: .serif, relativeTo: .title2)
                    .foregroundStyle(Color.ivory)

                Text(model.favoritePassageText(for: suggestion.favorite))
                    .limiarFont(15, relativeTo: .body)
                    .foregroundStyle(Color.softText)
                    .lineSpacing(4)
                    .lineLimit(3)

                HStack(spacing: 10) {
                    Button("Revisitar") {
                        selectedRevisitFavorite = suggestion.favorite
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.sageButton)

                    Button {
                        if model.isEssentialMode {
                            showingPaywall = true
                        } else {
                            narration.toggle(segments: segments, context: "revisita_inteligente")
                        }
                    } label: {
                        Label(
                            narration.state(for: segments) == .idle ? "Ouvir novamente" : narration.state(for: segments).title,
                            systemImage: narration.state(for: segments).systemImage
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.sageButton)
                    .foregroundStyle(Color.deepInk)
                }
                .limiarFont(14, weight: .semibold, relativeTo: .headline)
            }
            .padding(18)
            .limiarPanel()
            .dynamicTypeSize(...DynamicTypeSize.large)
        }
    }

    @ViewBuilder
    private var weeklyPauseSummary: some View {
        if let summary = model.weeklyPauseSummaryText {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .limiarFont(17, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(Color.warmGold)
                Text(summary)
                    .limiarFont(16, weight: .medium, relativeTo: .body)
                    .foregroundStyle(Color.ivory)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sageButton.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.sageButton.opacity(0.22), lineWidth: 1)
            )
        }
    }

    private var readingRequirementHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Label("SEU LIMIAR", systemImage: "book.closed")
                    .limiarFont(13, weight: .bold, relativeTo: .caption)
                    .tracking(1.3)
                    .foregroundStyle(Color.warmGold)

                Spacer(minLength: 8)

                ReadingPreferencesMenu {
                    narration.applyStoredPreferences()
                }
            }

            Text(model.currentReadingTitle)
                .limiarFont(40, design: .serif, relativeTo: .largeTitle)
                .foregroundStyle(Color.ivory)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("Leia com calma e reflita sobre sua vida.")
                .limiarFont(18, relativeTo: .body)
                .foregroundStyle(Color.softText)
                .lineSpacing(5)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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
                if model.aiContentState == .localSession {
                    AIReadingLocalSessionNotice(
                        isRetrying: model.isRetryingLocalSession,
                        retry: model.retryReadingGeneration
                    )
                }

                ForEach(Array(model.currentSpiritualReadingItems.enumerated()), id: \.element.id) { index, item in
                    let narrationSegments = readingNarrationSegments(for: item)

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
                                markTraversalStartedByInteraction()
                                narration.toggle(segments: narrationSegments)
                            }
                        },
                        narrationState: model.isEssentialMode ? .idle : narration.state(for: narrationSegments),
                        narrationSegmentIndex: model.isEssentialMode
                            ? nil
                            : narration.highlightedSegmentIndex(for: narrationSegments),
                        showsReflection: (model.hasPremiumAccess || model.isEssentialMode) && item.hasExplanationContent,
                        showsNarration: model.canNarrateCurrentReading || model.isEssentialMode,
                        isSaveLocked: model.isEssentialMode,
                        isNarrationLocked: model.isEssentialMode
                    )
                    .id(index == 1 ? "essentialMiddle" : "reading-\(item.id)")

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
            if model.currentSpiritualReadingItems.count > 1 {
                Label("Reflexão breve", systemImage: "sparkle")
                    .limiarFont(13, weight: .bold, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                    .padding(.top, 4)
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                ReadingBlock(title: "Entenda o significado", text: model.currentReflection.summary)
            }
            ReadingBlock(title: "Sentido espiritual", text: model.currentReflection.spiritualMeaning)
                .padding(.top, model.currentSpiritualReadingItems.count == 1 ? 4 : 0)
            ReadingBlock(title: "Para levar para o dia", text: model.currentReflection.practicalApplication)
            ReadingBlock(title: "Pergunta para refletir", text: model.currentReflection.meditationQuestion)
            RememberTodayBlock(
                text: model.currentReflection.conclusion,
                isSaved: model.currentSpiritualReadingItems.first.map { model.isFavorite($0) } ?? false,
                saveAction: saveCurrentPassageFromReminder
            )
        }
    }

    private func saveCurrentPassageFromReminder() {
        guard let item = model.currentSpiritualReadingItems.first else { return }
        if model.isEssentialMode {
            showingPaywall = true
        } else if !model.isFavorite(item) {
            model.toggleFavorite(item)
        }
    }

    private func favoriteReadingItem(_ favorite: FavoritePassageItem) -> SpiritualReadingItem {
        SpiritualReadingItem(
            id: favorite.passageID,
            reference: favorite.reference,
            text: model.favoritePassageText(for: favorite),
            homily: favorite.homily ?? "",
            practicalConclusion: favorite.practicalConclusion ?? "",
            passageID: favorite.passageID
        )
    }

    private var essentialReflectionTeaser: some View {
        Button {
            showingPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflexão breve", systemImage: "lock.fill")
                    .limiarFont(13, weight: .bold, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                Text(model.currentReflection.summary)
                    .limiarFont(16, design: .serif, relativeTo: .body)
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
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel("Reflexão breve bloqueada. Abrir Limiar completo")
    }

    private var essentialModeNotice: some View {
        Group {
            if model.isEssentialMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .limiarFont(14, weight: .semibold, relativeTo: .subheadline)
                            .foregroundStyle(Color.sageButton)

                        Text("Modo Essencial")
                            .limiarFont(14, weight: .bold, relativeTo: .headline)
                            .foregroundStyle(Color.ivory)
                    }

                    Text("Você está lendo os trechos principais com explicações essenciais. Narração, maior variedade e experiência sem anúncios ficam no Limiar completo.")
                        .limiarFont(13, weight: .medium, relativeTo: .footnote)
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if model.isEssentialMode {
                        NavigationLink {
                            PaywallView(analyticsOrigin: .dashboard)
                        } label: {
                            Text("Ver planos")
                                .limiarFont(13, weight: .bold, relativeTo: .headline)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            }
        }
    }

    private var chooseAppsButton: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .limiarFont(24, relativeTo: .title2)
                    .frame(width: 52, height: 52)
                    .glassCircle()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Editar apps da pausa")
                        .limiarFont(19, design: .serif, relativeTo: .title3)
                        .foregroundStyle(Color.ivory)
                    Text("Escolha quais apps vão abrir com a pausa do Limiar.")
                        .limiarFont(15, relativeTo: .body)
                        .foregroundStyle(Color.softText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .limiarFont(20, weight: .semibold, relativeTo: .title3)
                    .foregroundStyle(Color.sageButton)
            }
            .contentShape(Rectangle())
        }
        .padding(16)
        .limiarPanel()
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var completionExplanation: some View {
        Text("Após concluir a leitura, os apps selecionados ficarão disponíveis até o próximo ciclo.")
            .limiarFont(14, relativeTo: .subheadline)
            .foregroundStyle(Color.softText)
            .lineSpacing(5)
            .padding(.horizontal, 2)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var unlockButton: some View {
        Button {
            completeReading()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: "sunrise.fill")
                    .limiarFont(20, weight: .semibold, relativeTo: .title3)
                    .foregroundStyle(Color.deepInk.opacity(0.70))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Despausar apps, continuar")
                        .limiarFont(22, design: .serif, relativeTo: .title3)
                        .foregroundStyle(Color.deepInk)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .limiarFont(24, relativeTo: .title2)
                    .foregroundStyle(Color.deepInk)
            }
            .padding(.horizontal, 34)
            .frame(height: 104)
            .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.ivory.opacity(0.26), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 10)
        }
        .disabled(showingCompletionScreen)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel("Despausar apps, continuar")
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
            Text("Você no controle. Você escolhe o que atravessar.")
        }
        .limiarFont(15, weight: .medium, relativeTo: .body)
        .foregroundStyle(Color.sageButton)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var completionScreen: some View {
        let presentation = completionPresentation

        return ZStack {
            LimiarBackground()
            CompletionLightSweep()

            VStack(spacing: 24) {
                Spacer()

                ZStack(alignment: .topTrailing) {
                    Image(systemName: presentation.iconName)
                        .limiarFont(46, relativeTo: .largeTitle)
                        .foregroundStyle(Color.warmGold)
                        .symbolEffect(.bounce, value: showingCompletionScreen)

                    Image(systemName: "checkmark")
                        .limiarFont(10, weight: .bold, relativeTo: .caption2)
                        .foregroundStyle(Color.deepInk)
                        .frame(width: 22, height: 22)
                        .background(Color.sageButton, in: Circle())
                        .overlay(Circle().stroke(Color.ivory.opacity(0.35), lineWidth: 1))
                        .offset(x: 10, y: -7)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Travessia concluída no turno da \(presentation.turn.title.lowercased())")

                Text("Travessia concluída")
                    .limiarFont(40, design: .serif, relativeTo: .largeTitle)
                    .foregroundStyle(Color.ivory)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Text("Seus apps estão liberados até o próximo ciclo, \(presentation.nextCycleReference).")
                        .limiarFont(18, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(Color.ivory)

                    Text("Pode fechar o Limiar e seguir seu dia. Leve a leitura de hoje com você.")
                        .limiarFont(16, relativeTo: .body)
                        .foregroundStyle(Color.softText)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingCompletionScreen = false
                    }
                } label: {
                    Text("Permanecer no Limiar")
                        .limiarFont(15, weight: .medium, relativeTo: .body)
                        .foregroundStyle(Color.sageButton)
                }
                .accessibilityHint("Fecha a tela de conclusão e volta para a leitura")
                .padding(.bottom, 44)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    private var completionPresentation: CompletionScreenPresentation {
        let now = Date()
        let calendar = ScreenTimePolicyStore.cycleCalendar
        let turn = debugCompletionTurn ?? model.pauseCycleTurn
        let nextCycleStart: Date

        if let debugTiming = debugCompletionTiming {
            let dayOffset = debugTiming == "today" ? 0 : 1
            let day = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            nextCycleStart = calendar.date(
                bySettingHour: turn.rawValue,
                minute: 0,
                second: 0,
                of: day
            ) ?? day
        } else {
            nextCycleStart = ScreenTimePolicyStore.nextCycleStart(after: now, calendar: calendar)
        }

        return CompletionScreenPresentation(
            turn: turn,
            now: now,
            nextCycleStart: nextCycleStart,
            calendar: calendar
        )
    }

    private var debugCompletionTurn: PauseCycleTurn? {
        #if DEBUG
        guard let value = Self.debugArgument(after: "-LimiarCompletionTurn") else { return nil }
        switch value {
        case "morning": return .morning
        case "afternoon": return .afternoon
        case "evening": return .evening
        default: return nil
        }
        #else
        return nil
        #endif
    }

    private var debugCompletionTiming: String? {
        #if DEBUG
        Self.debugArgument(after: "-LimiarCompletionTiming")
        #else
        nil
        #endif
    }

    private static func debugArgument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private func completeReading() {
        guard !showingCompletionScreen else { return }

        narration.stop(preservingProgress: false)
        model.finishReading()
        requestTrackingPermissionAfterCompletion()
        requestReviewIfEligibleAfterCompletion()

        withAnimation(.easeInOut(duration: 0.8)) {
            showingCompletionScreen = true
        }
    }

    /// Pede a permissão de rastreamento na travessia concluída — o momento de
    /// maior boa vontade, quando a pessoa acabou de receber o que veio buscar
    /// e vê os apps liberados. O alerta do sistema só aparece uma vez por
    /// instalação, então esta é a única chance de perguntar; oferecê-la aqui,
    /// e não numa abertura futura, alcança também quem instala pelo anúncio e
    /// não volta no dia seguinte.
    private func requestTrackingPermissionAfterCompletion() {
        // Espera o encerramento visual da travessia (0.8s de animação) para o
        // alerta não subir por cima da transição.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            MetaAppEvents.requestTrackingPermissionIfNeeded()
        }
    }

    private func requestReviewIfEligibleAfterCompletion() {
        let history = model.history
        let readingWasHealthy = model.aiContentState != .fallback && model.aiContentState != .localSession

        // Aguarda o encerramento visual da travessia para não interromper a
        // ação de concluir a leitura. Quando o alerta de rastreamento ainda
        // está pendente, ele tem a vez: só aparece uma vez por instalação,
        // enquanto o pedido de avaliação volta a ficar elegível em outra
        // travessia. Sem essa folga o iOS descartaria um dos dois.
        let delay: TimeInterval = MetaAppEvents.isTrackingPromptPending ? 12.0 : 3.0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !MetaAppEvents.isTrackingPromptPending else { return }
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

struct RememberTodayBlock: View {
    let text: String
    let isSaved: Bool
    let saveAction: () -> Void

    @State private var copied = false
    @AppStorage(
        ReadingTextScaleStore.key,
        store: ReadingTextScaleStore.appGroupDefaults
    ) private var readingTextScale = ReadingTextScalePolicy.defaultValue

    private var cleanedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !cleanedText.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("PARA LEMBRAR HOJE", systemImage: "sun.max.fill")
                    .limiarFont(13, weight: .bold, relativeTo: .caption)
                    .tracking(1.1)
                    .foregroundStyle(Color.warmGold)

                Text(cleanedText)
                    .readingFont(
                        18,
                        textScale: readingTextScale,
                        design: .serif,
                        relativeTo: .title3
                    )
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(action: saveAction) {
                        Label(
                            isSaved ? "Salvo com o trecho" : "Salvar com o trecho",
                            systemImage: isSaved ? "heart.fill" : "heart"
                        )
                    }
                    .disabled(isSaved)

                    Button {
                        UIPasteboard.general.string = cleanedText
                        copied = true
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1.2))
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copiado" : "Copiar", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                }
                .limiarFont(13, weight: .semibold, relativeTo: .headline)
                .buttonStyle(.bordered)
                .tint(Color.sageButton)
            }
            .padding(17)
            .background(
                LinearGradient(
                    colors: [Color.warmGold.opacity(0.12), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.warmGold.opacity(0.25), lineWidth: 1)
            )
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
    }
}

private struct CompletionLightSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lightOffset: CGFloat = -1.2

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.clear, Color.warmGold.opacity(0.02), Color.warmGold.opacity(0.16), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.48, height: proxy.size.height * 1.25)
            .rotationEffect(.degrees(8))
            .offset(x: lightOffset * proxy.size.width, y: -proxy.size.height * 0.12)
            .blendMode(.screen)
            .allowsHitTesting(false)
            .onAppear {
                guard !reduceMotion else {
                    lightOffset = 0.45
                    return
                }
                withAnimation(.easeInOut(duration: 1.8)) {
                    lightOffset = 1.5
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
