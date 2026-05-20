import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final BoxDecoration? decoration;
  final BoxDecoration? hoverDecoration;
  final VoidCallback? onTap;

  const HoverContainer({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 200),
    this.decoration,
    this.hoverDecoration,
    this.onTap,
  });

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? widget.scale : 1.0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            decoration: _isHovered 
                ? (widget.hoverDecoration ?? widget.decoration) 
                : widget.decoration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
