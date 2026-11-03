import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config.dart';
import '../services/order_service.dart';

/// Presents Square's Web Payments SDK card form in a WebView, tokenizes the card,
/// and returns the single-use token via `Navigator.pop(context, token)`.
class SquareCardPage extends StatefulWidget {
  const SquareCardPage({super.key, required this.displayAmount});
  final String displayAmount;

  @override
  State<SquareCardPage> createState() => _SquareCardPageState();
}

class _SquareCardPageState extends State<SquareCardPage> {
  WebViewController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final cfg = await OrderService().paymentConfig();
      final appId = cfg['applicationID'] as String;
      final locId = cfg['locationID'] as String;
      final sandbox = (cfg['environment'] as String?) == 'sandbox';

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel('SquareChannel',
            onMessageReceived: (m) => _onMessage(m.message));
      await controller.loadHtmlString(
        _html(appId, locId, sandbox, widget.displayAmount),
        baseUrl: AppConfig.apiBaseUrl, // https origin — required by the SDK
      );
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Payments unavailable: $e');
    }
  }

  void _onMessage(String raw) {
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final token = obj['token'] as String?;
      if (token != null) {
        Navigator.of(context).pop(token);
        return;
      }
      final err = obj['error'] as String? ?? 'Card could not be processed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: _controller!),
    );
  }

  String _html(String appId, String locId, bool sandbox, String amount) {
    final sdk = sandbox
        ? 'https://sandbox.web.squarecdn.com/v1/square.js'
        : 'https://web.squarecdn.com/v1/square.js';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <script src="$sdk"></script>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, system-ui, sans-serif; margin: 0; padding: 20px; background: #fff; color: #262626; }
    #card-container { margin-bottom: 20px; min-height: 90px; }
    #pay-button { width: 100%; padding: 16px; font-size: 17px; font-weight: 600; color: #fff; background: #F2669A; border: none; border-radius: 10px; }
    #pay-button:disabled { background: #cccccc; }
    #status { margin-top: 12px; color: #E54D4D; font-size: 14px; min-height: 18px; }
  </style>
</head>
<body>
  <div id="card-container"></div>
  <button id="pay-button">Pay $amount</button>
  <div id="status"></div>
  <script>
    function post(msg) { SquareChannel.postMessage(JSON.stringify(msg)); }
    function setStatus(t) { document.getElementById('status').textContent = t || ''; }
    async function main() {
      if (!window.Square) { post({ error: 'Could not load the payment form.' }); return; }
      let payments, card;
      try {
        payments = window.Square.payments('$appId', '$locId');
        card = await payments.card();
        await card.attach('#card-container');
      } catch (e) { post({ error: 'Could not initialize payments: ' + (e.message || e) }); return; }
      const button = document.getElementById('pay-button');
      button.addEventListener('click', async () => {
        button.disabled = true; setStatus('');
        try {
          const result = await card.tokenize();
          if (result.status === 'OK') { post({ token: result.token }); }
          else { const m = (result.errors && result.errors[0] && result.errors[0].message) || 'Card could not be processed.'; setStatus(m); post({ error: m }); button.disabled = false; }
        } catch (e) { setStatus(e.message || 'Payment error'); post({ error: e.message || 'Payment error' }); button.disabled = false; }
      });
    }
    main();
  </script>
</body>
</html>
''';
  }
}
