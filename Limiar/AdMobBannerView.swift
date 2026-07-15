import SwiftUI
import UIKit
@preconcurrency import GoogleMobileAds

enum LimiarAdMobConfiguration {
    static let appID = "ca-app-pub-7717198050770102~4802998011"

    #if DEBUG
    private static var debugBannerAdUnitID: String {
        if ProcessInfo.processInfo.arguments.contains("-LimiarAdMobForceFailure") {
            return "ca-app-pub-3940256099942544/0000000000"
        }
        return "ca-app-pub-3940256099942544/2934735716"
    }

    static var anchoredBannerAdUnitID: String { debugBannerAdUnitID }
    static var mrecAdUnitID: String { debugBannerAdUnitID }
    #else
    static let anchoredBannerAdUnitID = "ca-app-pub-7717198050770102/7996436288"
    static let mrecAdUnitID = "ca-app-pub-7717198050770102/2565100496"
    #endif
}

/// Banner adaptativo ancorado no rodape do dashboard Essencial.
/// O slot ocupa altura zero ate o delegate confirmar que o anuncio carregou.
struct LimiarAnchoredAdSlot: View {
    var body: some View {
        LimiarAdSlot(placement: .anchored)
    }
}

/// Retangulo 300x250 exibido uma unica vez, no final do conteudo Essencial.
/// O filho de 300pt e centralizado sem participar do calculo da largura do VStack,
/// portanto nao alarga o dashboard em telas estreitas como o iPhone SE.
struct LimiarMRECAdSlot: View {
    var body: some View {
        LimiarAdSlot(placement: .mrec)
    }
}

private enum LimiarAdPlacement: String {
    case anchored
    case mrec

    var adUnitID: String {
        switch self {
        case .anchored:
            LimiarAdMobConfiguration.anchoredBannerAdUnitID
        case .mrec:
            LimiarAdMobConfiguration.mrecAdUnitID
        }
    }

    func adSize(availableWidth: CGFloat) -> AdSize {
        switch self {
        case .anchored:
            currentOrientationAnchoredAdaptiveBanner(width: max(1, availableWidth))
        case .mrec:
            AdSizeMediumRectangle
        }
    }

    func adWidth(availableWidth: CGFloat) -> CGFloat {
        switch self {
        case .anchored:
            max(1, availableWidth)
        case .mrec:
            AdSizeMediumRectangle.size.width
        }
    }
}

private struct LimiarAdSlot: View {
    private static let labelHeight: CGFloat = 12
    private static let labelSpacing: CGFloat = 4
    private static let topPadding: CGFloat = 2
    private static let bottomPadding: CGFloat = 4

    let placement: LimiarAdPlacement

    @State private var loadedAdHeight: CGFloat = 0

    private var isLoaded: Bool {
        loadedAdHeight > 0
    }

    private var visibleHeight: CGFloat {
        guard isLoaded else { return 0 }
        return loadedAdHeight
            + Self.labelHeight
            + Self.labelSpacing
            + Self.topPadding
            + Self.bottomPadding
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(1, proxy.size.width)
            let adWidth = placement.adWidth(availableWidth: availableWidth)
            let requestedSize = placement.adSize(availableWidth: adWidth)

            VStack(alignment: .leading, spacing: Self.labelSpacing) {
                Text("Publicidade")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.softText.opacity(0.72))
                    .frame(width: adWidth, height: Self.labelHeight, alignment: .leading)

                LimiarBannerView(
                    placement: placement,
                    availableWidth: adWidth,
                    onLoadStateChange: updateLoadState
                )
                .frame(width: requestedSize.size.width, height: requestedSize.size.height)
            }
            .padding(.top, Self.topPadding)
            .padding(.bottom, Self.bottomPadding)
            .frame(width: adWidth, height: visibleHeight, alignment: .bottom)
            .position(x: availableWidth / 2, y: visibleHeight / 2)
            .opacity(isLoaded ? 1 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Publicidade")
            .accessibilityHidden(!isLoaded)
        }
        .frame(height: visibleHeight)
        .animation(.easeOut(duration: 0.24), value: visibleHeight)
    }

    private func updateLoadState(isLoaded: Bool, height: CGFloat) {
        let nextHeight = isLoaded ? height : 0
        guard abs(nextHeight - loadedAdHeight) > 0.5 else { return }
        loadedAdHeight = nextHeight
    }
}

private struct LimiarBannerView: UIViewRepresentable {
    let placement: LimiarAdPlacement
    let availableWidth: CGFloat
    let onLoadStateChange: @MainActor (Bool, CGFloat) -> Void

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        let placement: LimiarAdPlacement
        var configuredWidth: CGFloat = 0
        var hasRetried = false
        var onLoadStateChange: @MainActor (Bool, CGFloat) -> Void

        init(
            placement: LimiarAdPlacement,
            onLoadStateChange: @escaping @MainActor (Bool, CGFloat) -> Void
        ) {
            self.placement = placement
            self.onLoadStateChange = onLoadStateChange
        }

        func prepareForReload() {
            onLoadStateChange(false, 0)
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onLoadStateChange(true, bannerView.adSize.size.height)
            LimiarAIDiagnostics.log(
                "admob_banner_loaded",
                values: ["position": placement.rawValue]
            )
        }

        func bannerView(
            _ bannerView: BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            let nsError = error as NSError
            onLoadStateChange(false, 0)
            LimiarAIDiagnostics.log(
                "admob_banner_failed",
                values: [
                    "position": placement.rawValue,
                    "code": "\(nsError.code)",
                    "reason": Self.errorName(for: nsError.code)
                ]
            )

            // No maximo uma tentativa suave por ciclo de vida do placement.
            // O Coordinator nasce novamente quando o placement reaparece.
            guard !hasRetried else { return }
            hasRetried = true
            Task { @MainActor [weak bannerView] in
                try? await Task.sleep(for: .seconds(4))
                guard let bannerView else { return }
                bannerView.load(Request())
            }
        }

        private static func errorName(for code: Int) -> String {
            switch code {
            case 0: "invalidRequest"
            case 1: "noFill"
            case 2: "networkError"
            case 3: "serverError"
            case 5: "timeout"
            case 7: "mediationDataError"
            case 8: "mediationAdapterError"
            case 10: "mediationInvalidAdSize"
            case 11: "internalError"
            case 12: "invalidArgument"
            case 19: "adAlreadyUsed"
            case 20: "applicationIdentifierMissing"
            case 21: "receivedInvalidAdString"
            default: "unknown"
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(placement: placement, onLoadStateChange: onLoadStateChange)
    }

    func makeUIView(context: Context) -> BannerView {
        let width = max(1, availableWidth)
        let banner = BannerView(adSize: placement.adSize(availableWidth: width))
        banner.adUnitID = placement.adUnitID
        banner.backgroundColor = .clear
        banner.setContentHuggingPriority(.defaultLow, for: .horizontal)
        banner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        banner.rootViewController = UIApplication.shared.limiarRootViewController
        banner.delegate = context.coordinator
        context.coordinator.configuredWidth = width
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        let width = max(1, availableWidth)
        context.coordinator.onLoadStateChange = onLoadStateChange

        // A largura real do container e a unica fonte de verdade. Qualquer
        // realimentacao por bounds/intrinsicContentSize faria o dashboard crescer.
        if abs(context.coordinator.configuredWidth - width) > 1 {
            context.coordinator.prepareForReload()
            banner.adSize = placement.adSize(availableWidth: width)
            context.coordinator.configuredWidth = width
            banner.load(Request())
        }

        banner.rootViewController = UIApplication.shared.limiarRootViewController
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: BannerView,
        context: Context
    ) -> CGSize? {
        let adSize = placement.adSize(availableWidth: availableWidth).size
        return CGSize(
            width: min(proposal.width ?? adSize.width, adSize.width),
            height: adSize.height
        )
    }
}

private extension UIApplication {
    var limiarRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
