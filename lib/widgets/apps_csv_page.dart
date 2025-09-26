import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:list_apps/models/app_info.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AppsCSVPage extends StatefulWidget {
  final List<AppInfo> apps;
  final List<String>? installedPackages;

  const AppsCSVPage({super.key, required this.apps, this.installedPackages});

  @override
  State<AppsCSVPage> createState() => _AppsCSVPageState();
}

class _AppsCSVPageState extends State<AppsCSVPage> {
  late List<AppInfo> _sortedApps;
  late List<AppInfo> _filteredApps;
  bool _sortByNameAsc = true;
  bool _sortByPackageAsc = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _sortedApps = List.from(widget.apps);
    _filteredApps = List.from(_sortedApps);
  }

  void _sortByName() {
    setState(() {
      _sortedApps.sort(
        (a, b) => _sortByNameAsc
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name),
      );
      _sortByNameAsc = !_sortByNameAsc;
      _applyFilter();
    });
  }

  void _sortByPackage() {
    setState(() {
      _sortedApps.sort(
        (a, b) => _sortByPackageAsc
            ? a.package.compareTo(b.package)
            : b.package.compareTo(a.package),
      );
      _sortByPackageAsc = !_sortByPackageAsc;
    });
  }

  void _applyFilter() {
    setState(() {
      if (_search.trim().isEmpty) {
        _filteredApps = List.from(_sortedApps);
      } else {
        final query = _search.trim().toLowerCase();
        _filteredApps = _sortedApps
            .where(
              (app) =>
                  app.name.toLowerCase().contains(query) ||
                  app.package.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _deleteApp(int index) {
    setState(() {
      final appToRemove = _filteredApps[index];
      _sortedApps.remove(appToRemove);
      _filteredApps.removeAt(index);
    });
  }

  Future<void> _saveFilteredList() async {
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final initialFilename = 'apps_filtradas_$timestamp.json';
    final textController = TextEditingController(text: initialFilename);

    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath == null) return;

    if (!mounted) return;

    final finalFilename = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar como...'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nombre del archivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(textController.text);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (finalFilename != null && finalFilename.isNotEmpty) {
      String jsonStr = jsonEncode(
        _filteredApps.map((e) => e.toJson()).toList(),
      );
      final path = '$selectedPath/$finalFilename';
      final file = File(path);
      await file.writeAsString(jsonStr);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lista guardada en $path')));
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppsCSVPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apps != oldWidget.apps) {
      setState(() {
        _sortedApps = List.from(widget.apps)
          ..sort((a, b) => a.name.compareTo(b.name));
        _filteredApps = List.from(_sortedApps);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = widget.installedPackages ?? [];

    return Stack(
      children: [
        Container(
          color: const Color(0xFFE3F2FD),
          child: _filteredApps.isEmpty && _search.isEmpty
              ? const Center(child: Text('No hay datos importados.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Buscar por nombre o paquete...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                _search = value;
                                _applyFilter();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: 'Guardar lista filtrada',
                            onPressed: _filteredApps.isNotEmpty
                                ? _saveFilteredList
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: Icon(
                              _sortByNameAsc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 18,
                            ),
                            label: const Text('Nombre'),
                            onPressed: _sortByName,
                          ),
                          TextButton.icon(
                            icon: Icon(
                              _sortByPackageAsc
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 18,
                            ),
                            label: const Text('Paquete'),
                            onPressed: _sortByPackage,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredApps.isEmpty
                          ? const Center(
                              child: Text('No se encontraron resultados.'),
                            )
                          : ListView.builder(
                              itemCount: _filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final isInstalled = installed.contains(
                                  app.package,
                                );

                                return Container(
                                  color: isInstalled
                                      ? const Color(
                                          0xFFC8E6C9,
                                        ) // Verde suave si instalada
                                      : Colors.transparent,
                                  child: ListTile(
                                    leading:
                                        (app.iconBase64 != null &&
                                            app.iconBase64!.isNotEmpty)
                                        ? Image.memory(
                                            base64Decode(app.iconBase64!),
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.apps,
                                                      color: Colors.blueAccent,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.apps,
                                            color: Colors.blue,
                                          ),
                                    title: Text(app.name),
                                    subtitle: Text(
                                      'Paquete: ${app.package}\nVersión: ${app.version}\nInstalada: ${app.installed}\nActualizada: ${app.updated}',
                                    ),
                                    isThreeLine: true,
                                    trailing: SizedBox(
                                      width: 96, // Ancho para dos IconButtons
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new),
                                            tooltip: 'Abrir en Play Store',
                                            onPressed: () async {
                                              final url =
                                                  'https://play.google.com/store/apps/details?id=${app.package}';
                                              if (await canLaunchUrl(
                                                Uri.parse(url),
                                              )) {
                                                await launchUrl(
                                                  Uri.parse(url),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Eliminar de la lista',
                                            onPressed: () => _deleteApp(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: isInstalled
                                        ? () {
                                            DeviceApps.openApp(app.package);
                                          }
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
