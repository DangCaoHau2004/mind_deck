import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareQrWidget extends StatelessWidget {
  final String targetType; // 'deck' or 'folder'
  final String targetId;
  final String shareToken;
  final String? customLink;

  const ShareQrWidget({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.shareToken,
    this.customLink,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Cần chỉnh lại đoạn này
    final String deepLinkData =
        customLink ?? "minddeck://minddeck.com/library/$targetType/$targetId?token=$shareToken";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: QrImageView(
        data: deepLinkData,
        version: QrVersions.auto,
        size: 250.0,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}
