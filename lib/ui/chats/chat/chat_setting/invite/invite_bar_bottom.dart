import 'package:flutter/material.dart';
import 'package:cocochat_app/ui/app_colors.dart';

class InviteBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Tab> tabs;

  const InviteBarBottom({super.key, required this.controller, required this.tabs});

  @override
  Size get preferredSize => Size(double.maxFinite, 40);

  @override
  Widget build(BuildContext context) {
    return TabBar(
        labelColor: AppColors.primaryBlue,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelColor: AppColors.grey600,
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        controller: controller,
        tabs: tabs);
  }
}
