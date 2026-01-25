
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/import_system/import_screen.dart';
import 'package:myapp/notifications_provider.dart';
import 'package:myapp/notifications_screen.dart';
import 'package:myapp/reports_provider.dart';
import 'package:myapp/reports_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './employee_provider.dart';
import './add_employee_screen.dart';
import './employee_details_screen.dart';
import './about_screen.dart';
import './employee_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
        ChangeNotifierProxyProvider<EmployeeProvider, NotificationsProvider>(
          create: (context) => NotificationsProvider(context.read<EmployeeProvider>()),
          update: (context, employeeProvider, previous) =>
              NotificationsProvider(employeeProvider),
        ),
        ChangeNotifierProxyProvider2<EmployeeProvider, NotificationsProvider,
            ReportsProvider>(
          create: (context) => ReportsProvider(
            context.read<EmployeeProvider>(),
            context.read<NotificationsProvider>(),
          ),
          update: (context, employeeProvider, notificationsProvider, previous) =>
              ReportsProvider(employeeProvider, notificationsProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.teal;

    final TextTheme appTextTheme = TextTheme(
      displayLarge:
          GoogleFonts.cairo(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.cairo(fontSize: 14),
      bodySmall: GoogleFonts.cairo(fontSize: 12),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle:
            GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle:
            GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'إدارة شؤون الموظفين',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', ''), // Arabic, no country code
          ],
          locale: const Locale('ar', ''),
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
          routes: {
            '/reports': (context) => const ReportsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSearching = false;
  String _searchQuery = '';

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text(
              'هل أنت متأكد من رغبتك في حذف جميع بيانات الموظفين؟ هذا الإجراء لا يمكن التراجع عنه.'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<EmployeeProvider>(context, listen: false)
                    .clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف جميع البيانات بنجاح.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
            });
          },
        ),
        title: TextField(
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث عن موظف...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18.0),
        ),
      );
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.add),
        tooltip: 'إضافة موظف',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
          );
        },
      ),
      title: const Text('الموظفين'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'التقارير',
          onPressed: () {
            Navigator.pushNamed(context, '/reports');
          },
        ),
        Consumer<NotificationsProvider>(
          builder: (context, provider, child) {
            final bool hasNotifications = provider.dueRaises.isNotEmpty ||
                provider.upcomingRaises.isNotEmpty ||
                provider.duePromotions.isNotEmpty ||
                provider.upcomingPromotions.isNotEmpty;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  tooltip: 'التنبيهات',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                if (hasNotifications)
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'reports':
                Navigator.pushNamed(context, '/reports');
                break;
              case 'import':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImportScreen()),
                );
                break;
              case 'about':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
                break;
              case 'toggle_theme':
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                break;
              case 'delete_database':
                _showDeleteConfirmationDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
             const PopupMenuItem<String>(
              value: 'reports',
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('التقارير'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('استيراد بيانات'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('حول التطبيق'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'toggle_theme',
              child: ListTile(
                leading: Icon(Icons.brightness_6),
                title: Text('تبديل السمة'),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete_database',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('حذف قاعدة البيانات',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<EmployeeProvider>(
            builder: (context, provider, child) {
              final List<Employee> employees = _isSearching
                  ? provider.employees
                      .where((emp) => emp.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList()
                  : provider.employees;

              if (employees.isEmpty) {
                return Center(
                  child: Text(_isSearching
                      ? 'لا توجد نتائج بحث'
                      : 'لا يوجد موظفين حاليًا. اضغط على "+" لإضافة موظف جديد.'),
                );
              }

              if (constraints.maxWidth > 600) {
                return _buildGridView(employees);
              } else {
                return _buildListView(employees);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Employee> employees) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 4.0,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(employee.name.isNotEmpty ? employee.name[0] : ''),
            ),
            title: Text(employee.name),
            subtitle: Text(employee.grade.title),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmployeeDetailsScreen(employee: employee),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Employee> employees) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          elevation: 4.0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmployeeDetailsScreen(employee: employee),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                        employee.name.isNotEmpty ? employee.name[0] : '',
                        style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 10),
                  Text(employee.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  Text(employee.grade.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
