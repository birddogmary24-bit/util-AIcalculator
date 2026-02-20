import 'package:flutter/material.dart';

class ToolScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottomAction;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: children,
      ),
      bottomNavigationBar: bottomAction != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: bottomAction,
              ),
            )
          : null,
    );
  }
}
