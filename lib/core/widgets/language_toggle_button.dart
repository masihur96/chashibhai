import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/account/presentation/state/app_state_provider.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool compact;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const LanguageToggleButton({
    super.key,
    this.compact = false,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final isBangla = appState.isBangla;

    final primaryGreen = activeColor ?? const Color(0xFF2E7D32);
    final bgColor = backgroundColor ?? Colors.grey.shade100;
    final inActiveTextColor = inactiveColor ?? Colors.grey.shade600;

    if (compact) {
      // Compact circular / rounded button e.g. for AppBars
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => appState.toggleLocale(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 16, color: primaryGreen),
                const SizedBox(width: 5),
                Text(
                  isBangla ? 'বাং' : 'EN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full segmented pill toggle [ English | বাংলা ]
    return GestureDetector(
      onTap: () => appState.toggleLocale(),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // English Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !isBangla ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !isBangla
                    ? [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: !isBangla ? FontWeight.bold : FontWeight.w500,
                  color: !isBangla ? Colors.white : inActiveTextColor,
                ),
              ),
            ),
            // Bangla Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isBangla ? primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isBangla
                    ? [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'বাংলা',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBangla ? FontWeight.bold : FontWeight.w500,
                  color: isBangla ? Colors.white : inActiveTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
