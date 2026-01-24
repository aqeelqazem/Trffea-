
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/employee_model.dart';
import 'package:myapp/penalty_model.dart';
import 'package:myapp/thanks_book_model.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:myapp/add_employee_screen.dart';
import 'package:myapp/employee_provider.dart';
import 'package:myapp/thanks_book_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with TickerProviderStateMixin {
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

  // --- Calculation Logic with Penalties ---

  int _calculateTotalPenaltyMonths(Employee emp) {
    // Sums up the delay months from all penalties that haven't been 'consumed' by a promotion yet.
    return emp.penalties
        .where((p) => !p.isConsumed)
        .fold(0, (sum, p) => sum + p.delayInMonths);
  }

  DateTime _calculateNextRaiseDate(Employee emp) {
    final baseRaiseDate = DateTime(
      emp.effectiveLastRaiseDate.year + 1,
      emp.effectiveLastRaiseDate.month,
      emp.effectiveLastRaiseDate.day,
    );

    final raiseYearStartDate = emp.effectiveLastRaiseDate;

    // Calculate deductions from thanks books
    final applicableBooks = emp.thanksBooks.where((book) {
      return !book.isApplied &&
          !book.bookDate.isBefore(raiseYearStartDate) &&
          book.bookDate.isBefore(baseRaiseDate);
    }).toList();
    final totalMonthsToDeduct =
        applicableBooks.fold<int>(0, (sum, book) => sum + book.monthsDeducted);

    // Get total delay months from penalties
    final totalPenaltyMonths = _calculateTotalPenaltyMonths(emp);

    // Apply deductions first, then add penalties
    var adjustedRaiseDate = baseRaiseDate;
    for (int i = 0; i < totalMonthsToDeduct; i++) {
      adjustedRaiseDate = DateTime(adjustedRaiseDate.year,
          adjustedRaiseDate.month - 1, adjustedRaiseDate.day);
    }
    for (int i = 0; i < totalPenaltyMonths; i++) {
      adjustedRaiseDate = DateTime(adjustedRaiseDate.year,
          adjustedRaiseDate.month + 1, adjustedRaiseDate.day);
    }

    return adjustedRaiseDate;
  }

  DateTime? _calculateNextPromotionDate(Employee emp) {
    if (emp.grade.raisesCount == null) return null; // Not promotable

    final basePromotionDate = DateTime(
      emp.lastPromotionDate.year + emp.grade.raisesCount!,
      emp.lastPromotionDate.month,
      emp.lastPromotionDate.day,
    );

    // Calculate total months deducted from ALL thanks books for promotion
    final totalThanksMonths =
        emp.thanksBooks.fold<int>(0, (sum, book) => sum + book.monthsDeducted);

    // Get total delay months from penalties
    final totalPenaltyMonths = _calculateTotalPenaltyMonths(emp);

    // Apply deductions first, then add penalties
    var adjustedPromotionDate = basePromotionDate;
    for (int i = 0; i < totalThanksMonths; i++) {
      adjustedPromotionDate = DateTime(adjustedPromotionDate.year,
          adjustedPromotionDate.month - 1, adjustedPromotionDate.day);
    }
     for (int i = 0; i < totalPenaltyMonths; i++) {
      adjustedPromotionDate = DateTime(adjustedPromotionDate.year,
          adjustedPromotionDate.month + 1, adjustedPromotionDate.day);
    }

    return adjustedPromotionDate;
  }

  // --- Dialogs ---

  void _showConfirmationDialog(BuildContext context,
      {required String title,
      required String content,
      required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('تأكيد'),
              onPressed: () {
                onConfirm();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddPenaltyDialog(BuildContext context, String employeeId) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final delayController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('إضافة عقوبة جديدة'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'موضوع العقوبة'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'الرجاء إدخال موضوع العقوبة'
                        : null,
                  ),
                  TextFormField(
                    controller: delayController,
                    decoration:
                        const InputDecoration(labelText: 'مدة تأخير العلاوة/الترفيع (بالأشهر)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال مدة التأخير';
                      }
                      if (int.tryParse(value) == null) {
                        return 'الرجاء إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                  const SizedBox(height: 20),
                  // Simple Date Picker imitation
                  Row(
                    children: [
                      const Text('تاريخ العقوبة:'),
                      const Spacer(),
                      Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null && pickedDate != selectedDate) {
                             // This part is tricky in a dialog. A stateful builder is better.
                             // For now, we just update the variable.
                             selectedDate = pickedDate;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.of(ctx).pop()),
            ElevatedButton(
              child: const Text('حفظ'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newPenalty = Penalty(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    delayInMonths: int.parse(delayController.text),
                    date: selectedDate,
                    notes: notesController.text,
                  );
                  Provider.of<EmployeeProvider>(context, listen: false)
                      .addPenalty(employeeId, newPenalty);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }


  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, child) {
        final currentEmployee = provider.employees.firstWhere(
            (e) => e.id == widget.employee.id,
            orElse: () => widget.employee);

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Text(currentEmployee.name),
                  centerTitle: true,
                  pinned: true,
                  floating: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AddEmployeeScreen(
                                  existingEmployee: currentEmployee))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showConfirmationDialog(
                        context,
                        title: 'تأكيد الحذف',
                        content: 'هل أنت متأكد من رغبتك في حذف هذا الموظف؟',
                        onConfirm: () {
                          provider.deleteEmployee(currentEmployee.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const <Widget>[
                      Tab(
                          text: 'العلاوة',
                          icon: Icon(Icons.add_circle_outline)),
                      Tab(text: 'الترفيع', icon: Icon(Icons.arrow_upward)),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildRaiseTab(context, currentEmployee),
                _buildPromotionTab(context, currentEmployee),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabWithInfo(
      {required BuildContext context,
      required Employee employee,
      required List<Widget> children}) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _buildBasicInfoCard(context, employee),
        ),
        SliverList(
          delegate: SliverChildListDelegate(children),
        ),
      ],
    );
  }

  Widget _buildRaiseTab(BuildContext context, Employee currentEmployee) {
    return _buildTabWithInfo(
      context: context,
      employee: currentEmployee,
      children: [
        _buildRaiseSection(context, currentEmployee),
        const SizedBox(height: 16),
        _buildThanksBooksCard(
            context,
            'كتب الشكر الجديدة',
            currentEmployee.thanksBooks.where((b) => !b.isApplied).toList(),
            currentEmployee.id,
            false),
        const SizedBox(height: 16),
        _buildPenaltiesCard(context, currentEmployee), // <-- Moved to the bottom
      ],
    );
  }

  Widget _buildPromotionTab(BuildContext context, Employee currentEmployee) {
    return _buildTabWithInfo(
      context: context,
      employee: currentEmployee,
      children: [
        _buildPromotionSection(context, currentEmployee),
        const SizedBox(height: 16),
        _buildThanksBooksCard(
            context,
            'أرشيف كتب الشكر',
            currentEmployee.thanksBooks.where((b) => b.isApplied).toList(),
            currentEmployee.id,
            true),
      ],
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, Employee currentEmployee) {
    final currencyFormat = NumberFormat.decimalPattern('ar');
    bool inTasKeen = false;
    if (currentEmployee.grade.raisesCount != null) {
      if (currentEmployee.raisesReceived >=
          currentEmployee.grade.raisesCount!) {
        inTasKeen = true;
      }
    }
    final raisesColor = inTasKeen ? Colors.red : null;

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(context,
                icon: Icons.badge,
                title: 'العنوان الوظيفي',
                value: currentEmployee.jobTitle),
            _buildDetailRow(context,
                icon: Icons.school,
                title: 'التحصيل الدراسي',
                value: currentEmployee.education),
            _buildDetailRow(context,
                icon: Icons.work,
                title: 'الدرجة الوظيفية',
                value: currentEmployee.grade.title),
            _buildDetailRow(context,
                icon: Icons.star,
                title: 'تاريخ آخر ترفيع',
                value: DateFormat('yyyy-MM-dd')
                    .format(currentEmployee.lastPromotionDate)),
            _buildDetailRow(context,
                icon: Icons.event_available,
                title: 'تاريخ آخر علاوة فعلي',
                value: DateFormat('yyyy-MM-dd')
                    .format(currentEmployee.effectiveLastRaiseDate)),
            _buildDetailRow(context,
                icon: Icons.format_list_numbered,
                title: 'عدد العلاوات المستلمة',
                value: '${currentEmployee.raisesReceived}',
                valueColor: raisesColor),
            const Divider(height: 20),
            _buildDetailRow(context,
                icon: Icons.account_balance_wallet,
                title: 'الراتب الإجمالي الحالي',
                value: '${currencyFormat.format(currentEmployee.currentSalary)} دينار',
                isHeader: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRaiseSection(BuildContext context, Employee currentEmployee) {
    final nextRaiseDate = _calculateNextRaiseDate(currentEmployee);
    final isRaiseDue = !DateTime.now().isBefore(nextRaiseDate);
    final provider = Provider.of<EmployeeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildInfoCard(context,
          title: 'استحقاق العلاوة السنوية',
          children: [
            _buildDetailRow(context,
                icon: Icons.event,
                title: 'موعد العلاوة القادمة',
                value: DateFormat('yyyy-MM-dd').format(nextRaiseDate)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle),
                label: const Text('منح العلاوة'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: isRaiseDue ? Colors.green : null),
                onPressed: !isRaiseDue
                    ? null
                    : () => _showConfirmationDialog(
                          context,
                          title: 'تأكيد منح العلاوة',
                          content:
                              'هل أنت متأكد من منح علاوة سنوية للموظف بتاريخ ${DateFormat('yyyy-MM-dd').format(nextRaiseDate)}؟',
                          onConfirm: () =>
                              provider.grantRaise(currentEmployee.id, nextRaiseDate),
                        ),
              ),
            ),
          ]),
    );
  }

  Widget _buildPromotionSection(
      BuildContext context, Employee currentEmployee) {
    final nextPromotionDate = _calculateNextPromotionDate(currentEmployee);
    final isEligibleForPromotion = currentEmployee.grade.raisesCount != null &&
        currentEmployee.raisesReceived >= currentEmployee.grade.raisesCount!;
    final provider = Provider.of<EmployeeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: nextPromotionDate != null
          ? _buildInfoCard(context,
              title: 'استحقاق الترفيع',
              children: [
                  _buildDetailRow(context,
                      icon: Icons.auto_awesome,
                      title: 'موعد الترفيع المستحق',
                      value:
                          DateFormat('yyyy-MM-dd').format(nextPromotionDate),
                      valueColor: isEligibleForPromotion ? Colors.green : null),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('ترفيع الموظف'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isEligibleForPromotion ? Colors.green : null),
                      onPressed: !isEligibleForPromotion
                          ? null
                          : () => _showConfirmationDialog(
                                context,
                                title: 'تأكيد الترفيع',
                                content:
                                    'سيتم ترفيع الموظف للدرجة التالية بتاريخ ${DateFormat('yyyy-MM-dd').format(nextPromotionDate)}. هل أنت متأكد؟',
                                onConfirm: () => provider.promoteEmployee(
                                    currentEmployee.id, nextPromotionDate),
                              ),
                    ),
                  ),
                ])
          : const Center(
              child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("هذا الموظف في أعلى درجة وظيفية.",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            )),
    );
  }

  // --- New Penalty Card Widget ---
  Widget _buildPenaltiesCard(BuildContext context, Employee employee) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildInfoCard(
        context,
        title: 'العقوبات',
        children: [
           Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.red, size: 30),
                onPressed: () => _showAddPenaltyDialog(context, employee.id),
                tooltip: 'إضافة عقوبة جديدة',
              ),
            ),
          if (employee.penalties.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('لا توجد عقوبات مسجلة.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employee.penalties.length,
              itemBuilder: (context, index) {
                final penalty = employee.penalties[index];
                return ListTile(
                  leading: Icon(
                    penalty.isConsumed ? Icons.history_toggle_off : Icons.warning_amber_rounded,
                    color: penalty.isConsumed ? Colors.grey : Colors.orange,
                  ),
                  title: Text(penalty.title),
                  subtitle: Text(
                      'التاريخ: ${DateFormat('yMd').format(penalty.date)} - تؤخر ${penalty.delayInMonths} أشهر'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showConfirmationDialog(
                      context,
                      title: 'تأكيد الحذف',
                      content: 'هل أنت متأكد من حذف عقوبة "${penalty.title}"؟',
                      onConfirm: () =>
                          Provider.of<EmployeeProvider>(context, listen: false)
                              .deletePenalty(employee.id, penalty.id),
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildThanksBooksCard(BuildContext context, String title,
      List<ThanksBook> books, String employeeId, bool isArchived) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildInfoCard(
        context,
        title: title,
        children: [
          if (!isArchived)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon:
                    const Icon(Icons.add_circle, color: Colors.green, size: 30),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ThanksBookScreen(employeeId: employeeId))),
                tooltip: 'إضافة كتاب شكر جديد',
              ),
            ),
          if (books.isEmpty)
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                    child: Text(isArchived
                        ? 'لا توجد كتب شكر مؤرشفة.'
                        : 'لا توجد كتب شكر جديدة.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: book.isApplied
                      ? const Icon(Icons.archive, color: Colors.orange)
                      : const Icon(Icons.new_releases, color: Colors.blue),
                  title: Text('رقم الكتاب: ${book.bookNumber}'),
                   subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(book.bookDate)} - يختزل: ${book.monthsDeducted} شهر'),
                      if (book.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('ملاحظات: ${book.notes}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                    ],
                  ),
                  trailing: isArchived
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: Icon(Icons.edit,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ThanksBookScreen(
                                            employeeId: employeeId,
                                            existingBook: book)))),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _showConfirmationDialog(
                                    context,
                                    title: 'تأكيد الحذف',
                                    content:
                                        'هل أنت متأكد من حذف كتاب الشكر رقم ${book.bookNumber}؟',
                                    onConfirm: () =>
                                        Provider.of<EmployeeProvider>(context,
                                                listen: false)
                                            .deleteThanksBook(
                                                employeeId, book.id))),
                          ],
                        ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            ...children
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      bool isHeader = false,
      Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Theme.of(context).colorScheme.secondary, size: 20),
          const SizedBox(width: 16),
          Expanded(
              child: Text('$title: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal))),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isHeader ? FontWeight.bold : FontWeight.normal,
                      color: valueColor ??
                          (isHeader
                              ? Theme.of(context).colorScheme.primary
                              : null)))),
        ],
      ),
    );
  }
}
