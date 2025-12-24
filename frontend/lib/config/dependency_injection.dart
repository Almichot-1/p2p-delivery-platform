import 'package:get_it/get_it.dart';

import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';

import '../features/profile/data/repositories/profile_repository.dart';
import '../features/profile/bloc/profile_bloc.dart';

import '../features/trips/data/repositories/trip_repository.dart';
import '../features/trips/bloc/trip_bloc.dart';

import '../features/requests/data/repositories/request_repository.dart';
import '../features/requests/bloc/request_bloc.dart';

import '../features/matches/data/repositories/match_repository.dart';
import '../features/matches/bloc/match_bloc.dart';

import '../features/chat/data/repositories/chat_repository.dart';
import '../features/chat/bloc/chat_bloc.dart';

import '../features/reviews/data/repositories/review_repository.dart';
import '../features/reviews/bloc/review_bloc.dart';

import '../features/notifications/data/repositories/notification_repository.dart';
import '../features/notifications/bloc/notification_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<FirebaseService>()),
  );

  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<FirebaseService>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<FirebaseService>()),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(getIt<FirebaseService>(), getIt<StorageService>()),
  );

  getIt.registerLazySingleton<TripRepository>(
    () => TripRepository(getIt<FirebaseService>()),
  );

  getIt.registerLazySingleton<RequestRepository>(
    () => RequestRepository(getIt<FirebaseService>(), getIt<StorageService>()),
  );

  getIt.registerLazySingleton<MatchRepository>(
    () => MatchRepository(getIt<FirebaseService>()),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(getIt<FirebaseService>(), getIt<StorageService>()),
  );

  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepository(getIt<FirebaseService>()),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<FirebaseService>()),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(getIt<ProfileRepository>()),
  );

  getIt.registerFactory<TripBloc>(
    () => TripBloc(getIt<TripRepository>()),
  );

  getIt.registerFactory<RequestBloc>(
    () => RequestBloc(getIt<RequestRepository>()),
  );

  getIt.registerFactory<MatchBloc>(
    () => MatchBloc(getIt<MatchRepository>()),
  );

  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(getIt<ChatRepository>()),
  );

  getIt.registerFactory<ReviewBloc>(
    () => ReviewBloc(getIt<ReviewRepository>()),
  );

  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(getIt<NotificationRepository>()),
  );
}
