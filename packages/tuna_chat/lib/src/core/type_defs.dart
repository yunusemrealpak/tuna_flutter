import 'package:dartz/dartz.dart';

import 'failures.dart';

/// Convenience typedef — every repository method returns this.
typedef FutureEither<T> = Future<Either<Failure, T>>;
