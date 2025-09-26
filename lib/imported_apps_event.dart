part of 'imported_apps_bloc.dart';

abstract class ImportedAppsEvent extends Equatable {
  const ImportedAppsEvent();

  @override
  List<Object> get props => [];
}

class ImportAppsFromJson extends ImportedAppsEvent {
  final List<AppInfo> apps;

  const ImportAppsFromJson(this.apps);

  @override
  List<Object> get props => [apps];
}

class FilterImportedApps extends ImportedAppsEvent {
  final String query;

  const FilterImportedApps(this.query);

  @override
  List<Object> get props => [query];
}

class SortImportedApps extends ImportedAppsEvent {
  final SortField field;

  const SortImportedApps(this.field);

  @override
  List<Object> get props => [field];
}

class DeleteImportedApp extends ImportedAppsEvent {
  final AppInfo app;
  const DeleteImportedApp(this.app);
  @override
  List<Object> get props => [app];
}
