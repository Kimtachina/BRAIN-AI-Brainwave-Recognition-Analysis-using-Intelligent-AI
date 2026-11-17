import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// กลุ่มรายการแบบหน้าตั้งค่าของแอปใหญ่ (iOS Settings / Android Settings / Google Account)
/// หัวข้อเล็กด้านบน แผ่นขาวขอบบาง รายการคั่นด้วยเส้นที่เยื้องตามไอคอน และคำอธิบายใต้กลุ่ม
class SettingsGroup extends StatelessWidget {
  final String? title;
  final String? footer;
  final List<Widget> children;

  const SettingsGroup({super.key, this.title, this.footer, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(height: 1, thickness: 1, indent: 60, color: AppColors.line));
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(title!, style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600)),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card - 1),
              child: Column(children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(footer!, style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }
}

/// หนึ่งแถวในกลุ่ม: ไอคอน ชื่อ คำอธิบาย ค่าปัจจุบันชิดขวา และลูกศรเมื่อกดเข้าไปต่อได้
class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  /// ค่าว่าง: แสดงคำชวนกรอก (สีหลัก) แทนค่า
  final String? emptyHint;

  const SettingsTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.error : AppColors.ink;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final showHint = !hasValue && emptyHint != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: destructive ? AppColors.error.withValues(alpha: 0.08) : AppColors.paper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: destructive ? AppColors.error : AppColors.inkSoft),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body.copyWith(fontSize: 15, color: fg)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(subtitle!, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                if (hasValue || showHint) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      hasValue ? value! : emptyHint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.small.copyWith(
                        color: showHint ? AppColors.primary : AppColors.inkFaint,
                        fontWeight: showHint ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (onTap != null && !destructive) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkFaint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// แถวที่มีสวิตช์ กดได้ทั้งแถว
class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.surface,
          activeTrackColor: AppColors.primary,
        ),
      ),
    );
  }
}

/// ช่องค้นหาสไตล์เดียวกันทั้งแอป
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.inkFaint),
          suffixIcon: v.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'ล้างคำค้น',
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkSoft),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

/// ตัวอักษรตัวแรกในวงกลม หรือรูปโปรไฟล์ถ้ามี
class UserAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;

  const UserAvatar({super.key, required this.name, this.url, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        image: hasUrl ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: hasUrl
          ? null
          : Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : 'U',
              style: AppTextStyles.heading.copyWith(color: AppColors.primaryDeep, fontSize: size * 0.4),
            ),
    );
  }
}
