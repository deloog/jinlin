import 'package:flutter/material.dart';
import 'package:jinlin_app/generated/l10n.dart';
import 'package:jinlin_app/providers/sync_provider.dart';
import 'package:jinlin_app/screens/settings/sync_management_screen.dart';
import 'package:jinlin_app/widgets/common/custom_app_bar.dart';
import 'package:jinlin_app/widgets/common/custom_card.dart';
import 'package:jinlin_app/widgets/common/section_title.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final syncProvider = SyncProvider.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: s.settings,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGeneralSettingsCard(context),
          const SizedBox(height: 16.0),
          _buildDataSettingsCard(context),
          const SizedBox(height: 16.0),
          _buildSyncSettingsCard(context, syncProvider),
          const SizedBox(height: 16.0),
          _buildAboutCard(context),
        ],
      ),
    );
  }
  
  /// 构建通用设置卡片
  Widget _buildGeneralSettingsCard(BuildContext context) {
    final s = S.of(context);
    
    return CustomCard(
      title: s.generalSettings,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.language),
            subtitle: Text(s.currentLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到语言设置页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(s.theme),
            subtitle: Text(s.currentTheme),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到主题设置页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(s.notifications),
            subtitle: Text(s.notificationSettings),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到通知设置页面
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建数据设置卡片
  Widget _buildDataSettingsCard(BuildContext context) {
    final s = S.of(context);
    
    return CustomCard(
      title: s.dataSettings,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(s.backupAndRestore),
            subtitle: Text(s.backupAndRestoreDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到备份和恢复页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(s.dataManagement),
            subtitle: Text(s.dataManagementDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到数据管理页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(s.importExport),
            subtitle: Text(s.importExportDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到导入导出页面
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建同步设置卡片
  Widget _buildSyncSettingsCard(BuildContext context, SyncProvider syncProvider) {
    final s = S.of(context);
    final theme = Theme.of(context);
    
    return CustomCard(
      title: s.syncSettings,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: Text(s.autoSync),
            subtitle: Text(s.autoSyncDescription),
            value: syncProvider.isAutoSyncEnabled,
            onChanged: (value) {
              if (value) {
                syncProvider.enableAutoSync();
              } else {
                syncProvider.disableAutoSync();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(s.syncManagement),
            subtitle: Text(s.syncManagementDescription),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (syncProvider.hasConflictOperations)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      syncProvider.conflictOperationsCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                const SizedBox(width: 8.0),
                const Icon(Icons.arrow_forward_ios, size: 16.0),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SyncManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync_problem),
            title: Text(s.syncStatus),
            subtitle: syncProvider.isSyncing
                ? Text(s.syncing)
                : syncProvider.lastSyncTime != null
                    ? Text(s.lastSyncTimeAgo)
                    : Text(s.neverSynced),
            trailing: syncProvider.isSyncing
                ? SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: () => syncProvider.startSync(),
                    tooltip: s.sync,
                  ),
          ),
        ],
      ),
    );
  }
  
  /// 构建关于卡片
  Widget _buildAboutCard(BuildContext context) {
    final s = S.of(context);
    
    return CustomCard(
      title: s.about,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(s.appInfo),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到应用信息页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(s.help),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到帮助页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(s.privacyPolicy),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到隐私政策页面
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(s.termsOfService),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // TODO: 导航到服务条款页面
            },
          ),
        ],
      ),
    );
  }
}
