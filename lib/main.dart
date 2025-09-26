import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:list_apps/blocs/imported_apps/imported_apps_bloc.dart';
import 'package:list_apps/blocs/installed_apps/installed_apps_bloc.dart';
import 'pages/app_pages.dart';

void main() => runApp(const AppBlocProvider());

class AppBlocProvider extends StatelessWidget {
  const AppBlocProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InstalledAppsBloc()..add(LoadInstalledApps()),
        ),
        BlocProvider(create: (context) => ImportedAppsBloc()),
      ],
      child: const MaterialApp(
        title: 'Lista de Apps',
        home: AppPages(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
