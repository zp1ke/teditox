import 'package:flutter/material.dart';

/// Utility extension to convert file names to appropriate icons.
extension StringToIcon on String {
  /// Converts a file name to an appropriate icon based on its extension.
  IconData get toIcon => _getFileIcon(this);
}

IconData _getFileIcon(String fileName) {
  final extension = fileName.toLowerCase().split('.').lastOrNull ?? '';

  switch (extension) {
    // Code files
    case 'dart':
    case 'java':
    case 'kt':
    case 'swift':
    case 'c':
    case 'cpp':
    case 'h':
    case 'hpp':
    case 'cs':
    case 'py':
    case 'rb':
    case 'go':
    case 'rs':
      return Icons.code;

    // Web files
    case 'html':
    case 'htm':
    case 'css':
    case 'scss':
    case 'sass':
    case 'less':
      return Icons.web;

    case 'js':
    case 'ts':
    case 'jsx':
    case 'tsx':
    case 'vue':
      return Icons.javascript;

    // Data/Config files
    case 'json':
    case 'yaml':
    case 'yml':
    case 'toml':
    case 'ini':
    case 'conf':
    case 'config':
    case 'xml':
      return Icons.settings_applications;

    // Markdown/Documentation
    case 'md':
    case 'markdown':
    case 'rst':
    case 'adoc':
      return Icons.article;

    // Text files
    case 'txt':
    case 'log':
      return Icons.subject;

    // Database
    case 'sql':
    case 'db':
    case 'sqlite':
      return Icons.storage;

    // Shell scripts
    case 'sh':
    case 'bash':
    case 'zsh':
    case 'fish':
    case 'bat':
    case 'cmd':
    case 'ps1':
      return Icons.terminal;

    // Default
    default:
      return Icons.description_outlined;
  }
}
