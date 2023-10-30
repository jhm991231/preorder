import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;  // 뒤로 가기 버튼을 표시할지 결정하는 변수

  CustomAppBar({
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: Color(0xff303742),
      leading: showBackButton // 뒤로 가기 버튼 표시 조건
          ? IconButton(
        icon: Icon(Icons.close),
        onPressed: () => Navigator.pop(context),  // 뒤로 가기 기능
      )
          : null,  // 아무것도 표시하지 않음
    );
  }
}

