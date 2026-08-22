import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/chat_store.dart';
import '../core/wallet_manager.dart';

/// Opens the photo-KYC modal.
void showKycSheet(BuildContext context, {required VoidCallback onVerified}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => KycVerificationSheet(onVerified: onVerified),
  );
}

/// Photo KYC: pick a document photo; submitting awards the +50,000 $TYP0K
/// bonus instantly and posts the green receipt to the @wallet chat.
class KycVerificationSheet extends StatefulWidget {
  final VoidCallback onVerified;

  const KycVerificationSheet({super.key, required this.onVerified});

  @override
  State<KycVerificationSheet> createState() => _KycVerificationSheetState();
}

class _KycVerificationSheetState extends State<KycVerificationSheet> {
  XFile? _image;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _image = picked);
    }
  }

  void _submit() {
    if (_image == null) return;

    WalletManager.I.verifyKYC();
    HapticFeedback.mediumImpact();
    ChatStore.I.postMessage(
      chatId: ChatStore.walletChatId,
      senderId: ChatStore.walletBotId,
      text: '✅ Верификация успешна! Вам начислено 50,000 \$TYP0K. Баланс обновлен.',
    );

    Navigator.of(context).pop();
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF10151F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Верификация',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _pick,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2230),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner_rounded,
                                size: 40, color: Color(0xFF3D9BFF)),
                            SizedBox(height: 10),
                            Text('Выбрать фото документа',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('PNG или JPG',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white38)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          child: Image.file(
                            File(_image!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Загрузите фото документа. После проверки на ваш кошелёк будет начислено +50,000 \$TYP0K.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _image == null ? null : _submit,
                child: const Text('Подтвердить аккаунт'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
