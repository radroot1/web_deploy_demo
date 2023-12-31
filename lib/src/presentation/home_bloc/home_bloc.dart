import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_intern/src/data/repositories/api_service.dart';
import 'package:test_intern/src/data/repositories/sql_service.dart';
import 'package:test_intern/src/domain/models/result_model.dart';
import 'package:test_intern/src/presentation/home_bloc/home_event.dart';
import 'package:test_intern/src/presentation/home_bloc/home_state.dart';

class HomeBloc extends Bloc<PagEvent, PagState> {
  final ApiService apiService;
  final SQLService service = SQLService();
  HomeBloc(this.apiService)
      : super(const PagState(
          page: 1,
          count: 20,
          result: [],
          isLoading: false,
          search: '',
          next: null,
          isCached: false,
          connection: false,
        )) {
    on<LoadListEvent>(_onLoadData);
    on<LoadNextPageEvent>(_onLoadNextPage);
    on<UpdateCountEvent>(_onUpdateCount);
    on<RefreshDataEvent>(_onRefreshData);
    on<SearchNameEvent>(_onSearch);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<bool> isInternetAvailable() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _onLoadData(LoadListEvent event, Emitter<PagState> emit) async {
    final bool isInternetConnected = await isInternetAvailable();
    List<ResultModel> data = [];
    if (isInternetConnected) {
      const nextPage = 1;
      final newData = await apiService.getResult(nextPage, state.count);
      await service.insertPaginatedList(newData.results);
      data = newData.results ?? [];
      emit(state.copyWith(connection: true, result: newData.results, page: nextPage));
    } else {
      final cachedData = await service.getCachedList();
      if (cachedData?.isNotEmpty ?? false) {
        data = cachedData ?? [];
      } else {
        data = [];
      }
    }
    bool isCached = !isInternetConnected || (data.isNotEmpty && !isInternetConnected);
    emit(state.copyWith(result: data, page: state.page, isCached: isCached));
  }

  void _onLoadNextPage(LoadNextPageEvent event, Emitter<PagState> emit) async {
    if (state.next == '') {
      return;
    }

    final nextPage = state.page + 1;
    final newData = await apiService.getResult(nextPage, state.count);

    if (newData.results?.isEmpty ?? true) {
      emit(state.copyWith(next: ''));
      return;
    }

    final updatedData = List.of(state.result)..addAll(newData.results ?? []);
    await service.insertPaginatedList(newData.results);
    emit(
      state.copyWith(result: updatedData, page: nextPage, next: newData.info?.next ?? '', isCached: false),
    );
  }

  void _onUpdateCount(UpdateCountEvent event, Emitter<PagState> emit) {
    emit(
      state.copyWith(
        count: event.newCount,
      ),
    );
  }

  void _onRefreshData(RefreshDataEvent event, Emitter<PagState> emit) async {
    const initialPage = 1;
    const initialCount = 20;

    final newData = await apiService.getResult(initialPage, initialCount);
    emit(
      state.copyWith(result: newData.results, page: initialPage, count: initialCount, next: newData.info?.next ?? ''),
    );
  }

  void _onSearch(SearchNameEvent event, Emitter<PagState> emit) async {
    final localResults = await service.getCachedList();
    if (localResults != null) {
      final filteredLocalResults =
          localResults.where((result) => result.name!.toLowerCase().contains(event.name.toLowerCase())).toList();
      if (filteredLocalResults.isNotEmpty) {
        emit(state.copyWith(result: filteredLocalResults, page: 1, isLoading: false, next: ''));
        return;
      }
    }
    final remoteResults = await apiService.fetchNameSearch(event.name);
    emit(
      PagState(
        result: remoteResults.results ?? [],
        page: 1,
        count: remoteResults.results?.length ?? 0,
        isLoading: false,
        search: event.name,
        next: '',
        isCached: false,
        connection: false,
      ),
    );
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<PagState> emit) async {
    const initialPage = 1;
    final newData = await apiService.getResult(initialPage, state.count);
    emit(
      PagState(
        result: newData.results ?? [],
        page: 1,
        count: newData.results?.length ?? 0,
        isLoading: false,
        search: '',
        next: newData.info?.next ?? '',
        isCached: false,
        connection: false,
      ),
    );
  }
}
