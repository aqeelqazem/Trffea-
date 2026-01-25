
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/employee_details_screen.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/employee_provider.dart';
import 'package:myapp/notifications_provider.dart';
import 'package:myapp/report_generator.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, child) {
        final int raisesCount =
            provider.dueRaises.length + provider.upcomingRaises.length;
        final int promotionsCount =
            provider.duePromotions.length + provider.upcomingPromotions.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('التنبيهات'),
            centerTitle: true,
            actions: [
              // This is the new Export button
              PopupMenuButton<String>(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'تصدير التقارير',
                onSelected: (value) {
                  final allEmployeesForRaise =
                      provider.dueRaises + provider.upcomingRaises;
                  final allEmployeesForPromotion =
                      provider.duePromotions + provider.upcomingPromotions;
                  final allGrades = context.read<EmployeeProvider>().grades;

                  if (value == 'export_raises') {
                    if (allEmployeesForRaise.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('لا يوجد موظفين لتصديرهم في تقرير العلاوات.')),
                      );
                    } else {
                      ReportGenerator.generateRaiseReport(
                          context, allEmployeesForRaise);
                    }
                  } else if (value == 'export_promotions') {
                    if (allEmployeesForPromotion.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'لا يوجد موظفين لتصديرهم في تقرير الترفيعات.')),
                      );
                    } else {
                      ReportGenerator.generatePromotionReport(
                          context, allEmployeesForPromotion, allGrades);
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'export_raises',
                    child: ListTile(
                      leading: Icon(Icons.card_giftcard),
                      title: Text('تصدير تقرير العلاوات'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'export_promotions',
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('تصدير تقرير الترفيعات'),
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab('العلاوات', Icons.card_giftcard, raisesCount),
                _buildTab('الترفيعات', Icons.star, promotionsCount),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationsList(
                context,
                provider,
                dueList: provider.dueRaises,
                upcomingList: provider.upcomingRaises,
                type: 'raise',
              ),
              _buildNotificationsList(
                context,
                provider,
                dueList: provider.duePromotions,
                upcomingList: provider.upcomingPromotions,
                type: 'promotion',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, IconData icon, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 4),
          Flexible(
            child: Text(title, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4.0),
              child: Chip(
                label: Text(
                  count.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.all(2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context,
      NotificationsProvider provider,
      {required List<Employee> dueList,
      required List<Employee> upcomingList,
      required String type}) {
    if (dueList.isEmpty && upcomingList.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد تنبيهات حاليًا.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (dueList.isNotEmpty)
          ..._buildSection(context, provider, 'مستحقة ومتأخرة', dueList, type, true),
        if (upcomingList.isNotEmpty)
          ..._buildSection(
              context, provider, 'مستحقة لهذا الشهر', upcomingList, type, false),
      ],
    );
  }

  List<Widget> _buildSection(BuildContext context, NotificationsProvider provider,
      String title, List<Employee> employees, String type, bool isDue) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      ),
      ...employees.map((employee) {
        final date = type == 'raise'
            ? provider.calculateNextRaiseDate(employee)
            : provider.calculateNextPromotionDate(employee);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
          elevation: 3.0,
          color: isDue ? Theme.of(context).colorScheme.error.withAlpha(25) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDue
                  ? Theme.of(context).colorScheme.errorContainer
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isDue ? Colors.red.shade100 : Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                type == 'raise' ? Icons.card_giftcard : Icons.star,
                color: isDue
                    ? Colors.red.shade700
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تاريخ الاستحقاق: ${DateFormat('yyyy-MM-dd').format(date!)}'),
                if (isDue)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      provider.calculateDifference(date),
                      style: TextStyle(
                          color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailsScreen(employee: employee),
                ),
              );
            },
          ),
        );
      })
    ];
  }
}
