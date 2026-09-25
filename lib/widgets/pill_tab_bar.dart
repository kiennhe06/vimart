import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Thanh tab dạng "viên thuốc" (pill) dùng chung cho các màn có tab
/// (đơn hàng người mua / người bán). Đặt vào AppBar.bottom.
PreferredSizeWidget pillTabBar(List<String> labels) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(56),
    child: Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        indicator: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(30)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        splashBorderRadius: BorderRadius.circular(30),
        tabs: labels
            .map((l) => Tab(
                  height: 40,
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(l)),
                ))
            .toList(),
      ),
    ),
  );
}
