import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../templates/models/invitation_data.dart';
import '../templates/template_resolver.dart';

class SharingService {
  static Future<Uint8List?> captureTemplateAsImage({
    required String? templateClassName,
    required String eventType,
    required InvitationData data,
    double pixelRatio = 3.0,
  }) async {
    final widget = TemplateResolver.resolve(
      templateId: null,
      className: templateClassName,
      eventType: eventType,
      data: data,
    );

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: const BoxConstraints(maxWidth: 390, maxHeight: 700),
        devicePixelRatio: pixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<String> saveToTemp(Uint8List bytes, String eventName) async {
    final dir = await getTemporaryDirectory();
    final safeName = eventName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/invitation_$safeName.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> shareInvitationImage({
    required String filePath,
    required String eventName,
    String? caption,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'image/png')],
        text: caption ?? 'Invitation à $eventName — Créé avec INVYRA',
        subject: 'Invitation à $eventName',
      ),
    );
  }

  static Future<void> sendTextViaWhatsApp({
    required String phone,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  static Future<void> sendViaEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final url = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
