import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings.g.dart';

class ExcludeAndroidAutoState {
  final bool? value;
  final Object? error;
  final bool isSaving;
  final bool? pendingValue;

  const ExcludeAndroidAutoState({
    this.value,
    this.error,
    this.isSaving = false,
    this.pendingValue,
  });
}

@Riverpod(keepAlive: true)
class ExcludeAndroidAuto extends _$ExcludeAndroidAuto {
  static const _preferenceKey = 'excludeAndroidAuto';

  @override
  Future<ExcludeAndroidAutoState> build() async {
    try {
      final value = await SharedPreferencesAsync().getBool(_preferenceKey);
      return ExcludeAndroidAutoState(value: value ?? false);
    } catch (error) {
      return ExcludeAndroidAutoState(error: error);
    }
  }

  Future<void> setExcludeAndroidAuto(bool value) async {
    final previousValue = state.requireValue.value;
    state = AsyncData(
      ExcludeAndroidAutoState(
        value: previousValue,
        isSaving: true,
        pendingValue: value,
      ),
    );

    try {
      await SharedPreferencesAsync().setBool(_preferenceKey, value);
      state = AsyncData(ExcludeAndroidAutoState(value: value));
    } catch (error) {
      state = AsyncData(
        ExcludeAndroidAutoState(
          value: previousValue,
          error: error,
          pendingValue: value,
        ),
      );
    }
  }

  Future<void> retry() async {
    final pendingValue = state.value?.pendingValue;
    if (pendingValue == null) {
      ref.invalidateSelf();
    } else {
      await setExcludeAndroidAuto(pendingValue);
    }
  }
}
