import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'config/di.dart';
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
  late AuthBloc _authBloc;
  Key _appKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _authBloc = GetIt.instance<AuthBloc>();
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  void reassemble() {
    super.reassemble();

    // Hot reload does not rerun `main()` or top-level initializers, and it does
    // not rerun `initState()`. Many changes (DI wiring, init flows, routing)
    // won't show up until Hot Restart.
    //
    // In debug, we intentionally recreate the app subtree (and AuthBloc) on
    // every hot reload so changes show up immediately.
    if (!kDebugMode) return;

    debugPrint('###HOT_RELOAD### Rebuilding app subtree');

    configureDependencies();

    unawaited(_authBloc.close());
    _authBloc = GetIt.instance<AuthBloc>()..add(const AuthCheckRequested());

    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  void dispose() {
    unawaited(_authBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        key: _appKey,
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
