import 'package:get_it/get_it.dart';

import '../core/services/cloudinary_service.dart';
import '../core/services/firebase_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/profile/data/repositories/profile_repository.dart';
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

  // Placeholders for future repos
}
