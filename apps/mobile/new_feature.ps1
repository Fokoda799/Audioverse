# =====================================================
#  Flutter Feature Generator — AudioVerse structure
#  Usage: .\new_feature.ps1 -feature profile
#         .\new_feature.ps1 -feature user_settings
# =====================================================

param (
    [Parameter(Mandatory = $true)]
    [string]$feature
)

# ── Convert to snake_case (e.g. "UserProfile" → "user_profile") ──────────────
$snake = ($feature -creplace '([A-Z])', '_$1').ToLower().TrimStart('_')

# ── PascalCase for class names (e.g. "user_profile" → "UserProfile") ─────────
$pascal = ($snake -split '_' | ForEach-Object {
    $_.Substring(0,1).ToUpper() + $_.Substring(1)
}) -join ''

# ── Base path — matches your project structure ────────────────────────────────
$base = "lib/features/$snake"

# ── Create folders ────────────────────────────────────────────────────────────
$folders = @("$base/screens", "$base/widgets")
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# ==============================================================================
#  FILE TEMPLATES
# ==============================================================================

# ── 1. {feature}.dart — barrel export ─────────────────────────────────────────
# Matches: auth.dart
# Re-exports everything in the feature so other parts of the app
# only need one import: package:Audioverse/features/profile/profile.dart
$barrelFile = @"
// $pascal feature — barrel export
// Import this single file to access everything in the $snake feature.
//
// Usage from another feature:
//   import 'package:Audioverse/features/$snake/$snake.dart';

export '${snake}_models.dart';
export '${snake}_repository.dart';
export '${snake}_repository_impl.dart';
export '${snake}_provider.dart';
"@

# ── 2. {feature}_models.dart — data models ────────────────────────────────────
# Matches: auth_models.dart
# Contains the data classes with fromJson/toJson.
# No Flutter imports — pure Dart only.
$modelsFile = @"
// $pascal Models
// Pure Dart data classes — no Flutter, no Dio, no external dependencies.
// These are the shapes of data that flow through the $snake feature.

class $pascal {
  final String id;
  // TODO: add your fields here

  const $pascal({
    required this.id,
  });

  /// Build from the JSON your NestJS server returns.
  /// Match the exact key names your API sends (camelCase for NestJS default).
  factory $pascal.fromJson(Map<String, dynamic> json) {
    return $pascal(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
  };

  @override
  String toString() => '$pascal(id: \$id)';
}
"@

# ── 3. {feature}_repository.dart — abstract contract ─────────────────────────
# Matches: auth_repository.dart
# The interface that defines WHAT this feature can do.
# Never changes when you swap implementations (e.g. mock for tests).
$repositoryFile = @"
import '${snake}_models.dart';

// $pascal Repository — abstract contract
//
// Defines WHAT the $snake feature can do.
// The implementation (${snake}_repository_impl.dart) decides HOW.
//
// This separation means you can swap implementations freely:
//   - Real API in production
//   - Mock in tests
//   - Local cache during offline mode

abstract class ${pascal}Repository {
  // TODO: add your method signatures here
  // Example:
  // Future<$pascal>  getById(String id);
  // Future<$pascal>  update(String id, Map<String, dynamic> data);
  // Future<void>     delete(String id);
}
"@

# ── 4. {feature}_repository_impl.dart — Dio implementation ───────────────────
# Matches: auth_repository_impl.dart
# The concrete class that makes real HTTP calls using Dio.
# Only this file knows about HTTP, JSON, and error codes.
$repositoryImplFile = @"
import 'package:dio/dio.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import '${snake}_models.dart';
import '${snake}_repository.dart';

// $pascal Repository Implementation
//
// Makes real HTTP calls using Dio.
// The Dio instance is injected — it already has the AuthInterceptor
// attached, so Bearer tokens are added automatically to every request.
//
// Every method follows the same pattern:
//   1. Call the API with Dio
//   2. Parse the JSON response with fromJson()
//   3. Return the clean model — or throw a readable exception

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final Dio _dio;

  ${pascal}RepositoryImpl({required Dio dio}) : _dio = dio;

  // TODO: implement your methods here
  // Example:
  // @override
  // Future<$pascal> getById(String id) async {
  //   try {
  //     AppLogger.d('GET /$snake/\$id');
  //     final response = await _dio.get('/$snake/\$id');
  //     return $pascal.fromJson(response.data);
  //   } on DioException catch (e) {
  //     throw _handleError(e);
  //   }
  // }

  // ── Error handler ─────────────────────────────────────────────────────────
  // Converts raw Dio errors into readable exceptions.
  // Add this to every repository impl — same pattern as auth.
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final status  = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Something went wrong';
        return switch (status) {
          400 => Exception('Bad request: `$message'),
          401 => Exception('Unauthorized.'),
          403 => Exception('Forbidden.'),
          404 => Exception('Not found.'),
          409 => Exception('Conflict: `$message'),
          500 => Exception('Server error. Try again later.'),
          _   => Exception('Error `$status: `$message'),
        };
      default:
        return Exception('Unexpected error. Please try again.');
    }
  }
}
"@

# ── 5. {feature}_provider.dart — state management ────────────────────────────
# Matches: auth_provider.dart
# Owns all state for this feature. Screens never call the repository
# directly — they always go through the provider.
$providerFile = @"
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import '${snake}_models.dart';
import '${snake}_repository.dart';

// $pascal Provider
//
// Owns ALL state for the $snake feature.
// Screens read from it via context.watch<${pascal}Provider>()
// Screens call methods via context.read<${pascal}Provider>().methodName()
//
// State the UI reacts to:
//   isLoading    → show spinners, disable buttons
//   data         → the main data object for this feature
//   errorMessage → show error banners

class ${pascal}Provider extends ChangeNotifier {
  final ${pascal}Repository _repository;

  ${pascal}Provider({required ${pascal}Repository repository})
      : _repository = repository;

  // ── State ─────────────────────────────────────────────────────────────────
  bool      _isLoading    = false;
  $pascal?  _data;
  String?   _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool     get isLoading    => _isLoading;
  $pascal? get data         => _data;
  String?  get errorMessage => _errorMessage;

  // TODO: add your methods here
  // Example:
  // Future<void> load(String id) async {
  //   AppLogger.d('Loading $snake → \$id');
  //   _setLoading();
  //   try {
  //     _data = await _repository.getById(id);
  //     _clearError();
  //     AppLogger.i('$snake loaded → \$id');
  //   } catch (e, st) {
  //     AppLogger.e('Failed to load $snake', error: e, stackTrace: st);
  //     _setError(e);
  //   } finally {
  //     _stopLoading();
  //   }
  // }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _setError(Object e) {
    _errorMessage = e.toString().replaceAll('Exception: ', '');
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
"@

# ── 6. screens/{feature}_screen.dart — main screen ───────────────────────────
# Matches: screens/login_screen.dart pattern
# Reads state from provider via context.watch()
# Calls methods via context.read()
$screenFile = @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../${snake}_provider.dart';

// ${pascal}Screen — main screen for the $snake feature
//
// Reads state:  context.watch<${pascal}Provider>()  → rebuilds on change
// Calls methods: context.read<${pascal}Provider>()  → inside callbacks only

class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<${pascal}Provider>();

    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: switch (provider.isLoading) {
        true  => const Center(child: CircularProgressIndicator()),
        false => provider.errorMessage != null
            ? Center(child: Text(provider.errorMessage!))
            : const Center(child: Text('TODO: build your UI here')),
      },
    );
  }
}
"@

# ==============================================================================
#  WRITE FILES
# ==============================================================================

$files = @{
    "$base/${snake}.dart"                     = $barrelFile
    "$base/${snake}_models.dart"              = $modelsFile
    "$base/${snake}_repository.dart"          = $repositoryFile
    "$base/${snake}_repository_impl.dart"     = $repositoryImplFile
    "$base/${snake}_provider.dart"            = $providerFile
    "$base/screens/${snake}_screen.dart"      = $screenFile
}

foreach ($path in $files.Keys) {
    if (-Not (Test-Path $path)) {
        New-Item -ItemType File -Path $path -Force | Out-Null
        Set-Content -Path $path -Value $files[$path] -Encoding UTF8
        Write-Host "  [+] $path" -ForegroundColor Cyan
    } else {
        Write-Host "  [~] skipped (exists): $path" -ForegroundColor Yellow
    }
}

# ==============================================================================
#  SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "  Feature '$snake' created!" -ForegroundColor Green
Write-Host ""
Write-Host "  $base/"
Write-Host "  |-- ${snake}.dart                   <- barrel export"
Write-Host "  |-- ${snake}_models.dart             <- data models + fromJson"
Write-Host "  |-- ${snake}_repository.dart         <- abstract contract"
Write-Host "  |-- ${snake}_repository_impl.dart    <- Dio implementation"
Write-Host "  |-- ${snake}_provider.dart           <- state (ChangeNotifier)"
Write-Host "  |-- screens/"
Write-Host "  |   `-- ${snake}_screen.dart         <- main screen"
Write-Host "  `-- widgets/                         <- (empty, add as needed)"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add fields to ${snake}_models.dart"
Write-Host "  2. Add method signatures to ${snake}_repository.dart"
Write-Host "  3. Implement methods in ${snake}_repository_impl.dart"
Write-Host "  4. Add state methods to ${snake}_provider.dart"
Write-Host "  5. Wire provider in main.dart"
Write-Host "  6. Add route in app_router.dart"
Write-Host ""