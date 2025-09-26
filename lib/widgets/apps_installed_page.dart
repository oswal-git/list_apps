import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

class AppsInstalledPage extends StatefulWidget {
  final List<Application> apps;
  final bool loading;
  final Future<void> Function() onRefresh;

  const AppsInstalledPage({
    super.key,
    required this.apps,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<AppsInstalledPage> createState() => _AppsInstalledPageState();
}

class _AppsInstalledPageState extends State<AppsInstalledPage> {
  List<Application> _filteredApps = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      List<Application> filtered;
      if (_search.trim().isEmpty) {
        filtered = List.from(widget.apps);
      } else {
        final query = _search.trim().toLowerCase();
        filtered = widget.apps.where((app) {
          final name = app.appName.toLowerCase();
          final package = app.packageName.toLowerCase();
          return name.contains(query) || package.contains(query);
        }).toList();
      }
      filtered.sort((a, b) => a.appName.compareTo(b.appName));
      _filteredApps = filtered;
    });
  }

  @override
  void didUpdateWidget(covariant AppsInstalledPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apps != oldWidget.apps) {
      _applyFilter();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredApps.length,
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                return ListTile(
                  leading: app is ApplicationWithIcon
                      ? Image.memory(app.icon, width: 40)
                      : const Icon(Icons.apps, size: 40),
                  title: Text(app.appName),
                  subtitle: Text(
                    'Paquete: ${app.packageName}\n'
                    'Versión: ${app.versionName ?? 'Desconocida'}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Abrir en Play Store',
                    onPressed: () async {
                      final url =
                          'https://play.google.com/store/apps/details?id=${app.packageName}';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          if (!mounted || !context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir Play Store'),
                            ),
                          );
                        }
                      } else {
                        if (!mounted || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Play Store no disponible'),
                          ),
                        );
                      }
                    },
                  ),
                  onTap: () async {
                    try {
                      final launched = await DeviceApps.openApp(
                        app.packageName,
                      );
                      if (!launched) {
                        if (!mounted || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo abrir ${app.appName}'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al abrir la app')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
