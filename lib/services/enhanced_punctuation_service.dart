import 'dart:convert';
import 'package:intl/intl.dart';

/// Улучшенный сервис пунктуации для DictaPro
/// Разбивает текст на предложения по паузам и эвристикам
class EnhancedPunctuationService {
  
  /// Главный метод — добавляет пунктуацию в текст
  static String addPunctuation(String text, {List<WordTiming>? timings}) {
    if (text.isEmpty) return text;
    
    // Если есть тайминги — используем их
    if (timings != null && timings.isNotEmpty) {
      return _punctuateWithTimings(text, timings);
    }
    
    // Иначе — эвристика
    return _punctuateWithHeuristics(text);
  }
  
  /// Пунктуация по таймингам (лучший вариант)
  static String _punctuateWithTimings(String text, List<WordTiming> timings) {
    final sentences = <String>[];
    var currentSentence = StringBuffer();
    var lastEndTime = 0.0;
    
    for (var i = 0; i < timings.length; i++) {
      final word = timings[i];
      
      // Пауза > 1 секунды — конец предложения
      if (lastEndTime > 0 && word.startTime - lastEndTime > 1.0) {
        if (currentSentence.isNotEmpty) {
          sentences.add(currentSentence.toString().trim());
          currentSentence = StringBuffer();
        }
      }
      
      // Пауза > 0.5 секунды — возможно запятая (пока просто разделим)
      if (lastEndTime > 0 && word.startTime - lastEndTime > 0.5) {
        // Можно добавить запятую, но пока просто разделим пробелом
      }
      
      currentSentence.write('${word.word} ');
      lastEndTime = word.endTime;
    }
    
    // Добавляем последнее предложение
    if (currentSentence.isNotEmpty) {
      sentences.add(currentSentence.toString().trim());
    }
    
    // Форматируем каждое предложение
    return sentences.map((s) => _formatSentence(s)).join('. ');
  }
  
  /// Пунктуация по эвристикам (fallback)
  static String _punctuateWithHeuristics(String text) {
    // Разбиваем на слова
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return text;
    
    final sentences = <String>[];
    var currentSentence = <String>[];
    var wordCount = 0;
    
    for (var i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.isEmpty) continue;
      
      currentSentence.add(word);
      wordCount++;
      
      // Конец предложения по:
      // 1. Длине (8-15 слов)
      // 2. Союзам/частицам в начале следующего слова
      // 3. Вопросительным/восклицательным словам
      
      final isEndOfSentence = _isEndOfSentence(word, i, words, wordCount);
      
      if (isEndOfSentence && currentSentence.isNotEmpty) {
        sentences.add(currentSentence.join(' '));
        currentSentence = <String>[];
        wordCount = 0;
      }
    }
    
    // Добавляем остаток
    if (currentSentence.isNotEmpty) {
      sentences.add(currentSentence.join(' '));
    }
    
    // Форматируем каждое предложение
    return sentences.map((s) => _formatSentence(s)).join('. ');
  }
  
  /// Проверяет, является ли слово концом предложения
  static bool _isEndOfSentence(String word, int index, List<String> words, int wordCount) {
    // Минимальная длина предложения
    if (wordCount < 5) return false;
    
    // Максимальная длина предложения
    if (wordCount >= 15) return true;
    
    // Союзы/частицы в начале следующего слова — начало нового предложения
    if (index < words.length - 1) {
      final nextWord = words[index + 1].toLowerCase();
      final sentenceStarters = [
        'и', 'а', 'но', 'или', 'потом', 'затем', 'тогда', 'поэтому',
        'однако', 'значит', 'итак', 'следовательно', 'во-первых',
        'во-вторых', 'наконец', 'в общем', 'короче', 'итого',
        'ну', 'так', 'значит', 'слушай', 'смотри', 'вообще',
        'получается', 'типа', 'короче', 'ну', 'ладно', 'давай',
        'таким', 'этим', 'следующим', 'первым', 'вторым', 'третьим'
      ];
      
      for (final starter in sentenceStarters) {
        if (nextWord.startsWith(starter)) return true;
      }
    }
    
    // Вопросительные слова в начале (если длина >= 5)
    final questionWords = ['что', 'кто', 'как', 'почему', 'зачем', 'когда', 'где', 'куда', 'откуда', 'какой', 'который'];
    if (index < words.length - 1) {
      final nextWord = words[index + 1].toLowerCase();
      for (final qw in questionWords) {
        if (nextWord.startsWith(qw) && wordCount >= 5) return true;
      }
    }
    
    // Слова, которые часто заканчивают предложение
    final endingWords = ['всё', 'все', 'окей', 'ок', 'хорошо', 'понятно', 'ясно', 'договорились', 'согласны', 'верно'];
    for (final ew in endingWords) {
      if (word.toLowerCase() == ew && wordCount >= 5) return true;
    }
    
    return false;
  }
  
  /// Форматирует одно предложение
  static String _formatSentence(String sentence) {
    if (sentence.isEmpty) return sentence;
    
    // Убираем лишние пробелы
    sentence = sentence.trim();
    
    // Заглавная буква в начале
    if (sentence.isNotEmpty) {
      sentence = sentence[0].toUpperCase() + sentence.substring(1);
    }
    
    // Убираем точку в конце, если есть (добавим потом)
    if (sentence.endsWith('.') || sentence.endsWith('!') || sentence.endsWith('?')) {
      sentence = sentence.substring(0, sentence.length - 1);
    }
    
    return sentence;
  }
  
  /// Определяет тип предложения (вопрос/восклицание/утверждение)
  static String _detectSentenceType(String sentence) {
    final lower = sentence.toLowerCase().trim();
    
    // Вопросительные слова
    final questionPatterns = [
      'что ', 'кто ', 'как ', 'почему ', 'зачем ', 'когда ', 'где ',
      'куда ', 'откуда ', 'какой ', 'который ', 'сколько ', 'какая ',
      'какое ', 'какие ', 'какие ', 'верно', 'правильно', 'не так ли',
      'ты понял', 'вы поняли', 'понятно', 'ясно'
    ];
    
    for (final pattern in questionPatterns) {
      if (lower.contains(pattern)) return '?';
    }
    
    // Восклицательные слова
    final exclamationPatterns = [
      'вау', 'ого', 'ух ты', 'невероятно', 'круто', 'отлично',
      'здорово', 'прекрасно', 'великолепно', 'восторг'
    ];
    
    for (final pattern in exclamationPatterns) {
      if (lower.contains(pattern)) return '!';
    }
    
    return '.';
  }
  
  /// Добавляет знаки препинания в уже разбитый текст
  static String addFinalPunctuation(String text) {
    if (text.isEmpty) return text;
    
    // Разбиваем на предложения
    final sentences = text.split('. ');
    final result = <String>[];
    
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;
      
      final type = _detectSentenceType(sentence);
      final formatted = _formatSentence(sentence);
      
      if (formatted.isNotEmpty) {
        result.add('$formatted$type');
      }
    }
    
    return result.join(' ');
  }
}

/// Класс для таймингов слов (если VOSK их предоставляет)
class WordTiming {
  final String word;
  final double startTime;
  final double endTime;
  final double confidence;
  
  WordTiming({
    required this.word,
    required this.startTime,
    required this.endTime,
    this.confidence = 1.0,
  });
  
  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] as String,
      startTime: (json['start'] as num).toDouble(),
      endTime: (json['end'] as num).toDouble(),
      confidence: (json['conf'] as num?)?.toDouble() ?? 1.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'start': startTime,
      'end': endTime,
      'conf': confidence,
    };
  }
}
