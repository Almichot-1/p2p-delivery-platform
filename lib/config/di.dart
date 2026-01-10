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
  if (!getIt.isRegistered<FirebaseService>()) {
    getIt.registerLazySingleton<FirebaseService>(() => FirebaseService.instance);
  }
  if (!getIt.isRegistered<CloudinaryService>()) {
    getIt.registerLazySingleton<CloudinaryService>(() => CloudinaryService.instance);
  }

  // Auth
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(firebaseService: getIt<FirebaseService>()),
    );
  }
  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(authRepository: getIt<AuthRepository>()),
    );
  }

  // Profile
  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(
        getIt<FirebaseService>(),
        getIt<CloudinaryService>(),
      ),
    );
  }
  if (!getIt.isRegistered<ProfileBloc>()) {
    getIt.registerFactory<ProfileBloc>(
      () => ProfileBloc(profileRepository: getIt<ProfileRepository>()),
    );
  }

  // Trips
  if (!getIt.isRegistered<TripRepository>()) {
    getIt.registerLazySingleton<TripRepository>(
      () => TripRepository(getIt<FirebaseService>()),
    );
  }
  if (!getIt.isRegistered<TripBloc>()) {
    getIt.registerFactory<TripBloc>(
      () => TripBloc(tripRepository: getIt<TripRepository>()),
    );
  }

  // Requests
  if (!getIt.isRegistered<RequestRepository>()) {
    getIt.registerLazySingleton<RequestRepository>(
      () => RequestRepository(
        getIt<FirebaseService>(),
        getIt<CloudinaryService>(),
      ),
    );
  }
  if (!getIt.isRegistered<RequestBloc>()) {
    getIt.registerFactory<RequestBloc>(
      () => RequestBloc(requestRepository: getIt<RequestRepository>()),
    );
  }

  // Chat (registered before Matches since MatchBloc depends on ChatRepository)
  if (!getIt.isRegistered<ChatRepository>()) {
    getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepository(getIt<FirebaseService>(), getIt<CloudinaryService>()),
    );
  }
  if (!getIt.isRegistered<ChatBloc>()) {
    getIt.registerFactory<ChatBloc>(
      () => ChatBloc(
        chatRepository: getIt<ChatRepository>(),
        firebaseService: getIt<FirebaseService>(),
      ),
    );
  }

  // Matches
  if (!getIt.isRegistered<MatchRepository>()) {
    getIt.registerLazySingleton<MatchRepository>(
      () => MatchRepository(getIt<FirebaseService>()),
    );
  }
  if (!getIt.isRegistered<MatchBloc>()) {
    getIt.registerFactory<MatchBloc>(
      () => MatchBloc(
        matchRepository: getIt<MatchRepository>(),
        chatRepository: getIt<ChatRepository>(),
        notificationRepository: getIt<NotificationRepository>(),
      ),
    );
  }

  // Notifications
  if (!getIt.isRegistered<NotificationRepository>()) {
    getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(getIt<FirebaseService>()),
    );
  }
  if (!getIt.isRegistered<NotificationBloc>()) {
    getIt.registerFactory<NotificationBloc>(
      () => NotificationBloc(getIt<NotificationRepository>()),
    );
  }
}
