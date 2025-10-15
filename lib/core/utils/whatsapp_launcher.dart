import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nookat996/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class WhatsAppLauncher {
  static String normalizePhoneForWa(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    String phone = cleaned;
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) phone = '996${phone.substring(1)}';
    return phone;
  }

  static Future<void> launch(BuildContext context, {
    required String phone,
    String message = '',
  }) async {
    final waPhone = normalizePhoneForWa(phone);
    final waUri = Uri.parse('whatsapp://send?phone=$waPhone&text=${Uri.encodeComponent(message)}');

    try {
      final canWa = await canLaunchUrl(waUri);
      if (canWa) {
        final launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть WhatsApp')),
          );
        }
        return;
      }

      if (Platform.isIOS) {
        await _showNotInstalledDialog(context, waPhone, message, ios: true);
      } else {
        await _showNotInstalledDialog(context, waPhone, message, ios: false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при открытии WhatsApp: $e')),
        );
      }
    }
  }

  static Future<void> _showNotInstalledDialog(BuildContext context, String waPhone, String message, {required bool ios}) async {
    final storeUrl = ios
        ? 'https://apps.apple.com/app/whatsapp-messenger/id310633997'
        : 'https://play.google.com/store/apps/details?id=com.whatsapp';
    final webUri = Uri.parse('https://wa.me/$waPhone?text=${Uri.encodeComponent(message)}');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.whatsapp, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'whatsapp_unavailable_title'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'whatsapp_unavailable_body'.tr(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(storeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(ios ? 'open_app_store'.tr() : 'open_play_market'.tr()),
                  ),
                ),
                const SizedBox(height: 10),
                if (!ios)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (await canLaunchUrl(webUri)) {
                          await launchUrl(webUri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text('open_in_browser'.tr()),
                    ),
                  ),
                if (!ios) const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final e164 = waPhone.startsWith('996') ? '+$waPhone' : '+$waPhone';
                      await Clipboard.setData(ClipboardData(text: e164));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('number_copied'.tr())),
                        );
                      }
                    },
                    child: Text('copy_number'.tr()),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(ctx).maybePop(),
                  child: Text('cancel'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
