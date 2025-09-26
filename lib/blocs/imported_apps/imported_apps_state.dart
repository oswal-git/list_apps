part of 'imported_apps_bloc.dart';

enum SortField { name, package }

abstract class ImportedAppsState extends Equatable {
  const ImportedAppsState();

  @override
  List<Object> get props => [];
}

class ImportedAppsInitial extends ImportedAppsState {}

class ImportedAppsLoaded extends ImportedAppsState {
  final List<AppInfo> originalApps;
  final List<AppInfo> filteredApps;
  final String searchQuery;
  final bool sortByNameAsc;
  final bool sortByPackageAsc;

  const ImportedAppsLoaded({
    this.originalApps = const [],
    this.filteredApps = const [],
    this.searchQuery = '',
    this.sortByNameAsc = true,
    this.sortByPackageAsc = true,
  });

  ImportedAppsLoaded copyWith({
    List<AppInfo>? originalApps,
    List<AppInfo>? filteredApps,
    String? searchQuery,
    bool? sortByNameAsc,
    bool? sortByPackageAsc,
  }) {
    return ImportedAppsLoaded(
      originalApps: originalApps ?? this.originalApps,
      filteredApps: filteredApps ?? this.filteredApps,
      searchQuery: searchQuery ?? this.searchQuery,
      sortByNameAsc: sortByNameAsc ?? this.sortByNameAsc,
      sortByPackageAsc: sortByPackageAsc ?? this.sortByPackageAsc,
    );
  }

  @override
  List<Object> get props => [
    originalApps,
    filteredApps,
    searchQuery,
    sortByNameAsc,
    sortByPackageAsc,
  ];
}
