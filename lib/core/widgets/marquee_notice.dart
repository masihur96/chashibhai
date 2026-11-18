import 'package:flutter/material.dart';

class MarqueeNotice extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final Color? backgroundColor;
  final IconData? icon;

  const MarqueeNotice({
    super.key,
    required this.text,
    this.style,
    this.height = 36.0,
    this.backgroundColor,
    this.icon = Icons.campaign_rounded,
  });

  @override
  State<MarqueeNotice> createState() => _MarqueeNoticeState();
}

class _MarqueeNoticeState extends State<MarqueeNotice>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        maxExtent,
        duration: Duration(milliseconds: (maxExtent * 30).clamp(2000, 15000).toInt()),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: Colors.amber.shade900),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: widget.style ??
                    TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
