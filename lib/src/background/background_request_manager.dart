import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'background_request_config.dart';
import 'background_request_executor.dart';
import 'background_result.dart';

/// Key prefix for storing background results in SharedPreferences.
const String _resultKeyPrefix = 'bg_request_result_';

/// Key for storing the list of all result keys.
const String _resultIndexKey = 'bg_request_result_index';

/// WorkManager unique task name prefix.
const String _taskPrefix = 'api_request_bg_';

/// Main manager for scheduling and tracking background API requests.
///
/// This singleton coordinates background request execution via WorkManager,
/// persists results using SharedPreferences, and provides APIs for scheduling,
/// cancellation, and result retrieval.
///
/// ## Setup
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await BackgroundRequestManager.instance!.initialize();
///
///   BackgroundRequestManager.instance!.onBackgroundResult = (result) {
///     debugPrint('Background task done: ${result.taskTag}');
///   };
///
///   await BackgroundRequestManager.instance!.processPendingResults();
///   runApp(MyApp());
/// }
/// ```
///
/// ## Scheduling
///
/// ```dart
/// await BackgroundRequestManager.instance!.scheduleOneOff(
///   config: config,
///   initialDelay: Duration(seconds: 5),
/// );
/// ```
class BackgroundRequestManager {
  static BackgroundRequestManager? _instance;

  static BackgroundRequestManager? get instance {
    _instance ??= BackgroundRequestManager._();
    return _instance;
  }

  BackgroundRequestManager._();

  /// Callback invoked when a background result is processed.
  void Function(BackgroundResult result)? onBackgroundResult;

  /// Initializes WorkManager. Must be called once before scheduling tasks.
  ///
  /// Call this in your `main()` before `runApp()`.
  ///
  /// [isInDebugMode] enables WorkManager debug logging.
  Future<void> initialize({bool isInDebugMode = false}) async {
    await Workmanager().initialize(
      backgroundRequestCallbackDispatcher,
      isInDebugMode: isInDebugMode,
    );
  }

  /// Schedules a one-off background request.
  ///
  /// The request will execute once, even if the app is closed.
  ///
  /// [config] contains all request details (URL, method, headers, etc.).
  /// [initialDelay] delays execution from now (default: immediate).
  /// [constraints] platform-specific constraints (e.g. network required).
  /// [existingWorkPolicy] how to handle existing tasks with same tag.
  Future<void> scheduleOneOff({
    required BackgroundRequestConfig config,
    Duration initialDelay = Duration.zero,
    Constraints? constraints,
    ExistingWorkPolicy existingWorkPolicy = ExistingWorkPolicy.replace,
  }) async {
    await Workmanager().registerOneOffTask(
      '$_taskPrefix${config.taskTag}',
      config.taskTag,
      initialDelay: initialDelay,
      constraints: constraints,
      existingWorkPolicy: existingWorkPolicy,
      inputData: config.toInputData(),
    );
  }

  /// Schedules a periodic background request.
  ///
  /// The request will repeat at the given [frequency].
  /// On iOS, the minimum frequency is 15 minutes.
  ///
  /// [config] contains all request details.
  /// [frequency] interval between executions (default: 15 minutes).
  /// [initialDelay] delay before first execution.
  /// [constraints] platform-specific constraints.
  /// [existingWorkPolicy] how to handle existing tasks with same tag.
  Future<void> schedulePeriodic({
    required BackgroundRequestConfig config,
    Duration frequency = const Duration(minutes: 15),
    Duration initialDelay = Duration.zero,
    Constraints? constraints,
    ExistingWorkPolicy existingWorkPolicy =
        ExistingWorkPolicy.replace,
  }) async {
    await Workmanager().registerPeriodicTask(
      '$_taskPrefix${config.taskTag}',
      config.taskTag,
      frequency: frequency,
      initialDelay: initialDelay,
      constraints: constraints,
      existingWorkPolicy: existingWorkPolicy,
      inputData: config.toInputData(),
    );
  }

  /// Cancels a scheduled background task by its tag.
  Future<void> cancel(String taskTag) async {
    await Workmanager().cancelByTag('$_taskPrefix$taskTag');
  }

  /// Cancels all scheduled background tasks.
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Retrieves all stored background results.
  Future<List<BackgroundResult>> getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getStringList(_resultIndexKey) ?? [];
    final results = <BackgroundResult>[];

    for (final key in index) {
      final json = prefs.getString(key);
      if (json != null) {
        results.add(BackgroundResult.fromJsonString(json));
      }
    }

    return results;
  }

  /// Retrieves a single background result by task tag.
  Future<BackgroundResult?> getResult(String taskTag) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_resultKeyPrefix$taskTag');
    if (json == null) return null;
    return BackgroundResult.fromJsonString(json);
  }

  /// Clears a stored result by task tag.
  Future<void> clearResult(String taskTag) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_resultKeyPrefix$taskTag';
    await prefs.remove(key);

    final index = prefs.getStringList(_resultIndexKey) ?? [];
    index.remove(key);
    await prefs.setStringList(_resultIndexKey, index);
  }

  /// Clears all stored background results.
  Future<void> clearAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getStringList(_resultIndexKey) ?? [];

    for (final key in index) {
      await prefs.remove(key);
    }
    await prefs.remove(_resultIndexKey);
  }

  /// Processes all pending results and invokes [onBackgroundResult] for each.
  ///
  /// Call this at app startup to handle results from tasks that completed
  /// while the app was in the background. Results are cleared after processing.
  Future<void> processPendingResults() async {
    if (onBackgroundResult == null) return;

    final results = await getResults();
    for (final result in results) {
      onBackgroundResult!(result);
      await clearResult(result.taskTag);
    }
  }

  /// Saves a result to SharedPreferences (called from background isolate).
  static Future<void> _saveResult(BackgroundResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_resultKeyPrefix${result.taskTag}';
    await prefs.setString(key, result.toJsonString());

    final index = prefs.getStringList(_resultIndexKey) ?? [];
    if (!index.contains(key)) {
      index.add(key);
      await prefs.setStringList(_resultIndexKey, index);
    }
  }
}

/// Top-level callback dispatcher required by WorkManager.
///
/// This function runs in a background isolate and handles all background
/// API request executions. It must be annotated with `@pragma('vm:entry-point')`
/// to prevent tree-shaking.
@pragma('vm:entry-point')
void backgroundRequestCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (inputData == null) return Future.value(false);

      final config = BackgroundRequestConfig.fromInputData(inputData);
      final result = await BackgroundRequestExecutor.execute(config);
      await BackgroundRequestManager._saveResult(result);

      return Future.value(true);
    } catch (e) {
      debugPrint('BackgroundRequestManager: Task failed — $e');
      return Future.value(false);
    }
  });
}
