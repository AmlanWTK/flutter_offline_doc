import 'package:flutter/material.dart';

enum DocumentCategory {
  all,
  study,
  finance,
  legal,
  receipts,
  work,
  personal,
}

extension DocumentCategoryExtension on DocumentCategory {
  String get label {
    switch (this) {
      case DocumentCategory.all:     return 'All';
      case DocumentCategory.study:   return 'Study';
      case DocumentCategory.finance: return 'Finance';
      case DocumentCategory.legal:   return 'Legal';
      case DocumentCategory.receipts:return 'Receipts';
      case DocumentCategory.work:    return 'Work';
      case DocumentCategory.personal:return 'Personal';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategory.all:     return Icons.grid_view_rounded;
      case DocumentCategory.study:   return Icons.school_outlined;
      case DocumentCategory.finance: return Icons.account_balance_outlined;
      case DocumentCategory.legal:   return Icons.gavel_outlined;
      case DocumentCategory.receipts:return Icons.receipt_long_outlined;
      case DocumentCategory.work:    return Icons.work_outline;
      case DocumentCategory.personal:return Icons.person_outline;
    }
  }

  Color get color {
    switch (this) {
      case DocumentCategory.all:     return const Color(0xFF6750A4);
      case DocumentCategory.study:   return const Color(0xFF0077B6);
      case DocumentCategory.finance: return const Color(0xFF2D6A4F);
      case DocumentCategory.legal:   return const Color(0xFF7B2D8B);
      case DocumentCategory.receipts:return const Color(0xFFD4A017);
      case DocumentCategory.work:    return const Color(0xFFE07B39);
      case DocumentCategory.personal:return const Color(0xFFD62839);
    }
  }
}
