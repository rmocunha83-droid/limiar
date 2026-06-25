import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL

    private let termsURL = URL(string: "https://limiar-five.vercel.app/terms.html")!
    private let privacyURL = URL(string: "https://limiar-five.vercel.app/privacy.html")!

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if subscription.accessState == .trialExpired {
                        TrialMetricsPanel()
                    }
                    benefits
                    planPicker(selection: $subscription.selectedPlan)
                    primaryAction
                    restoreAndLegal
                }
                .padding(.horizontal, 22)
                .padding(.top, 58)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            subscription.start()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("LimiarLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)

            Text("Limiar Premium")
                .font(.system(size: 46, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(subscription.accessState == .trialExpired ? 0 : 1)
                .overlay(alignment: .leading) {
                    if subscription.accessState == .trialExpired {
                        Text("Continue sua jornada com o Limiar")
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

            Text(headerSubtitle)
                .font(.system(size: 19))
                .foregroundStyle(Color.softText)
                .lineSpacing(5)

            Text(headerDisclosure)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .lineSpacing(4)
        }
    }

    private var headerSubtitle: String {
        if subscription.accessState == .trialExpired {
            return "Você ainda pode continuar no Modo Essencial com os trechos principais. Para ter reflexões personalizadas, narração e maior variedade, assine o Limiar completo."
        }
        return "Transforme a pausa antes dos apps selecionados em um momento de reflexão."
    }

    private var headerDisclosure: String {
        if subscription.accessState == .trialExpired {
            return "Seu teste gratuito terminou. O Modo Essencial continua disponível sem chamadas de IA."
        }
        return "Depois dos 7 dias grátis, R$ 9,90/mês. Cancele quando quiser."
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaywallBenefit(icon: "sparkles", text: "Leituras e reflexões espirituais personalizadas")
            PaywallBenefit(icon: "text.bubble", text: "IA com explicações em linguagem simples")
            PaywallBenefit(icon: "book.closed", text: "Escolha de religião, temas e livros preferidos")
            PaywallBenefit(icon: "slider.horizontal.3", text: "Reflexões curtas, médias ou longas")
            PaywallBenefit(icon: "arrow.triangle.2.circlepath", text: "Novas mensagens com menos repetição")
            PaywallBenefit(icon: "clock.arrow.circlepath", text: "Histórico de leituras")
            PaywallBenefit(icon: "sunrise.fill", text: "Pausas conscientes antes dos apps selecionados")
        }
        .padding(16)
        .limiarPanel()
    }

    private func planPicker(selection: Binding<SubscriptionPlan>) -> some View {
        VStack(spacing: 12) {
            ForEach([SubscriptionPlan.monthly]) { plan in
                PaywallPlanRow(
                    plan: plan,
                    price: subscription.displayPrice(for: plan),
                    detailText: subscription.planDetailText(for: plan),
                    trialText: subscription.trialText(for: plan),
                    hasFreeTrial: subscription.hasConfirmedFreeTrial(for: plan),
                    isSelected: selection.wrappedValue == plan
                ) {
                    selection.wrappedValue = plan
                }
            }
        }
    }

    private var primaryAction: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await subscription.purchaseSelectedPlan()
                }
            } label: {
                HStack(spacing: 12) {
                    if subscription.state == .purchasing {
                        ProgressView()
                            .tint(Color.deepInk)
                    }
                    Text("Assinar por R$ 9,90/mês")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.deepInk)
            }
            .disabled(!subscription.canPurchase(subscription.selectedPlan))
            .opacity(subscription.canPurchase(subscription.selectedPlan) ? 1 : 0.62)

            Text("Assinatura mensal de R$ 9,90/mês. Cancele quando quiser.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.softText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text("A assinatura renova automaticamente, salvo cancelamento pelo menos 24 horas antes do fim do período atual.")
                .font(.system(size: 12))
                .foregroundStyle(Color.softText.opacity(0.86))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !subscription.statusText.isEmpty {
                Text(subscription.statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(statusColor)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
    }

    private var restoreAndLegal: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    await subscription.restorePurchases()
                }
            } label: {
                Label("Restaurar compra", systemImage: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .disabled(subscription.isBusy)

            NavigationLink {
                SettingsView()
            } label: {
                Label("Configurações básicas", systemImage: "gearshape")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 1))
            }

            HStack(spacing: 18) {
                Button("Termos de Uso") {
                    openURL(termsURL)
                }
                Button("Política de Privacidade") {
                    openURL(privacyURL)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
        }
    }

    private var statusColor: Color {
        switch subscription.state {
        case .failed, .productsUnavailable:
            return Color.warmGold
        case .purchased, .restored, .active:
            return Color.sageButton
        default:
            return Color.softText
        }
    }
}

private struct PaywallBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ivory)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PaywallPlanRow: View {
    let plan: SubscriptionPlan
    let price: String
    let detailText: String
    let trialText: String
    let hasFreeTrial: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.sageButton : Color.softText)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.ivory)

                        if plan == .yearly {
                            Text("Melhor oferta")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.warmGold.opacity(0.22), in: Capsule())
                                .foregroundStyle(Color.warmGold)
                        }
                    }

                    Text(price)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.ivory)

                    Text(detailText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.softText)

                    if plan == .yearly {
                        Text(yearlyEmphasisText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.sageButton)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.07), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.sageButton.opacity(0.70) : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }

    private var yearlyEmphasisText: String {
        hasFreeTrial ? "\(trialText). Economize no plano anual." : "Economize no plano anual."
    }

    private var accessibilityText: String {
        hasFreeTrial ? "\(plan.title), \(price), \(trialText)" : "\(plan.title), \(price)"
    }
}

#Preview {
    PaywallView()
        .environment(LimiarAppModel())
        .environment(SubscriptionManager())
}
