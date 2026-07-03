import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../models/category_model.dart';

class CategoriesRepository {
  CategoriesRepository(this._dio);

  final Dio _dio;

  Future<ApiResult<List<CategoryModel>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final list = (response.data as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiSuccess(list);
    } on DioException catch (e) {
      return ApiError(
        e.response?.data?['message'] as String? ?? 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(dioProvider)),
);
