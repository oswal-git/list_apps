part of 'installed_apps_bloc.dart';

abstract class InstalledAppsState extends Equatable {
  const InstalledAppsState();

  @override
  List<Object> get props => [];
}

class InstalledAppsLoading extends InstalledAppsState {}

class InstalledAppsLoaded extends InstalledAppsState {
  final List<Application> allApps;
  final List<Application> filteredApps;

  const InstalledAppsLoaded({
    this.allApps = const [],
    this.filteredApps = const [],
  });

  @override
  List<Object> get props => [allApps, filteredApps];
}

class InstalledAppsError extends InstalledAppsState {
  final String message;
  const InstalledAppsError(this.message);
  @override
  List<Object> get props => [message];
}
