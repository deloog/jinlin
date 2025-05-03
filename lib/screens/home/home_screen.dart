import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jinlin_app/screens/home/home_bloc.dart';
import 'package:jinlin_app/services/holiday/holiday_repository.dart';
import 'package:jinlin_app/services/reminder/reminder_repository.dart';
import 'package:jinlin_app/services/logging/logging_service.dart';
import 'package:jinlin_app/widgets/empty_state_widget.dart';
import 'package:jinlin_app/widgets/timeline_list.dart';
import 'package:jinlin_app/routes/app_router.dart';

/// 主屏幕
///
/// 显示时间线和提醒事项
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeBloc(
        holidayRepository: Provider.of<HolidayRepository>(context, listen: false),
        reminderRepository: Provider.of<ReminderRepository>(context, listen: false),
        logger: Provider.of<LoggingService>(context, listen: false),
      ),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  @override
  void initState() {
    super.initState();

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = Provider.of<HomeBloc>(context, listen: false);
      bloc.loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<HomeBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CetaMind Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => bloc.showHolidayFilter(context),
            tooltip: '筛选节日',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: bloc.isSyncing ? null : () => bloc.syncData(),
            tooltip: '同步数据',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppRouter.navigateToSettings(),
            tooltip: '设置',
          ),
        ],
      ),
      body: _buildBody(bloc),
      floatingActionButton: FloatingActionButton(
        onPressed: () => bloc.navigateToAddReminder(context),
        tooltip: '添加提醒',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(HomeBloc bloc) {
    if (bloc.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载数据...'),
          ],
        ),
      );
    }

    if (bloc.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '加载数据失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              bloc.errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => bloc.loadData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (bloc.timelineItems.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.event_busy,
        title: '没有提醒事项',
        message: '点击右下角的加号按钮添加提醒事项',
      );
    }

    return RefreshIndicator(
      onRefresh: () => bloc.loadData(),
      child: TimelineList(
        items: bloc.timelineItems,
        onItemTap: (item) => bloc.onTimelineItemTap(context, item),
      ),
    );
  }
}
