import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'config/routes.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

class DiasporaApp extends StatefulWidget {
  const DiasporaApp({super.key});

  @override
  State<DiasporaApp> createState() => _DiasporaAppState();
}

class _DiasporaAppState extends State<DiasporaApp> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = GetIt.instance<AuthBloc>();
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRoutes.createRouter(_authBloc),
      ),
    );
  }
}
