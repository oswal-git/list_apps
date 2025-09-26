import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:list_apps/models/app_info.dart';

part 'imported_apps_event.dart';
part 'imported_apps_state.dart';

class ImportedAppsBloc extends Bloc<ImportedAppsEvent, ImportedAppsState> {
  ImportedAppsBloc() : super(ImportedAppsInitial()) {
    on<ImportAppsFromJson>(_onImportAppsFromJson);
    on<FilterImportedApps>(_onFilterImportedApps);
    on<SortImportedApps>(_onSortImportedApps);
    on<DeleteImportedApp>(_onDeleteImportedApp);
  }

  void _onImportAppsFromJson(
    ImportAppsFromJson event,
    Emitter<ImportedAppsState> emit,
  ) {
    final sorted = List<AppInfo>.from(event.apps)
      ..sort((a, b) => a.name.compareTo(b.name));
    emit(ImportedAppsLoaded(originalApps: sorted, filteredApps: sorted));
  }

  void _onFilterImportedApps(
    FilterImportedApps event,
    Emitter<ImportedAppsState> emit,
  ) {
    final currentState = state;
    if (currentState is ImportedAppsLoaded) {
      final query = event.query.trim().toLowerCase();
      final filtered = currentState.originalApps.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.package.toLowerCase().contains(query);
      }).toList();
      emit(
        currentState.copyWith(filteredApps: filtered, searchQuery: event.query),
      );
    }
  }

  void _onSortImportedApps(
    SortImportedApps event,
    Emitter<ImportedAppsState> emit,
  ) {
    final currentState = state;
    if (currentState is ImportedAppsLoaded) {
      final sorted = List<AppInfo>.from(currentState.originalApps);
      bool newSortByNameAsc = currentState.sortByNameAsc;
      bool newSortByPackageAsc = currentState.sortByPackageAsc;

      if (event.field == SortField.name) {
        sorted.sort(
          (a, b) => currentState.sortByNameAsc
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        newSortByNameAsc = !currentState.sortByNameAsc;
      } else if (event.field == SortField.package) {
        sorted.sort(
          (a, b) => currentState.sortByPackageAsc
              ? a.package.compareTo(b.package)
              : b.package.compareTo(a.package),
        );
        newSortByPackageAsc = !currentState.sortByPackageAsc;
      }

      // Re-apply filter after sorting
      final query = currentState.searchQuery.trim().toLowerCase();
      final filtered = sorted.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.package.toLowerCase().contains(query);
      }).toList();

      emit(
        currentState.copyWith(
          originalApps: sorted,
          filteredApps: filtered,
          sortByNameAsc: newSortByNameAsc,
          sortByPackageAsc: newSortByPackageAsc,
        ),
      );
    }
  }

  void _onDeleteImportedApp(
    DeleteImportedApp event,
    Emitter<ImportedAppsState> emit,
  ) {
    final currentState = state;
    if (currentState is ImportedAppsLoaded) {
      final newOriginal = List<AppInfo>.from(currentState.originalApps)
        ..remove(event.app);
      final newFiltered = List<AppInfo>.from(currentState.filteredApps)
        ..remove(event.app);

      emit(
        currentState.copyWith(
          originalApps: newOriginal,
          filteredApps: newFiltered,
        ),
      );
    }
  }
}
