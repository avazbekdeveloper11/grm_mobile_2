import 'package:flutter/material.dart';
import '../utils/phone_utils.dart';

/// Kichik qo'ng'iroq tugmasi — har qanday joyda ishlatiladi
class CallButton extends StatelessWidget {
  final String phone;
  final bool mini;

  const CallButton({super.key, required this.phone, this.mini = false});

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return IconButton.filled(
        icon: const Icon(Icons.call, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
        ),
        tooltip: formatPhone(phone),
        onPressed: () => callPhone(phone),
      );
    }

    return FilledButton.icon(
      icon: const Icon(Icons.call, size: 18),
      label: Text(formatPhone(phone)),
      onPressed: () => callPhone(phone),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 46),
      ),
    );
  }
}
