import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiFallbackProvider = Provider((ref) => GeminiFallbackEngine());

/// Offline Fallback Engine
/// Provides graceful degradation when Gemini API is unavailable
class GeminiFallbackEngine {
  Map<String, dynamic> textResponse(String prompt) {
    return {
      'success': false,
      'text': 'I\'m offline right now, but I can still help record this once connection returns.',
      'offline': true,
      'thoughtSignature': 'offline',
    };
  }

  Map<String, dynamic> receiptResponse() {
    return {
      'vendor': 'Unknown',
      'date': '',
      'total': 0.0,
      'tax': 0.0,
      'currency': 'INR',
      'category': 'Unknown',
      'alcoholAmount': 0.0,
      'deductibleAmount': 0.0,
      'confidence': 0.0,
      'notes': 'Offline - unable to analyze receipt',
      'thoughtSignature': 'offline',
      'offline': true,
    };
  }
  
  Map<String, dynamic> financeCommandResponse() {
    return {
      'action': 'unknown',
      'amount': null,
      'currency': null,
      'category': null,
      'personName': null,
      'description': 'Offline - command will be processed when connection returns',
      'offline': true,
    };
  }
}
