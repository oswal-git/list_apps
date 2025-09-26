import 'package:device_apps/device_apps.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'installed_apps_event.dart';
part 'installed_apps_state.dart';

class InstalledAppsBloc extends Bloc<InstalledAppsEvent, InstalledAppsState> {
  InstalledAppsBloc() : super(InstalledAppsLoading()) {
    on<LoadInstalledApps>(_onLoadInstalledApps);
    on<FilterInstalledApps>(_onFilterInstalledApps);
  }

  Future<void> _onLoadInstalledApps(
    LoadInstalledApps event,
    Emitter<InstalledAppsState> emit,
  ) async {
    emit(InstalledAppsLoading());
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
      );
      apps.sort((a, b) => a.appName.compareTo(b.appName));
      emit(InstalledAppsLoaded(allApps: apps, filteredApps: apps));
    } catch (e) {
      emit(InstalledAppsError(e.toString()));
    }
  }

  void _onFilterInstalledApps(
    FilterInstalledApps event,
    Emitter<InstalledAppsState> emit,
  ) {
    final currentState = state;
    if (currentState is InstalledAppsLoaded) {
      final query = event.query.trim().toLowerCase();
      if (query.isEmpty) {
        emit(
          InstalledAppsLoaded(
            allApps: currentState.allApps,
            filteredApps: currentState.allApps,
          ),
        );
      } else {
        final filtered = currentState.allApps.where((app) {
          return app.appName.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query);
        }).toList();
        emit(
          InstalledAppsLoaded(
            allApps: currentState.allApps,
            filteredApps: filtered,
          ),
        );
      }
    }
  }
}
