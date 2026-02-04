
import 'package:flutter/material.dart';
import 'package:myapp/employee_model.dart';

class GradeEmployeesScreen extends StatelessWidget {
  final String gradeTitle;
  final List<Employee> employees;

  const GradeEmployeesScreen({super.key, required this.gradeTitle, required this.employees});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('موظفو الدرجة: $gradeTitle'),
      ),
      body: employees.isEmpty
          ? const Center(
              child: Text('لا يوجد موظفون في هذه الدرجة.'),
            )
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(employee.name.isNotEmpty ? employee.name[0] : '؟'),
                    ),
                    title: Text(employee.name),
                  ),
                );
              },
            ),
    );
  }
}
