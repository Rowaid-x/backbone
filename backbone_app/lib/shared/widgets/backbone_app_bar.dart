import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';

class BackboneAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const BackboneAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <= 900;
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: isNarrow
          ? IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
            )
          : null,
      automaticallyImplyLeading: false,
      title: Text(title),
      actions: actions,
    );
  }
}
