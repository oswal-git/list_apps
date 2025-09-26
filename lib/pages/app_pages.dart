import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_apps/device_apps.dart';
// import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:list_apps/imported_apps_bloc.dart';
import 'package:list_apps/installed_apps_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../models/app_info.dart';
import '../widgets/apps_installed_page.dart';
import '../widgets/apps_csv_page.dart';

class AppPages extends StatefulWidget {
  const AppPages({super.key});

  @override
  State<AppPages> createState() => _AppPagesState();
}

class _AppPagesState extends State<AppPages> {
  final PageController _pageController = PageController();

  // Future<void> _exportToCSV() async {
  //   var status = await Permission.manageExternalStorage.status;
  //   if (!status.isGranted) {
  //     status = await Permission.manageExternalStorage.request();
  //     if (!status.isGranted) {
  //       if (mounted && context.mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Debes conceder permiso de almacenamiento para exportar el archivo.')));
  //       }
  //       return;
  //     }
  //   }

  //   String? selectedPath = await FilePicker.platform.getDirectoryPath();
  //   if (selectedPath == null) return;

  //   List<List<String>> rows = [
  //     ['Nombre', 'Paquete', 'Versión', 'Instalada en', 'Actualizada en'],
  //   ];
  //   for (var app in _apps) {
  //     if (app is ApplicationWithIcon) {
  //       rows.add([app.appName, app.packageName, app.versionName ?? '', app.installTimeMillis.toString(), app.updateTimeMillis.toString()]);
  //     }
  //   }
  //   String csv = const ListToCsvConverter().convert(rows);
  //   final path = '$selectedPath/apps_instaladas.csv';
  //   final file = File(path);
  //   await file.writeAsString(csv);
  //   if (mounted && context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportado a $path')));
  //   }
  // }

  // Future<void> _importFromCSV() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
  //   if (result == null) return;
  //   final file = File(result.files.single.path!);
  //   final content = await file.readAsString();
  //   List<List<dynamic>> rows = const CsvToListConverter().convert(content);

  //   List<AppInfo> apps = [];
  //   for (int i = 1; i < rows.length; i++) {
  //     final row = rows[i];
  //     if (row.length >= 5) {
  //       apps.add(AppInfo(row[0].toString(), row[1].toString(), row[2].toString(), row[3].toString(), row[4].toString()));
  //     }
  //   }
  //   setState(() {
  //     _csvApps = apps;
  //   });
  //   if (_csvApps.isNotEmpty) {
  //     _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.ease);
  //   }
  // }

  Future<void> _exportToJSON() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Debes conceder permiso de almacenamiento para exportar el archivo.',
              ),
            ),
          );
        }
        return;
      }
    }

    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath == null) return;

    if (!mounted || !context.mounted) return;
    final currentState = context.read<InstalledAppsBloc>().state;
    if (currentState is InstalledAppsLoaded) {
      List<AppInfo> appsInfo = [];
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .split('.')
          .first;
      final formattedTimestamp =
          '${timestamp.substring(0, 8)}_${timestamp.substring(9, 13)}';
      for (var app in currentState.allApps) {
        String? iconBase64;
        if (app is ApplicationWithIcon) {
          iconBase64 = base64Encode(app.icon);
        }
        appsInfo.add(
          AppInfo(
            app.appName,
            app.packageName,
            app.versionName ?? '',
            app.installTimeMillis.toString(),
            app.updateTimeMillis.toString(),
            iconBase64,
          ),
        );
      }
      String jsonStr = jsonEncode(appsInfo.map((e) => e.toJson()).toList());
      final path = '$selectedPath/apps_instaladas_$formattedTimestamp.json';
      final file = File(path);
      await file.writeAsString(jsonStr);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exportado a $path')));
      }
    }
  }

  Future<void> _importFromJSON() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    List<dynamic> jsonList = jsonDecode(content);

    List<AppInfo> apps = jsonList.map((e) => AppInfo.fromJson(e)).toList();
    if (apps.isNotEmpty) {
      if (!mounted) return;
      context.read<ImportedAppsBloc>().add(ImportAppsFromJson(apps));
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Apps'),
        actions: [
          // IconButton(icon: const Icon(Icons.download_rounded), onPressed: _exportToCSV),
          // IconButton(icon: const Icon(Icons.upload_file), onPressed: _importFromCSV),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToJSON,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importFromJSON,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [const AppsInstalledPage(), const AppsCSVPage()],
      ),
    );
  }
}
