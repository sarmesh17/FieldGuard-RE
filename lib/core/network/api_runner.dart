import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/network/network_exception_mapper.dart';
import 'package:field_guard_re/core/utils/result.dart';

mixin ApiRunner {
  Future<Result<T>> safeCall<T>(Future<T> Function() fn) async {
    try {
      return Success(await fn());
    } on DioException catch (e) {
      return Failure(NetworkExceptionMapper.map(e));
    } on AppException catch (e) {
      return Failure(e);
    } catch (_) {
      return Failure(const ServerException(AppStrings.serverError));
    }
  }
}
