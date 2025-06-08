import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OCR Detection Logic Tests', () {
    test('should detect OCR items with autoChecked flag', () {
      // Test data simulating OCR processed items
      final ocrDetectedItem = {
        'nama': 'Jeruk Manis',
        'jumlah': 5,
        'autoChecked': true,
        'source': 'paddle_ocr',
        'confidence': 0.95,
      };

      // Simulate the OCR detection logic
      bool isOcrDetected = _isOcrDetected(ocrDetectedItem);

      expect(isOcrDetected, true);
    });

    test('should detect OCR items with paddle_ocr source', () {
      final paddleOcrItem = {
        'nama': 'Apel Merah',
        'jumlah': 3,
        'source': 'paddle_ocr',
        'confidence': 0.8,
      };

      bool isOcrDetected = _isOcrDetected(paddleOcrItem);

      expect(isOcrDetected, true);
    });

    test('should detect OCR items with ocr source', () {
      final ocrItem = {
        'nama': 'Mangga',
        'jumlah': 2,
        'source': 'ocr',
        'confidence': 0.9,
      };

      bool isOcrDetected = _isOcrDetected(ocrItem);

      expect(isOcrDetected, true);
    });

    test('should detect OCR items with mlkit source', () {
      final mlkitItem = {
        'nama': 'Pisang',
        'jumlah': 10,
        'source': 'mlkit',
        'confidence': 0.85,
      };

      bool isOcrDetected = _isOcrDetected(mlkitItem);

      expect(isOcrDetected, true);
    });

    test('should detect OCR items with isOcrDetected flag', () {
      final flaggedItem = {
        'nama': 'Tomat',
        'jumlah': 4,
        'isOcrDetected': true,
      };

      bool isOcrDetected = _isOcrDetected(flaggedItem);

      expect(isOcrDetected, true);
    });

    test('should detect OCR items with high confidence', () {
      final highConfidenceItem = {
        'nama': 'Kentang',
        'jumlah': 7,
        'confidence': 0.9,
      };

      bool isOcrDetected = _isOcrDetected(highConfidenceItem);

      expect(isOcrDetected, true);
    });

    test('should not detect manual items', () {
      final manualItem = {
        'nama': 'Wortel',
        'jumlah': 3,
        'confidence': 0.3,
      };

      bool isOcrDetected = _isOcrDetected(manualItem);

      expect(isOcrDetected, false);
    });

    test('should not detect items with low confidence', () {
      final lowConfidenceItem = {
        'nama': 'Kubis',
        'jumlah': 1,
        'confidence': 0.5,
      };

      bool isOcrDetected = _isOcrDetected(lowConfidenceItem);

      expect(isOcrDetected, false);
    });
  });
}

// Helper function that simulates the OCR detection logic from the app
bool _isOcrDetected(Map<String, dynamic> item) {
  // Check multiple criteria for OCR detection
  bool autoChecked = item['autoChecked'] == true;
  bool paddleOcrSource = item['source'] == 'paddle_ocr';
  bool ocrSource = item['source'] == 'ocr';
  bool mlkitSource = item['source'] == 'mlkit';
  bool hasOcrFlag = item['isOcrDetected'] == true;
  bool highConfidence =
      (item['confidence'] is num) && (item['confidence'] >= 0.7);

  return autoChecked ||
      paddleOcrSource ||
      ocrSource ||
      mlkitSource ||
      hasOcrFlag ||
      highConfidence;
}
