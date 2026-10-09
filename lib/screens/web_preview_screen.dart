import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/widgets/app_loader.dart';
import '../models/event_model.dart';

class WebPreviewScreen extends StatefulWidget {
  final String webTemplateKey;
  final String templateName;
  final EventModel? event; // si null → mode démo avec données fictives

  const WebPreviewScreen({
    required this.webTemplateKey,
    required this.templateName,
    this.event,
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

    final String baseUrl = "https://invyra-web.vercel.app/preview/${widget.webTemplateKey}";
    final String fullUrl = _buildUrl(baseUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (e) => debugPrint("Erreur WebView: ${e.description}"),
        ),
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  String _buildUrl(String base) {
    final event = widget.event;
    if (event == null) return base;

    final params = <String, String>{};
    params['name'] = event.name;
    params['place'] = event.place;
    if (event.description.isNotEmpty) params['description'] = event.description;
    if (event.eventDate != null) {
      params['event_date'] = event.eventDate!.toIso8601String();
    }
    if (event.logoUrl != null && event.logoUrl!.isNotEmpty) {
      params['logo_url'] = event.logoUrl!;
    }
    if (event.hasCustomField1) {
      params['cf1_label'] = event.customField1Label!;
      params['cf1_value'] = event.customField1Value!;
    }
    if (event.hasCustomField2) {
      params['cf2_label'] = event.customField2Label!;
      params['cf2_value'] = event.customField2Value!;
    }
    // Passer toute la customization encodée en JSON
    if (event.customization.isNotEmpty) {
      params['customization'] = jsonEncode(event.customization);
    }

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$base?$query';
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const AppLoader(size: 60),
        ],
      ),
    );
  }
}
