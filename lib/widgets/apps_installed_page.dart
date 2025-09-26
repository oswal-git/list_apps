import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_apps/device_apps.dart';
import 'package:list_apps/installed_apps_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class AppsInstalledPage extends StatelessWidget {
  const AppsInstalledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InstalledAppsBloc, InstalledAppsState>(
      builder: (context, state) {
        if (state is InstalledAppsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InstalledAppsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        if (state is InstalledAppsLoaded) {
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
                    context.read<InstalledAppsBloc>().add(
                      FilterInstalledApps(value),
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<InstalledAppsBloc>().add(LoadInstalledApps());
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = state.filteredApps[index];
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
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo abrir Play Store',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (!context.mounted) return;
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
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No se pudo abrir ${app.appName}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al abrir la app'),
                              ),
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
        return const Center(child: Text('Inicia la carga de aplicaciones.'));
      },
    );
  }
}
