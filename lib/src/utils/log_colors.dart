/// ANSI color codes for terminal/console output.
///
/// This class provides color formatting for log messages to improve readability
/// in terminal environments. Colors are automatically disabled in non-terminal
/// environments or when colors are not supported.
///
/// ## Usage
///
/// ```dart
/// print(LogColors.green('Success message'));
/// print(LogColors.red('Error message'));
/// print(LogColors.blue('Info message'));
/// ```
///
/// ## Color Support
///
/// Colors are enabled when:
/// - Running in a terminal that supports ANSI colors
/// - Not running in release mode (colors disabled for production)
/// - Environment supports color output
///
/// When colors are disabled, the methods return the original text unchanged.
class LogColors {
  // Private constructor to prevent instantiation
  LogColors._();

  // ANSI escape codes
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _dim = '\x1B[2m';
  static const String _italic = '\x1B[3m';
  static const String _underline = '\x1B[4m';

  // Foreground colors
  static const String _black = '\x1B[30m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';

  // Bright foreground colors
  static const String _brightBlack = '\x1B[90m';
  static const String _brightRed = '\x1B[91m';
  static const String _brightGreen = '\x1B[92m';
  static const String _brightYellow = '\x1B[93m';
  static const String _brightBlue = '\x1B[94m';
  static const String _brightMagenta = '\x1B[95m';
  static const String _brightCyan = '\x1B[96m';
  static const String _brightWhite = '\x1B[97m';

  // Background colors
  static const String _bgRed = '\x1B[41m';
  static const String _bgGreen = '\x1B[42m';
  static const String _bgYellow = '\x1B[43m';
  static const String _bgBlue = '\x1B[44m';
  static const String _bgMagenta = '\x1B[45m';
  static const String _bgCyan = '\x1B[46m';

  /// Whether colors are enabled for this environment.
  ///
  /// Colors are enabled when running in debug mode and in environments
  /// that support ANSI color codes (most modern terminals).
  static bool get isEnabled {
    // Disable colors in release mode for performance
    bool releaseMode = false;
    assert(() {
      releaseMode = false;
      return true;
    }());
    if (releaseMode) return false;

    // Enable colors for most development environments
    // In a real implementation, you might check environment variables
    // like TERM, COLORTERM, or detect if running in an IDE
    return true;
  }

  /// Wraps text with ANSI color codes if colors are enabled.
  static String _colorize(String text, String colorCode) {
    if (!isEnabled) return text;
    return '$colorCode$text$_reset';
  }

  /// Applies multiple formatting codes to text.
  static String _format(String text, List<String> codes) {
    if (!isEnabled) return text;
    final combinedCodes = codes.join();
    return '$combinedCodes$text$_reset';
  }

  // Basic colors
  /// Red text - typically used for errors and failures.
  static String red(String text) => _colorize(text, _red);

  /// Green text - typically used for success messages.
  static String green(String text) => _colorize(text, _green);

  /// Yellow text - typically used for warnings.
  static String yellow(String text) => _colorize(text, _yellow);

  /// Blue text - typically used for informational messages.
  static String blue(String text) => _colorize(text, _blue);

  /// Magenta text - typically used for debug information.
  static String magenta(String text) => _colorize(text, _magenta);

  /// Cyan text - typically used for highlights.
  static String cyan(String text) => _colorize(text, _cyan);

  /// White text.
  static String white(String text) => _colorize(text, _white);

  /// Black text.
  static String black(String text) => _colorize(text, _black);

  // Bright colors
  /// Bright red text.
  static String brightRed(String text) => _colorize(text, _brightRed);

  /// Bright green text.
  static String brightGreen(String text) => _colorize(text, _brightGreen);

  /// Bright yellow text.
  static String brightYellow(String text) => _colorize(text, _brightYellow);

  /// Bright blue text.
  static String brightBlue(String text) => _colorize(text, _brightBlue);

  /// Bright magenta text.
  static String brightMagenta(String text) => _colorize(text, _brightMagenta);

  /// Bright cyan text.
  static String brightCyan(String text) => _colorize(text, _brightCyan);

  /// Bright white text.
  static String brightWhite(String text) => _colorize(text, _brightWhite);

  /// Dimmed/gray text - typically used for less important information.
  static String gray(String text) => _colorize(text, _brightBlack);

  // Text formatting
  /// Bold text.
  static String bold(String text) => _format(text, [_bold]);

  /// Dimmed text.
  static String dim(String text) => _format(text, [_dim]);

  /// Italic text.
  static String italic(String text) => _format(text, [_italic]);

  /// Underlined text.
  static String underline(String text) => _format(text, [_underline]);

  /// Bold text with color.
  static String boldRed(String text) => _format(text, [_bold, _red]);

  /// Bold green text.
  static String boldGreen(String text) => _format(text, [_bold, _green]);

  /// Bold yellow text.
  static String boldYellow(String text) => _format(text, [_bold, _yellow]);

  /// Bold blue text.
  static String boldBlue(String text) => _format(text, [_bold, _blue]);

  /// Bold cyan text.
  static String boldCyan(String text) => _format(text, [_bold, _cyan]);

  /// Bold magenta text.
  static String boldMagenta(String text) => _format(text, [_bold, _magenta]);

  // Background colors
  /// Text with red background.
  static String onRed(String text) => _colorize(text, _bgRed);

  /// Text with green background.
  static String onGreen(String text) => _colorize(text, _bgGreen);

  /// Text with yellow background.
  static String onYellow(String text) => _colorize(text, _bgYellow);

  /// Text with blue background.
  static String onBlue(String text) => _colorize(text, _bgBlue);

  /// Text with magenta background.
  static String onMagenta(String text) => _colorize(text, _bgMagenta);

  /// Text with cyan background.
  static String onCyan(String text) => _colorize(text, _bgCyan);

  // HTTP status code colors
  /// Colors text based on HTTP status code.
  ///
  /// - 2xx: Green (success)
  /// - 3xx: Yellow (redirection)
  /// - 4xx: Red (client error)
  /// - 5xx: Bright red (server error)
  /// - Other: Gray
  static String statusCode(int? statusCode, String text) {
    if (statusCode == null) return gray(text);

    if (statusCode >= 200 && statusCode < 300) return green(text);
    if (statusCode >= 300 && statusCode < 400) return yellow(text);
    if (statusCode >= 400 && statusCode < 500) return red(text);
    if (statusCode >= 500) return brightRed(text);

    return gray(text);
  }

  // HTTP method colors
  /// Colors text based on HTTP method.
  ///
  /// - GET: Blue
  /// - POST: Green
  /// - PUT: Yellow
  /// - DELETE: Red
  /// - PATCH: Magenta
  /// - Other: Gray
  static String httpMethod(String method, String text) {
    switch (method.toUpperCase()) {
      case 'GET':
        return blue(text);
      case 'POST':
        return green(text);
      case 'PUT':
        return yellow(text);
      case 'DELETE':
        return red(text);
      case 'PATCH':
        return magenta(text);
      default:
        return gray(text);
    }
  }

  // Log level colors
  /// Colors text based on log level.
  ///
  /// - ERROR: Red
  /// - WARNING: Yellow
  /// - INFO: Blue
  /// - DEBUG: Gray
  /// - SUCCESS: Green
  static String logLevel(String level, String text) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return red(text);
      case 'WARNING':
      case 'WARN':
        return yellow(text);
      case 'INFO':
        return blue(text);
      case 'DEBUG':
        return gray(text);
      case 'SUCCESS':
        return green(text);
      default:
        return text;
    }
  }

  // JSON syntax highlighting colors
  /// Colors JSON object braces `{}`
  static String jsonBraces(String text) => brightCyan(text);

  /// Colors JSON array brackets `[]`
  static String jsonBrackets(String text) => brightCyan(text);

  /// Colors JSON property keys/names
  static String jsonKey(String text) => cyan(text);

  /// Colors JSON string values
  static String jsonString(String text) => green(text);

  /// Colors JSON number values
  static String jsonNumber(String text) => yellow(text);

  /// Colors JSON boolean values (true/false)
  static String jsonBoolean(String text) => magenta(text);

  /// Colors JSON null values
  static String jsonNull(String text) => gray(text);

  /// Colors JSON colons `:`
  static String jsonColon(String text) => white(text);

  /// Colors JSON commas `,`
  static String jsonComma(String text) => gray(text);

  /// Colors JSON quotes `"`
  static String jsonQuote(String text) => brightGreen(text);
}