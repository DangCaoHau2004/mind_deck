import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Đồng bộ nền xám nhạt để nổi bật các khối trắng
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cài đặt', style: theme.textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'TÀI KHOẢN & BẢO MẬT'),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              context: context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  iconColor: colorScheme.primary,
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.devices_rounded,
                  title: 'Quản lý thiết bị',
                  subtitle: 'Đăng xuất từ xa',
                  iconColor: colorScheme.secondary,
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.link_rounded,
                  title: 'Liên kết Google',
                  iconColor: colorScheme.tertiary,
                  trailing: Text(
                    'Đã liên kết',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'TÙY CHỈNH'),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              context: context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Thông báo & Nhắc nhở',
                  iconColor: colorScheme.primary,
                ),
                _buildDivider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Giao diện',
                  iconColor: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                label: Text(
                  'Đăng xuất',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Thêm viền nhẹ cho nút đăng xuất
                  side: BorderSide(color: colorScheme.error.withOpacity(0.2)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface, // Giữ màu trắng
        borderRadius: BorderRadius.circular(20),
        // Viền tinh tế
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1.5,
        ),
        // Bóng đổ để khối setting nổi lên hẳn so với nền xám
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    String? subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: theme.colorScheme.outline,
          ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 68, // Căn chỉnh thụt qua phần icon
      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
    );
  }
}
