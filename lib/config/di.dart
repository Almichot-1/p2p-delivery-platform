import 'package:get_it/get_it.dart';

import '../core/services/cloudinary_service.dart';
import '../core/services/firebase_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/chat/bloc/chat_bloc.dart';
import '../features/chat/data/repositories/chat_repository.dart';
import '../features/matches/bloc/match_bloc.dart';
import '../features/matches/data/repositories/match_repository.dart';
import '../features/notifications/bloc/notification_bloc.dart';
import '../features/notifications/data/repositories/notification_repository.dart';
import '../features/requests/bloc/request_bloc.dart';
import '../features/requests/data/repositories/request_repository.dart';
import '../features/trips/bloc/trip_bloc.dart';
import '../features/trips/data/repositories/trip_repository.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  // Core services
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService.instance);
  getIt.registerLazySingleton<CloudinaryService>(
      () => CloudinaryService.instance);

  // Auth
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(firebaseService: getIt<FirebaseService>()),
  );
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  // Profile
  getIt.registerLazySingleton<ProfileRepository>(
    () =>
        ProfileRepository(getIt<FirebaseService>(), getIt<CloudinaryService>()),
  );
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(profileRepository: getIt<ProfileRepository>()),
  );

  // Trips
  getIt.registerLazySingleton<TripRepository>(
    () => TripRepository(getIt<FirebaseService>()),
  );
  getIt.registerFactory<TripBloc>(
    () => TripBloc(tripRepository: getIt<TripRepository>()),
  );

  // Requests
  getIt.registerLazySingleton<RequestRepository>(
    () =>
        RequestRepository(getIt<FirebaseService>(), getIt<CloudinaryService>()),
  );
  getIt.registerFactory<RequestBloc>(
    () => RequestBloc(requestRepository: getIt<RequestRepository>()),
  );

  // Chat (registered before Matches since MatchBloc depends on ChatRepository)
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(getIt<FirebaseService>(), getIt<CloudinaryService>()),
  );
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      chatRepository: getIt<ChatRepository>(),
      firebaseService: getIt<FirebaseService>(),
    ),
  );

  // Matches
  getIt.registerLazySingleton<MatchRepository>(
    () => MatchRepository(getIt<FirebaseService>()),
  );
  getIt.registerFactory<MatchBloc>(
    () => MatchBloc(
      matchRepository: getIt<MatchRepository>(),
      chatRepository: getIt<ChatRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );

  // Notifications
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<FirebaseService>()),
  );
  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(getIt<NotificationRepository>()),
  );
}
