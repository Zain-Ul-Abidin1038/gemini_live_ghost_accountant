import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

final geminiLoggerProvider = Provider((ref) => GeminiLogger());

/// Request Logging Middleware
/// Tracks all Gemini API requests and responses
class GeminiLogger {
  void logRequest(String model, Map<String, dynamic> request) {
    safePrint('[Gemini] → $model');
    safePrint('[Gemini] Request size: ${jsonEncode(request).length} chars');
    
    // Log thinking level if present
    final thinkingLevel = request['generationConfig']?['thinkingConfig']?['thinkingLevel'];
    if (thinkingLevel != null) {
      safePrint('[Gemini] Thinking level: $thinkingLevel');
    }
  }

  void logResponse(Map<String, dynamic> response) {
    final usage = response['usageMetadata'];
    if (usage != null) {
      final promptTokens = usage['promptTokenCount'] ?? 0;
      final outputTokens = usage['candidatesTokenCount'] ?? 0;
      final totalTokens = usage['totalTokenCount'] ?? 0;
      
      safePrint('[Gemini] Tokens: prompt=$promptTokens, output=$outputTokens, total=$totalTokens');
    }
    
    // Log response text for debugging
    try {
      final candidates = response['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        if (parts.isNotEmpty && parts[0].containsKey('text')) {
          final text = parts[0]['text'] as String;
          final preview = text.length > 200 ? '${text.substring(0, 200)}...' : text;
          safePrint('[Gemini] Response preview: $preview');
        }
      }
    } catch (e) {
      // Ignore logging errors
    }
  }

  void logError(Object error) {
    safePrint('[Gemini] ERROR: $error');
  }
  
  void logRetry(int attempt, Duration delay) {
    safePrint('[Gemini] Retry attempt $attempt after ${delay.inMilliseconds}ms');
  }
}
