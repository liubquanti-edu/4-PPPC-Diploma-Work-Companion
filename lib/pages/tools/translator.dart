//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'dart:async';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _translator = GoogleTranslator();
  final _textController = TextEditingController();
  String _translatedText = '';
  String _fromLanguage = 'uk';
  String _toLanguage = 'en';
  Timer? _debounce;

  final Map<String, String> _languages = {
    'uk': 'Українська',
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'pl': 'Polski',
    'pt': 'Português',
    'ru': 'Русский',
    'ja': '日本語',
    'ko': '한국어',
    'zh-cn': '中文 (简体)',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'tr': 'Türkçe',
  };

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      _translateText();
    });
  }

  void _translateText() async {
    if (_textController.text.isEmpty) return;

    setState(() {
    });

    try {
      final translation = await _translator.translate(
        _textController.text,
        from: _fromLanguage,
        to: _toLanguage,
      );

      setState(() {
        _translatedText = translation.text;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка перекладу: $e')),
        );
      }
    } finally {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Перекладач'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Текст...',
                    border: InputBorder.none,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(fontSize: 25),
                  textAlign: TextAlign.left,
                  ),
                  if (_textController.text.isNotEmpty)
                  const Divider(),
                  if (_translatedText.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                    _translatedText,
                    style: TextStyle(
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                      Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        icon: const SizedBox.shrink(),
                        alignment: Alignment.center,
                        value: _fromLanguage,
                        items: _languages.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                        }).toList(),
                        onChanged: (value) {
                        setState(() {
                          _fromLanguage = value!;
                          _translatedText = '';
                          if (_fromLanguage == _toLanguage) {
                          _toLanguage = _fromLanguage == 'uk' ? 'en' : 'uk';
                          }
                          if (_textController.text.isNotEmpty) {
                          _translateText();
                          }
                        });
                        },
                        underline: Container(),
                      ),
                      ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      setState(() {
                        final temp = _fromLanguage;
                        _fromLanguage = _toLanguage;
                        _toLanguage = temp;
                        _translatedText = '';
                        if (_textController.text.isNotEmpty) {
                          _translateText();
                        }
                      });
                    },
                  ),
                    Container(
                      decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                      icon: const SizedBox.shrink(),
                      alignment: Alignment.center,
                    value: _toLanguage,
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                      _toLanguage = value!;
                      _translatedText = '';
                      if (_fromLanguage == _toLanguage) {
                        _fromLanguage = _toLanguage == 'uk' ? 'en' : 'uk';
                      }
                      if (_textController.text.isNotEmpty) {
                        _translateText();
                      }
                      });
                    },
                    underline: Container(),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }
}