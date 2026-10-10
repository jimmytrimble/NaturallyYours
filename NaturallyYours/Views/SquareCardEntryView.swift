import SwiftUI
import WebKit

/// Presents Square's **Web Payments SDK** card form in a `WKWebView`, tokenizes the
/// entered card, and returns the resulting single-use nonce. This avoids a native
/// SDK dependency while producing a real token that the server's `/api/checkout`
/// charges via the Square Payments API.
struct SquareCardEntrySheet: View {
    /// Amount shown on the pay button (display only — the server charges the real total).
    let displayAmount: String
    let onResult: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var config: PaymentConfig?
    @State private var loadError: String?
    @State private var cardError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let config {
                    SquareWebView(
                        config: config,
                        payButtonTitle: "Pay \(displayAmount)",
                        onToken: { token in
                            onResult(token)
                            dismiss()
                        },
                        onError: { message in cardError = message }
                    )
                    .ignoresSafeArea(edges: .bottom)
                } else if let loadError {
                    ContentUnavailableView {
                        Label("Payments Unavailable", systemImage: "creditcard.trianglebadge.exclamationmark")
                    } description: {
                        Text(loadError)
                    }
                } else {
                    ProgressView("Loading secure payment…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Card Error", isPresented: Binding(
                get: { cardError != nil },
                set: { if !$0 { cardError = nil } }
            )) {
                Button("OK") { cardError = nil }
            } message: {
                Text(cardError ?? "")
            }
            .task {
                do {
                    config = try await APIClient.shared.get("/api/payments/config")
                } catch {
                    loadError = (error as? APIError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

// MARK: - WKWebView wrapper

private struct SquareWebView: UIViewRepresentable {
    let config: PaymentConfig
    let payButtonTitle: String
    let onToken: (String) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onToken: onToken, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "square")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.loadHTMLString(
            Self.html(config: config, payButtonTitle: payButtonTitle),
            // An https base URL gives the page a secure origin, which the Web Payments
            // SDK requires to initialize.
            baseURL: URL(string: "https://naturallyyoursbeautysupply.com/")
        )
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "square")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onToken: (String) -> Void
        let onError: (String) -> Void

        init(onToken: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onToken = onToken
            self.onError = onError
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            if let token = body["token"] as? String {
                onToken(token)
            } else if let error = body["error"] as? String {
                onError(error)
            }
        }
    }

    /// Inline page that loads the Square Web Payments SDK, renders the card form, and
    /// posts the tokenization result back to Swift via the `square` message handler.
    private static func html(config: PaymentConfig, payButtonTitle: String) -> String {
        let sdkURL = config.isSandbox
            ? "https://sandbox.web.squarecdn.com/v1/square.js"
            : "https://web.squarecdn.com/v1/square.js"

        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <script src="\(sdkURL)"></script>
          <style>
            :root { color-scheme: light dark; }
            * { box-sizing: border-box; -webkit-user-select: none; }
            body {
              font-family: -apple-system, system-ui, sans-serif;
              margin: 0; padding: 20px;
              background: #ffffff; color: #262626;
            }
            #card-container { margin-bottom: 20px; min-height: 90px; }
            #pay-button {
              width: 100%; padding: 16px; font-size: 17px; font-weight: 600;
              color: #fff; background: #F2669A; border: none; border-radius: 10px;
            }
            #pay-button:disabled { background: #cccccc; opacity: 0.6; }
            #status { margin-top: 12px; color: #E54D4D; font-size: 14px; min-height: 18px; }

            /* Follow the device appearance so the sheet isn't a white flash in dark mode. */
            @media (prefers-color-scheme: dark) {
              body { background: #1c1c1e; color: #f2f2f7; }
              #pay-button:disabled { background: #3a3a3c; }
            }
          </style>
        </head>
        <body>
          <div id="card-container"></div>
          <button id="pay-button">\(payButtonTitle)</button>
          <div id="status"></div>
          <script>
            function post(msg) { window.webkit.messageHandlers.square.postMessage(msg); }
            function setStatus(t) { document.getElementById('status').textContent = t || ''; }

            async function main() {
              if (!window.Square) { post({ error: 'Could not load the payment form. Check your connection.' }); return; }
              let payments, card;
              try {
                payments = window.Square.payments('\(config.applicationID)', '\(config.locationID)');
                const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                const cardStyle = dark ? {
                  input: { color: '#f2f2f7', backgroundColor: '#2c2c2e' },
                  'input::placeholder': { color: '#8e8e93' }
                } : {
                  input: { color: '#262626', backgroundColor: '#ffffff' },
                  'input::placeholder': { color: '#8e8e93' }
                };
                card = await payments.card({ style: cardStyle });
                await card.attach('#card-container');
              } catch (e) {
                post({ error: 'Could not initialize payments: ' + (e.message || e) });
                return;
              }

              const button = document.getElementById('pay-button');
              button.addEventListener('click', async () => {
                button.disabled = true;
                setStatus('');
                try {
                  const result = await card.tokenize();
                  if (result.status === 'OK') {
                    post({ token: result.token });
                  } else {
                    const msg = (result.errors && result.errors[0] && result.errors[0].message) || 'Card could not be processed.';
                    setStatus(msg);
                    post({ error: msg });
                    button.disabled = false;
                  }
                } catch (e) {
                  setStatus(e.message || 'Payment error');
                  post({ error: e.message || 'Payment error' });
                  button.disabled = false;
                }
              });
            }
            main();
          </script>
        </body>
        </html>
        """
    }
}
