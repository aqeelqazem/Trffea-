import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/grade_employees_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportsProvider>(context, listen: false).setMonthFilter(0);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصاءات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'العلاوات'),
            Tab(icon: Icon(Icons.star), text: 'الترفيعات'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildReportTab(provider, 'raise'),
              _buildReportTab(provider, 'promotion'),
              _buildStatsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportTab(ReportsProvider provider, String type) {
    final List<Employee> employees = type == 'raise'
        ? provider.raiseFilteredEmployees
        : provider.promotionFilteredEmployees;
    final int count = employees.length;
    final String title = type == 'raise' ? 'علاوة' : 'ترقية';
    final List<String> months = [
      'كل السنة',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              'عدد المستحقين ل$title: $count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButtonFormField<int>(
            initialValue: provider.selectedMonth,
            decoration: const InputDecoration(
              labelText: 'اختر الشهر',
              border: OutlineInputBorder(),
            ),
            items: List.generate(13, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(months[index]),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                provider.setMonthFilter(value);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: employees.isEmpty
              ? const Center(
                  child: Text('لا يوجد موظفون مستحقون في هذه الفترة.'),
                )
              : _buildEmployeesCardList(employees, type, provider),
        ),
      ],
    );
  }

  Widget _buildEmployeesCardList(
    List<Employee> employees,
    String type,
    ReportsProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        final date = type == 'raise'
            ? provider.calculateNextRaiseDate(employee)
            : provider.calculateNextPromotionDate(employee);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(type == 'raise' ? Icons.card_giftcard : Icons.star),
            ),
            title: Text(
              employee.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الدرجة: ${employee.grade.title}'),
                Text(
                  'تاريخ الاستحقاق: ${date != null ? DateFormat('yyyy-MM-dd').format(date) : 'غير محدد'}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(ReportsProvider provider) {
    final gradeDistribution = provider.gradeDistribution;
    if (gradeDistribution.isEmpty) {
      return const Center(child: Text('لا توجد بيانات لعرض الإحصائيات.'));
    }

    final sortedGrades = gradeDistribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedGrades.length,
      itemBuilder: (context, index) {
        final entry = sortedGrades[index];
        return InkWell(
          onTap: () {
            final employeesInGrade = provider.getEmployeesByGrade(entry.key);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradeEmployeesScreen(
                  gradeTitle: entry.key,
                  employees: employeesInGrade,
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'الدرجة: ${entry.key}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      'العدد: ${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
