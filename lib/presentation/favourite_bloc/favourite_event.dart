import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_intern/domain/models/result_model.dart';

abstract class FavoritesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class AddToFavoritesEvent extends FavoritesEvent {
  final ResultModel item;
  AddToFavoritesEvent(this.item);
}

class RemoveFromFavoritesEvent extends FavoritesEvent {
  final ResultModel item;
  RemoveFromFavoritesEvent(this.item);
}

class FavoritesLoadedEvent extends FavoritesEvent {
  FavoritesLoadedEvent();
}

class LoadFavoritesForUserEvent extends FavoritesEvent {
  final User newUserEmail;

  LoadFavoritesForUserEvent(this.newUserEmail);
}

class ClearUserFavouriteEvent extends FavoritesEvent {}
