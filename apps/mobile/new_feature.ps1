# =====================================================
#  Flutter Feature Generator
#  Usage: .\new_feature.ps1 -feature auth
# =====================================================

param (
    [Parameter(Mandatory = $true)]
    [string]$feature
)

# ── Convert feature name to snake_case (e.g. "UserProfile" → "user_profile") ──
$snake = ($feature -creplace '([A-Z])', '_$1').ToLower().TrimStart('_')

# ── Base path ─────────────────────────────────────────────────────────────────
$base = "lib/features/$snake"

# ── Define folders to create ──────────────────────────────────────────────────
$folders = @(
    "$base/screens",
    "$base/widgets"
)

# ── Create folders ────────────────────────────────────────────────────────────
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

Write-Host ""
Write-Host "  Feature '$snake' created!" -ForegroundColor Green
Write-Host ""

# ==============================================================================
#  FILE TEMPLATES
# ==============================================================================

# ── 1. user.dart (Model) ──────────────────────────────────────────────────────
$modelName = (Get-Culture).TextInfo.ToTitleCase($snake.Replace('_', ' ')).Replace(' ', '')

$modelFile = @"
// $modelName Model
// Holds the data shape + JSON parsing for $snake feature.

class $modelName {
  final String id;
  // TODO: add your fields here

  const $modelName({
    required this.id,
  });

  factory $modelName.fromJson(Map<String, dynamic> json) {
    return $modelName(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
  };
}
"@

# ── 2. {feature}_service.dart (API Calls) ────────────────────────────────────
$serviceFile = @"
import 'dart:convert';
import 'package:http/http.dart' as http;
import '${snake}.dart';

// ${modelName}Service
// Handles all API calls for the $snake feature.

class ${modelName}Service {
  final String _baseUrl;
  final http.Client _client;

  ${modelName}Service({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  // TODO: add your API methods here
  // Example:
  // Future<$modelName> fetchById(String id) async {
  //   final res = await _client.get(Uri.parse('\$_baseUrl/$snake/\$id'));
  //   _throwIfError(res);
  //   return $modelName.fromJson(jsonDecode(res.body));
  // }

  void _throwIfError(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception('\${response.statusCode}: \${body['message'] ?? 'Error'}');
    }
  }
}
"@

# ── 3. {feature}_provider.dart (State) ───────────────────────────────────────
$providerFile = @"
import 'package:flutter/foundation.dart';
import '${snake}_service.dart';
import '${snake}.dart';

// State values for $snake feature
enum ${modelName}Status { initial, loading, success, error }

// ${modelName}Provider
// Manages state for the $snake feature.
// Call methods from the UI, listen to status/data/errorMessage.

class ${modelName}Provider extends ChangeNotifier {
  final ${modelName}Service _service;

  ${modelName}Provider({required ${modelName}Service service})
      : _service = service;

  // ── State ────────────────────────────────────────────────────────────────
  ${modelName}Status _status = ${modelName}Status.initial;
  $modelName? _data;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  ${modelName}Status get status => _status;
  $modelName? get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ${modelName}Status.loading;

  // TODO: add your methods here
  // Example:
  // Future<void> load(String id) async {
  //   _setLoading();
  //   try {
  //     _data = await _service.fetchById(id);
  //     _setSuccess();
  //   } catch (e) {
  //     _setError(e.toString());
  //   }
  // }

  // ── Private helpers ──────────────────────────────────────────────────────
  void _setLoading() {
    _status = ${modelName}Status.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSuccess() {
    _status = ${modelName}Status.success;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ${modelName}Status.error;
    _errorMessage = message;
    notifyListeners();
  }
}
"@

# ── 4. {feature}_screen.dart (Main Screen) ───────────────────────────────────
$screenFile = @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../${snake}_provider.dart';

// ${modelName}Screen
// Main screen for the $snake feature.

class ${modelName}Screen extends StatelessWidget {
  const ${modelName}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<${modelName}Provider>();

    return Scaffold(
      appBar: AppBar(title: const Text('$modelName')),
      body: switch (provider.status) {
        ${modelName}Status.loading => const Center(child: CircularProgressIndicator()),
        ${modelName}Status.error   => Center(child: Text(provider.errorMessage ?? 'Error')),
        _                          => const Center(child: Text('TODO: build your UI here')),
      },
    );
  }
}
"@

# ── 5. {feature}_form_widget.dart (Reusable Widget) ──────────────────────────
$widgetFile = @"
import 'package:flutter/material.dart';

// ${modelName}FormWidget
// A reusable widget for the $snake feature.
// Drop it into any screen that needs this UI piece.

class ${modelName}FormWidget extends StatelessWidget {
  final VoidCallback? onSubmit;

  const ${modelName}FormWidget({super.key, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO: add your form fields here
        ElevatedButton(
          onPressed: onSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
"@

# ==============================================================================
#  WRITE FILES
# ==============================================================================

$files = @{
    "$base/${snake}.dart"                        = $modelFile
    "$base/${snake}_service.dart"                = $serviceFile
    "$base/${snake}_provider.dart"               = $providerFile
    "$base/screens/${snake}_screen.dart"         = $screenFile
    "$base/widgets/${snake}_form_widget.dart"    = $widgetFile
}

foreach ($path in $files.Keys) {
    # Only create if file doesn't already exist (won't overwrite your work)
    if (-Not (Test-Path $path)) {
        New-Item -ItemType File -Path $path -Force | Out-Null
        Set-Content -Path $path -Value $files[$path] -Encoding UTF8
        Write-Host "  [+] $path" -ForegroundColor Cyan
    } else {
        Write-Host "  [~] skipped (already exists): $path" -ForegroundColor Yellow
    }
}

# ==============================================================================
#  PRINT SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "  Structure created under $base/" -ForegroundColor Green
Write-Host ""
Write-Host "  $base/"
Write-Host "  |-- ${snake}.dart              <- Model + JSON"
Write-Host "  |-- ${snake}_service.dart      <- API calls"
Write-Host "  |-- ${snake}_provider.dart     <- State"
Write-Host "  |-- screens/"
Write-Host "  |   `-- ${snake}_screen.dart   <- Main screen"
Write-Host "  `-- widgets/"
Write-Host "      `-- ${snake}_form_widget.dart  <- Reusable widget"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add your fields to ${snake}.dart"
Write-Host "  2. Add your API calls to ${snake}_service.dart"
Write-Host "  3. Add your methods to ${snake}_provider.dart"
Write-Host "  4. Build your UI in screens/${snake}_screen.dart"
Write-Host ""