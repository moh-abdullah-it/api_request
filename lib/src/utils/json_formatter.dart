import 'dart:convert';
import 'log_colors.dart';

/// A utility class for formatting and syntax highlighting JSON data.
///
/// This class provides methods to format JSON strings with proper indentation
/// and apply color syntax highlighting for better readability in console output.
///
/// ## Features
///
/// - **Pretty Printing**: Formats JSON with proper indentation
/// - **Syntax Highlighting**: Colors different JSON elements (keys, values, braces, etc.)
/// - **Type-aware Coloring**: Different colors for strings, numbers, booleans, null
/// - **Error Handling**: Graceful fallback for invalid JSON
///
/// ## Usage
///
/// ```dart
/// final jsonString = '{"name":"John","age":30,"active":true}';
/// final formatted = JsonFormatter.formatWithColors(jsonString);
/// print(formatted);
/// ```
///
/// ## Color Scheme
///
/// - **Keys**: Bright blue
/// - **Strings**: Green
/// - **Numbers**: Yellow
/// - **Booleans**: Magenta
/// - **Null**: Gray
/// - **Braces/Brackets**: Bright cyan
/// - **Punctuation**: White/Gray
class JsonFormatter {
  /// Private constructor to prevent instantiation
  JsonFormatter._();

  /// Formats JSON data with color syntax highlighting.
  ///
  /// This method attempts to parse and format the input data as JSON,
  /// applying color syntax highlighting for better readability.
  ///
  /// Parameters:
  /// - [data]: The data to format (can be String, Map, List, or any JSON-serializable object)
  /// - [indent]: Number of spaces for indentation (default: 2)
  ///
  /// Returns a formatted and colored JSON string. If parsing fails,
  /// returns the original data as a string with basic indentation.
  static String formatWithColors(dynamic data, {int indent = 2}) {
    try {
      String jsonString;
      
      // Convert data to JSON string if it's not already
      if (data is String) {
        // Try to parse and re-stringify to ensure valid JSON
        try {
          final parsed = json.decode(data);
          jsonString = json.encode(parsed);
        } catch (e) {
          // If it's not valid JSON, treat as plain string
          return _addIndentation(data.toString(), indent);
        }
      } else {
        jsonString = json.encode(data);
      }

      return _formatJsonWithColors(jsonString, indent);
    } catch (e) {
      // Fallback to simple indented formatting
      return _addIndentation(data.toString(), indent);
    }
  }

  /// Formats JSON string with syntax highlighting and indentation.
  static String _formatJsonWithColors(String jsonString, int indent) {
    final buffer = StringBuffer();
    int currentIndent = 0;
    final indentStr = ' ' * indent;
    bool inString = false;
    bool escapeNext = false;
    
    for (int i = 0; i < jsonString.length; i++) {
      final char = jsonString[i];
      final nextChar = i + 1 < jsonString.length ? jsonString[i + 1] : null;
      
      // Handle string escape sequences
      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }
      
      if (char == '\\' && inString) {
        buffer.write(char);
        escapeNext = true;
        continue;
      }
      
      // Handle string delimiters
      if (char == '"') {
        inString = !inString;
        buffer.write(LogColors.jsonQuote(char));
        continue;
      }
      
      // If we're inside a string, determine if it's a key or value
      if (inString) {
        // Look ahead to see if this string is followed by a colon (making it a key)
        final remainingText = jsonString.substring(i);
        final isKey = _isStringAKey(remainingText, i);
        
        if (isKey) {
          buffer.write(LogColors.jsonKey(char));
        } else {
          buffer.write(LogColors.jsonString(char));
        }
        continue;
      }
      
      // Handle JSON structure characters
      switch (char) {
        case '{':
          buffer.write(LogColors.jsonBraces(char));
          if (nextChar != '}') {
            currentIndent++;
            buffer.write('\n${indentStr * currentIndent}');
          }
          break;
          
        case '}':
          if (jsonString[i - 1] != '{') {
            currentIndent = (currentIndent - 1).clamp(0, double.infinity).toInt();
            buffer.write('\n${indentStr * currentIndent}');
          }
          buffer.write(LogColors.jsonBraces(char));
          break;
          
        case '[':
          buffer.write(LogColors.jsonBrackets(char));
          if (nextChar != ']') {
            currentIndent++;
            buffer.write('\n${indentStr * currentIndent}');
          }
          break;
          
        case ']':
          if (jsonString[i - 1] != '[') {
            currentIndent = (currentIndent - 1).clamp(0, double.infinity).toInt();
            buffer.write('\n${indentStr * currentIndent}');
          }
          buffer.write(LogColors.jsonBrackets(char));
          break;
          
        case ':':
          buffer.write(LogColors.jsonColon(char));
          buffer.write(' ');
          break;
          
        case ',':
          buffer.write(LogColors.jsonComma(char));
          buffer.write('\n${indentStr * currentIndent}');
          break;
          
        case ' ':
        case '\t':
        case '\n':
        case '\r':
          // Skip whitespace as we're adding our own formatting
          break;
          
        default:
          // Handle values (numbers, booleans, null)
          final value = _extractValue(jsonString, i);
          if (value.isNotEmpty) {
            buffer.write(_colorValue(value));
            i += value.length - 1; // Skip the characters we've processed
          } else {
            buffer.write(char);
          }
          break;
      }
    }
    
    return buffer.toString();
  }

  /// Extracts a complete value (number, boolean, null) starting at the given index.
  static String _extractValue(String jsonString, int startIndex) {
    final buffer = StringBuffer();
    
    for (int i = startIndex; i < jsonString.length; i++) {
      final char = jsonString[i];
      
      // Stop at JSON delimiters
      if (char == ',' || char == '}' || char == ']' || char == ':' || 
          char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        break;
      }
      
      buffer.write(char);
    }
    
    return buffer.toString();
  }

  /// Colors a JSON value based on its type.
  static String _colorValue(String value) {
    final trimmed = value.trim();
    
    if (trimmed.isEmpty) return value;
    
    // Check for null
    if (trimmed == 'null') {
      return LogColors.jsonNull(value);
    }
    
    // Check for boolean
    if (trimmed == 'true' || trimmed == 'false') {
      return LogColors.jsonBoolean(value);
    }
    
    // Check for number
    if (RegExp(r'^-?\d+\.?\d*([eE][+-]?\d+)?$').hasMatch(trimmed)) {
      return LogColors.jsonNumber(value);
    }
    
    // Default to white for unknown values
    return LogColors.white(value);
  }

  /// Determines if the current string is a JSON key by looking ahead for a colon.
  static bool _isStringAKey(String remainingText, int currentIndex) {
    // Find the closing quote of the current string
    var quoteIndex = 0;
    var escapeNext = false;
    
    for (int i = 0; i < remainingText.length; i++) {
      final char = remainingText[i];
      
      if (escapeNext) {
        escapeNext = false;
        continue;
      }
      
      if (char == '\\') {
        escapeNext = true;
        continue;
      }
      
      if (char == '"') {
        quoteIndex = i;
        break;
      }
    }
    
    // Look for a colon after the closing quote (ignoring whitespace)
    for (int i = quoteIndex + 1; i < remainingText.length; i++) {
      final char = remainingText[i];
      if (char == ':') {
        return true;
      } else if (char != ' ' && char != '\t' && char != '\n' && char != '\r') {
        return false;
      }
    }
    
    return false;
  }

  /// Adds basic indentation to non-JSON data.
  static String _addIndentation(String text, int indent) {
    final indentStr = ' ' * indent;
    return text.split('\n').map((line) => '$indentStr$line').join('\n');
  }

  /// Formats JSON data without colors (plain text formatting only).
  ///
  /// This method provides pretty-printed JSON without color codes,
  /// useful when colors are not desired or supported.
  static String formatPlain(dynamic data, {int indent = 2}) {
    try {
      String jsonString;
      
      if (data is String) {
        try {
          final parsed = json.decode(data);
          jsonString = json.encode(parsed);
        } catch (e) {
          return _addIndentation(data.toString(), indent);
        }
      } else {
        jsonString = json.encode(data);
      }

      // Use JsonEncoder for pretty printing
      const encoder = JsonEncoder.withIndent('  ');
      final parsed = json.decode(jsonString);
      final formatted = encoder.convert(parsed);
      
      return _addIndentation(formatted, indent);
    } catch (e) {
      return _addIndentation(data.toString(), indent);
    }
  }
}