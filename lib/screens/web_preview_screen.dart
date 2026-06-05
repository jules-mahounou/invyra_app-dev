import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/theme/app_colors.dart';

class WebPreviewScreen extends StatefulWidget {
  final String webTemplateKey;
  final String templateName;

  const WebPreviewScreen({
    required this.webTemplateKey,
    required this.templateName,
    super.key,
  });

  @override
  State<WebPreviewScreen> createState() => _WebPreviewScreenState();
}

class _WebPreviewScreenState extends State<WebPreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    
    final String baseUrl = "https://invyra-web.vercel.app/preview";
    final String fullUrl = "$baseUrl/${widget.webTemplateKey}";

    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Erreur WebView: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Aperçu : ${widget.templateName}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // La page web Next.js qui tourne de manière fluide
          WebViewWidget(controller: _controller),
          
          // Indicateur de chargement pendant que Next.js s'initialise
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.violetRoyal),
              ),
            ),
        ],
      ),
    );
  }
}