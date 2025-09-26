import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:list_apps/imported_apps_bloc.dart';
import 'package:list_apps/installed_apps_bloc.dart';
import 'package:list_apps/models/app_info.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AppsCSVPage extends StatelessWidget {
  const AppsCSVPage({super.key});

  Future<void> _saveFilteredList(
    BuildContext context,
    List<AppInfo> filteredApps,
  ) async {
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final initialFilename = 'apps_filtradas_$timestamp.json';
    final textController = TextEditingController(text: initialFilename);

    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath == null) return;

    if (!context.mounted) return;

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
      String jsonStr = jsonEncode(filteredApps.map((e) => e.toJson()).toList());
      final path = '$selectedPath/$finalFilename';
      final file = File(path);
      await file.writeAsString(jsonStr);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lista guardada en $path')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installedPackages =
        (context.watch<InstalledAppsBloc>().state as InstalledAppsLoaded)
            .allApps
            .map((a) => a.packageName)
            .toList();

    return BlocBuilder<ImportedAppsBloc, ImportedAppsState>(
      builder: (context, state) {
        if (state is ImportedAppsInitial) {
          return const Center(child: Text('No hay datos importados.'));
        }
        if (state is ImportedAppsLoaded) {
          return Container(
            color: const Color(0xFFE3F2FD),
            child: Column(
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
                            context.read<ImportedAppsBloc>().add(
                              FilterImportedApps(value),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Guardar lista filtrada',
                        onPressed: state.filteredApps.isNotEmpty
                            ? () =>
                                  _saveFilteredList(context, state.filteredApps)
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
                          state.sortByNameAsc
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 18,
                        ),
                        label: const Text('Nombre'),
                        onPressed: () => context.read<ImportedAppsBloc>().add(
                          const SortImportedApps(SortField.name),
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          state.sortByPackageAsc
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 18,
                        ),
                        label: const Text('Paquete'),
                        onPressed: () => context.read<ImportedAppsBloc>().add(
                          const SortImportedApps(SortField.package),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.filteredApps.isEmpty
                      ? const Center(
                          child: Text('No se encontraron resultados.'),
                        )
                      : ListView.builder(
                          itemCount: state.filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = state.filteredApps[index];
                            final isInstalled = installedPackages.contains(
                              app.package,
                            );

                            return Container(
                              color: isInstalled
                                  ? const Color(0xFFC8E6C9)
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
                                  width: 96,
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
                                        onPressed: () => context
                                            .read<ImportedAppsBloc>()
                                            .add(DeleteImportedApp(app)),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: isInstalled
                                    ? () => DeviceApps.openApp(app.package)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
