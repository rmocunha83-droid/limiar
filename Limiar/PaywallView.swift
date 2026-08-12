import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    // Sem valor padrão de propósito: cada tela de oferta declara sua origem,
    // senão o funil mistura origens silenciosamente (foi assim que o D7
    // passou a contar em dobro).
    let analyticsOrigin: LimiarAnalytics.PaywallOrigin
    var continueEssential: (() -> Void)? = nil

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://applimiar.com.br/privacy")!

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ConversionHeader(
                        eyebrow: "LIMIAR PREMIUM",
                        title: "Quero voltar a ser premium",
                        subtitle: nil
                    )

                    ConversionLossBlock(
                        title: "No plano essencial, você está sem:",
                        finalItem: "Pausa limpa — anúncios nos trechos e no dashboard"
                    )

                    ConversionTestimonials(startingIndex: 1)

                    ConversionPlanPicker(selection: $subscription.selectedPlan)

                    ConversionPurchaseSection(
                        buttonTitle: "Voltar ao Limiar completo",
                        escapeTitle: "Continuar no Essencial",
                        escapeAction: {
                            if let continueEssential {
                                continueEssential()
                            } else {
                                dismiss()
                            }
                        }
                    )

                    ConversionLegalLinks(termsURL: termsURL, privacyURL: privacyURL)
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .task {
            MetaAppEvents.trackPaywallViewed()
            LimiarAnalytics.trackPaywallViewed(origin: analyticsOrigin)
            subscription.start()
        }
    }
}

struct SubscriptionGateView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription

    private let termsURL = URL(string: "https://applimiar.com.br/terms")!
    private let privacyURL = URL(string: "https://applimiar.com.br/privacy")!

    private var forcesTrialEligibilityForDebugging: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-LimiarGateTrialEligible")
#else
        false
#endif
    }

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            OnboardingTitle(eyebrow: "ÚLTIMO PASSO", title: gateTitle)

                            Text(gateSubtitle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.softText)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if showsRestoreFirstBanner {
                            SubscriptionGateVerifyingBanner()
                        }

                        SubscriptionGateBenefits(
                            profile: model.faithProfile,
                            turn: model.pauseCycleTurn,
                            title: showsEligibleTrial
                                ? "Tudo incluído nos seus 7 dias grátis"
                                : "Tudo incluído na sua assinatura"
                        )

                        SubscriptionGatePlanPicker(
                            selection: $subscription.selectedPlan,
                            forcesTrialEligibilityForDebugging: forcesTrialEligibilityForDebugging
                        )

                        ConversionTestimonials(startingIndex: 0, usesSmoothTransition: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 18)
                }

                SubscriptionGateProgress()

                SubscriptionGateCompliance(
                    termsURL: termsURL,
                    privacyURL: privacyURL,
                    forcesTrialEligibilityForDebugging: forcesTrialEligibilityForDebugging
                )
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .task {
            MetaAppEvents.trackPaywallViewed()
            LimiarAnalytics.trackGateViewed()
            subscription.start()
        }
    }

    private var gateTitle: String {
        showsEligibleTrial
            ? "Seu Limiar está pronto."
            : "Tudo pronto para sua primeira travessia."
    }

    private var gateSubtitle: String {
        if showsEligibleTrial {
            return "Experimente tudo por 7 dias, grátis. Cancele antes do dia 8 e não pague nada."
        }
        return "Escolha seu plano e entre no Limiar."
    }

    private var showsEligibleTrial: Bool {
        forcesTrialEligibilityForDebugging
            || subscription.hasEligibleFreeTrial(for: subscription.selectedPlan)
    }

    /// Quem já teve assinatura neste aparelho (marcador do Keychain) não deve
    /// abrir o portão direto como venda: primeiro verificamos a assinatura.
    private var showsRestoreFirstBanner: Bool {
        subscription.hadSubscriptionBefore
            && !subscription.hasActiveSubscription
            && subscription.isVerifyingInitialEntitlements
    }
}

private struct SubscriptionGateVerifyingBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(Color.sageButton)
            Text("Verificando sua assinatura anterior... Se você já assinou, use \"Restaurar compras\" abaixo.")
                .conversionFont(13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(Color.ivory.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.sageButton.opacity(0.4), lineWidth: 1))
    }
}

private struct SubscriptionGateBenefits: View {
    let profile: UserFaithProfile
    let turn: PauseCycleTurn
    let title: String

    private var benefits: [String] {
        [
            "Seus apps bloqueados até a pausa da \(turn.title.lowercased())",
            "Leituras na tradição \(profile.tradition.title.lowercased()), no seu ritmo: \(depthDescription)",
            "Narração com voz natural",
            "Trechos salvos para revisitar quando quiser",
            "Sem anúncios"
        ]
    }

    private var depthDescription: String {
        switch profile.explanationDepth {
        case .short: "reflexão curta"
        case .medium: "reflexão média"
        case .deep: "reflexão mais profunda"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .conversionFont(14, weight: .semibold)
                .foregroundStyle(Color.ivory)

            VStack(spacing: 0) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    ConversionListRow(symbol: "checkmark", color: Color.sageButton, text: benefit)
                    if index < benefits.count - 1 {
                        Divider().overlay(Color.conversionDivider)
                    }
                }
            }
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        }
    }
}

private struct SubscriptionGateProgress: View {
    private let stepCount = 7

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(Color.sageButton)
                    .frame(width: index == stepCount - 1 ? 26 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding concluído")
    }
}

private struct SubscriptionGatePlanPicker: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Binding var selection: SubscriptionPlan
    let forcesTrialEligibilityForDebugging: Bool

    var body: some View {
        VStack(spacing: 10) {
            ForEach([SubscriptionPlan.monthly, .yearly]) { plan in
                Button {
                    guard selection != plan else { return }
                    selection = plan
                    subscription.noteUserSelectedPlan()
                    LimiarAnalytics.trackGatePlanSelected(plan)
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        if plan == .yearly {
                            Text("MELHOR OFERTA")
                                .conversionFont(11, weight: .bold, relativeTo: .caption)
                                .tracking(1)
                                .foregroundStyle(Color.deepInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.sageButton, in: Capsule())
                        }

                        HStack(spacing: 8) {
                            Image(systemName: selection == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == plan ? Color.sageButton : Color.softText)
                            Text(plan.title)
                                .conversionFont(17, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                            Spacer(minLength: 8)
                            Text(priceLine(for: plan))
                                .conversionFont(16, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                                .layoutPriority(1)
                        }

                        Text(detailLine(for: plan))
                            .conversionFont(13, weight: .medium, relativeTo: .footnote)
                            .foregroundStyle(
                                showsEligibleTrial(for: plan)
                                    ? Color.sageButton
                                    : Color.softText
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 31)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        selection == plan
                            ? Color(red: 0.086, green: 0.13, blue: 0.12)
                            : Color.conversionPanel,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selection == plan ? Color.sageButton : Color.conversionBorder,
                                lineWidth: selection == plan ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func priceLine(for plan: SubscriptionPlan) -> String {
        "\(subscription.storeDisplayPrice(for: plan))/\(period(for: plan))"
    }

    private func detailLine(for plan: SubscriptionPlan) -> String {
        let base: String
        if forcesTrialEligibilityForDebugging {
            base = "7 dias grátis, depois \(priceLine(for: plan))"
        } else {
            switch subscription.introductoryOfferEligibility(for: plan) {
            case .eligible where subscription.hasConfirmedFreeTrial(for: plan):
                base = "7 dias grátis, depois \(priceLine(for: plan))"
            case .unknown:
                return "Verificando oferta com a App Store"
            case .eligible, .ineligible:
                base = "Assinatura por \(priceLine(for: plan))"
            }
        }
        if plan == .yearly, let equivalent = subscription.monthlyEquivalentDisplayPrice(for: .yearly) {
            return base + " · sai por \(equivalent)/mês"
        }
        return base
    }

    private func showsEligibleTrial(for plan: SubscriptionPlan) -> Bool {
        forcesTrialEligibilityForDebugging || subscription.hasEligibleFreeTrial(for: plan)
    }

    private func period(for plan: SubscriptionPlan) -> String {
        plan == .yearly ? "ano" : "mês"
    }
}

private struct SubscriptionGateCompliance: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    let termsURL: URL
    let privacyURL: URL
    let forcesTrialEligibilityForDebugging: Bool

    var body: some View {
        VStack(spacing: 9) {
            Button {
                Task {
                    await subscription.purchaseSelectedPlan(origin: .subscriptionGate)
                }
            } label: {
                HStack(spacing: 9) {
                    if subscription.state == .purchasing {
                        ProgressView().tint(Color.deepInk)
                    }
                    Text(buttonTitle)
                    Image(systemName: "arrow.right")
                }
                .conversionFont(16, weight: .semibold, relativeTo: .headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.deepInk)
            }
            .disabled(!canSubscribe)
            .opacity(canSubscribe ? 1 : 0.62)

            if forcesTrialEligibilityForDebugging || subscription.hasEligibleFreeTrial(for: subscription.selectedPlan) {
                Text("Hoje você não paga nada.")
                    .conversionFont(13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Color.sageButton)
                    .frame(maxWidth: .infinity)
            }

            Text("A assinatura renova automaticamente. Cancele a qualquer momento em Ajustes > Assinaturas. Para não ser cobrado, cancele até 24h antes do fim do período vigente.")
                .conversionFont(11, relativeTo: .caption)
                .foregroundStyle(Color.softText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            if let statusText {
                Text(statusText)
                    .conversionFont(12, weight: .medium, relativeTo: .footnote)
                    .foregroundStyle(Color.softText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if showsRetryButton {
                Button {
                    Task { await subscription.recoverIfNeeded() }
                } label: {
                    Label("Tentar novamente", systemImage: "arrow.clockwise")
                        .conversionFont(14, weight: .semibold, relativeTo: .footnote)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.sageButton.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.sageButton.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(Color.sageButton)
                }
                .accessibilityLabel("Tentar carregar os planos novamente")
            }

            Button {
                Task {
                    await subscription.restorePurchases(origin: .subscriptionGate)
                }
            } label: {
                Label("Restaurar compras", systemImage: "arrow.clockwise")
                    .conversionFont(13, weight: .semibold, relativeTo: .footnote)
            }
            .disabled(subscription.isBusy)

            HStack(spacing: 18) {
                Button("Termos de Uso") { openURL(termsURL) }
                Button("Política de Privacidade") { openURL(privacyURL) }
            }
            .conversionFont(12, weight: .medium, relativeTo: .footnote)
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.deepInk.opacity(0.97))
        .overlay(alignment: .top) {
            Divider().overlay(Color.conversionBorder)
        }
    }

    private var canSubscribe: Bool {
        subscription.canPurchase(subscription.selectedPlan)
            && subscription.introductoryOfferEligibility(for: subscription.selectedPlan) != .unknown
    }

    /// A primeira carga de produtos pode falhar (sem rede no fim do
    /// onboarding). O portão não tem bypass, então precisa oferecer uma
    /// saída explícita em vez de ficar com o CTA desabilitado para sempre.
    private var showsRetryButton: Bool {
        guard !subscription.isBusy else { return false }
        if subscription.products.isEmpty { return true }
        if case .failed = subscription.state { return true }
        return false
    }

    private var buttonTitle: String {
        let plan = subscription.selectedPlan
        if forcesTrialEligibilityForDebugging || subscription.hasEligibleFreeTrial(for: plan) {
            return "Começar 7 dias grátis"
        }
        if subscription.introductoryOfferEligibility(for: plan) == .unknown,
           subscription.product(for: plan) != nil {
            return "Verificando oferta..."
        }
        guard subscription.product(for: plan) != nil else {
            return subscription.products.isEmpty ? "Carregando planos" : "Plano indisponível"
        }
        return "Assinar por \(subscription.storeDisplayPrice(for: plan))"
    }

    private var statusText: String? {
        switch subscription.state {
        case .purchased, .restored, .pending, .cancelled, .productsUnavailable, .failed:
            return subscription.statusText
        case .idle, .loadingProducts, .purchasing, .active, .expired:
            return nil
        }
    }
}

struct ConversionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .conversionFont(12, weight: .bold, relativeTo: .caption)
                .tracking(2)
                .foregroundStyle(Color.warmGold)

            Text(title)
                .conversionFont(27, design: .serif, relativeTo: .title)
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .conversionFont(15)
                    .foregroundStyle(Color.softText)
                    .lineSpacing(4)
            }
        }
    }
}

struct ConversionContrastLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark")
                .conversionFont(13, weight: .bold)
                .foregroundStyle(Color.sageButton)
            Text(text)
                .conversionFont(14, weight: .medium)
                .foregroundStyle(Color.softText)
                .lineSpacing(3)
        }
    }
}

struct ConversionLossBlock: View {
    let title: String
    let finalItem: String

    private var items: [String] {
        [
            "Reflexão completa: significado, aplicação e pergunta",
            "Narração com voz natural",
            "Tradição, profundidade e livros do seu jeito",
            "Salvar trechos e rever seu histórico",
            finalItem
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .conversionFont(14, weight: .semibold)
                .foregroundStyle(Color.ivory)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ConversionListRow(symbol: "xmark", color: Color.conversionCoral, text: item)
                    if index < items.count - 1 {
                        Divider().overlay(Color.conversionDivider)
                    }
                }
            }
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        }
    }
}

struct ConversionListRow: View {
    let symbol: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .conversionFont(15, weight: .bold)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .conversionFont(15)
                .foregroundStyle(Color(red: 0.79, green: 0.81, blue: 0.79))
                .lineSpacing(3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

struct ConversionPlanPicker: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Binding var selection: SubscriptionPlan

    var body: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases.sorted { $0.sortOrder < $1.sortOrder }) { plan in
                Button {
                    selection = plan
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        if plan == .yearly {
                            Text("MAIS ESCOLHIDO")
                                .conversionFont(11, weight: .bold, relativeTo: .caption)
                                .tracking(1)
                                .foregroundStyle(Color.deepInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.sageButton, in: Capsule())
                        }

                        HStack(spacing: 8) {
                            Image(systemName: selection == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == plan ? Color.sageButton : Color.softText)
                            Text(plan.title)
                                .conversionFont(17, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                            Spacer(minLength: 8)
                            Text(mainPrice(for: plan))
                                .conversionFont(16, weight: .semibold, relativeTo: .headline)
                                .foregroundStyle(Color.ivory)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .layoutPriority(1)
                        }

                        Text(detail(for: plan))
                            .conversionFont(13, weight: .medium, relativeTo: .footnote)
                            .foregroundStyle(Color.softText)
                            .padding(.leading, 31)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(selection == plan ? Color(red: 0.086, green: 0.13, blue: 0.12) : Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selection == plan ? Color.sageButton : Color.conversionBorder, lineWidth: selection == plan ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func mainPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            return "\(subscription.displayPrice(for: plan))/ano"
        case .monthly:
            return "\(subscription.displayPrice(for: plan))/mês"
        }
    }

    private func detail(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            guard let daily = subscription.dailyEquivalentPrice(for: plan) else {
                return "Cobrado uma vez por ano"
            }
            return "Menos de \(daily) por dia · cobrado uma vez por ano"
        case .monthly:
            return "Renovação mensal · cancele quando quiser"
        }
    }
}

struct ConversionPurchaseSection: View {
    @Environment(SubscriptionManager.self) private var subscription
    let buttonTitle: String
    let escapeTitle: String
    var escapeAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Button {
                Task { await subscription.purchaseSelectedPlan() }
            } label: {
                HStack(spacing: 10) {
                    if subscription.state == .purchasing {
                        ProgressView().tint(Color.deepInk)
                    }
                    Text(buttonTitle)
                    Image(systemName: "arrow.right")
                }
                .conversionFont(17, weight: .semibold, relativeTo: .headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.deepInk)
            }
            .disabled(!subscription.canPurchase(subscription.selectedPlan))
            .opacity(subscription.canPurchase(subscription.selectedPlan) ? 1 : 0.62)

            Button { escapeAction?() } label: {
                ConversionSecondaryActionLabel(title: escapeTitle)
            }

            Text("Cancele quando quiser · A App Store confirma antes de cobrar")
                .conversionFont(12, relativeTo: .footnote)
                .foregroundStyle(Color.softText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(subscription.renewalDisclosure(for: subscription.selectedPlan))
                .conversionFont(12, relativeTo: .footnote)
                .foregroundStyle(Color.softText.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !subscription.statusText.isEmpty {
                Text(subscription.statusText)
                    .conversionFont(14, weight: .medium)
                    .foregroundStyle(Color.softText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ConversionSecondaryActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .conversionFont(15, weight: .semibold)
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.sageButton.opacity(0.75), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConversionLegalLinks: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    let termsURL: URL
    let privacyURL: URL

    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task { await subscription.restorePurchases() }
            } label: {
                Label("Restaurar compra", systemImage: "arrow.clockwise")
                    .conversionFont(13, weight: .semibold, relativeTo: .footnote)
            }
            .disabled(subscription.isBusy)

            HStack(spacing: 18) {
                Button("Termos de Uso") { openURL(termsURL) }
                Button("Política de Privacidade") { openURL(privacyURL) }
            }
            .conversionFont(13, weight: .medium, relativeTo: .footnote)
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
        }
    }
}

extension Color {
    static let conversionPanel = Color(red: 0.067, green: 0.106, blue: 0.11)
    static let conversionBorder = Color(red: 0.141, green: 0.192, blue: 0.184)
    static let conversionDivider = Color(red: 0.114, green: 0.157, blue: 0.153)
    static let conversionCoral = Color(red: 0.847, green: 0.541, blue: 0.478)
}

#Preview {
    PaywallView(analyticsOrigin: .settings)
        .environment(LimiarAppModel())
        .environment(SubscriptionManager())
}
