part of 'installed_apps_bloc.dart';

abstract class InstalledAppsEvent extends Equatable {
  const InstalledAppsEvent();

  @override
  List<Object> get props => [];
}

class LoadInstalledApps extends InstalledAppsEvent {}

class FilterInstalledApps extends InstalledAppsEvent {
  final String query;

  const FilterInstalledApps(this.query);

  @override
  List<Object> get props => [query];
}
