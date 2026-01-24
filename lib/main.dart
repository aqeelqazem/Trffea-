
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './employee_provider.dart';
import './add_employee_screen.dart';
import './employee_details_screen.dart';
import './about_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeProvider()),
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
      displayLarge: GoogleFonts.cairo(fontSize: 57, fontWeight: FontWeight.bold),
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
        titleTextStyle: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
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
        titleTextStyle: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
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
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموظفين'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            tooltip: 'حول التطبيق',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'تبديل السمة',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<EmployeeProvider>(
            builder: (context, provider, child) {
              if (provider.employees.isEmpty) {
                return const Center(
                  child: Text('لا يوجد موظفين حاليًا. اضغط على "+" لإضافة موظف جديد.'),
                );
              }

              if (constraints.maxWidth > 600) {
                return _buildGridView(provider);
              } else {
                return _buildListView(provider);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
           );
        },
        tooltip: 'إضافة موظف',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {},
              tooltip: 'الرئيسية',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Search functionality to be added here
              },
              tooltip: 'بحث',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(EmployeeProvider provider) {
    return ListView.builder(
      itemCount: provider.employees.length,
      itemBuilder: (context, index) {
        final employee = provider.employees[index];
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
                   builder: (context) => EmployeeDetailsScreen(employee: employee),
                 ),
               );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(EmployeeProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.employees.length,
      itemBuilder: (context, index) {
        final employee = provider.employees[index];
        return Card(
          elevation: 4.0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailsScreen(employee: employee),
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
                    child: Text(employee.name.isNotEmpty ? employee.name[0] : '', style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 10),
                  Text(employee.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  Text(employee.grade.title, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
