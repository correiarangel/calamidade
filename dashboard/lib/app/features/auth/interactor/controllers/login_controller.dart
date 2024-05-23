import 'package:core_module/core_module.dart';
import 'package:dashboard/app/features/auth/interactor/repositories/login_repository.dart';
import 'package:dashboard/app/features/auth/interactor/states/login_states.dart';
import 'package:flutter/material.dart';

const _kUserKey = 'user';
const _kTokenKey = 'token';
const _kRefreshTokenKey = 'refreshToken';
const _kTokenExpiresKey = 'tokenExpires';

class LoginController extends BaseController<BaseState> {
  LoginController({
    required this.cache,
    required this.repository,
  }) : super(LoginInitial());

  final LoginRepository repository;
  final ICache cache;

  late final passwordController = TextEditingController();
  late final emailController = TextEditingController();
  late final formKey = GlobalKey<FormState>();

  Future<void> checkSession() async {
    update(LoginLoading());

    final user = await getUser();
    if (user == null) {
      return update(LoginInitial());
    }

    update(LoginSuccess(data: user));
  }

  Future<void> login() async {
    update(LoginLoading());

    final email = emailController.text;
    final password = passwordController.text;

    final result = await repository.login(
      credentials: CredentialsEntity(email: email, password: password),
    );

    result.fold(
      (error) => update(LoginError(exception: error)),
      (success) => tokenStorage(success),
    );
  }

  Future<UserEntity?> getUser() async {
    final userMap = await cache.getData(_kUserKey);
    if (userMap == null) return null;

    return UserAdapter.fromJson(userMap);
  }

  Future<void> tokenStorage(SessionEntity session) async {
    final token = session.token;
    final refreshToken = session.refreshToken;
    final tokenExpires = session.tokenExpires;
    final user = session.user;

    await cache.setData(
      params: CacheParams(key: _kTokenKey, value: token),
    );
    await cache.setData(
      params: CacheParams(key: _kRefreshTokenKey, value: refreshToken),
    );
    await cache.setData(
      params: CacheParams(key: _kTokenExpiresKey, value: tokenExpires),
    );
    await cache.setData(
      params: CacheParams(key: _kUserKey, value: UserAdapter.toJson(user)),
    );

    update(LoginSuccess(data: session.user));
  }

  Future<String> getToken() {
    return cache.getData(_kTokenKey).then((value) => value ?? '');
  }

  Future<String> getRefreshToken() {
    return cache.getData(_kRefreshTokenKey).then((value) => value ?? '');
  }

  String? Function(String?)? validatorEmpty(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return message;
      }
      return null;
    };
  }
}
