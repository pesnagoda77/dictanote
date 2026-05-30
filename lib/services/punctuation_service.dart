import 'dart:math';

/// Сервис пунктуации для DictaPro
/// Разбивает текст на предложения по паузам и добавляет пунктуацию
class PunctuationService {
  
  // Минимальная пауза между предложениями (в секундах)
  static const double SENTENCE_PAUSE_THRESHOLD = 0.8;
  
  // Минимальная длина предложения (в словах)
  static const int MIN_SENTENCE_WORDS = 3;
  
  // Максимальная длина предложения (в словах)
  static const int MAX_SENTENCE_WORDS = 15;
  
  // Слова-маркеры конца предложения
  static final Set<String> END_MARKERS = {
    'и', 'а', 'но', 'или', 'потом', 'затем', 'тогда', 'поэтому',
    'однако', 'значит', 'итак', 'вообще', 'короче', 'кстати',
    'например', 'во-первых', 'во-вторых', 'в-третьих',
    'следовательно', 'значит', 'итого', 'вывод',
  };
  
  // Вопросительные слова
  static final Set<String> QUESTION_WORDS = {
    'что', 'кто', 'как', 'где', 'когда', 'почему', 'зачем',
    'какой', 'какая', 'какие', 'который', 'сколько', 'чей',
    'правда', 'верно', 'не так ли', 'ты думаешь',
  };
  
  /// Добавляет пунктуацию в распознанный текст
  /// 
  /// [words] - список слов с таймингами: [(word, startTime, endTime), ...]
  /// Возвращает текст с пунктуацией
  static String addPunctuation(List<(String, double, double)> words) {
    if (words.isEmpty) return '';
    
    List<List<(String, double, double)>> sentences = _splitIntoSentences(words);
    
    StringBuffer result = StringBuffer();
    
    for (int i = 0; i < sentences.length; i++) {
      var sentence = sentences[i];
      if (sentence.isEmpty) continue;
      
      // Собираем текст предложения
      String sentenceText = sentence.map((w) => w.$1).join(' ');
      
      // Определяем тип предложения
      bool isQuestion = _isQuestion(sentenceText);
      bool isExclamation = _isExclamation(sentenceText);
      
      // Добавляем заглавную букву
      sentenceText = _capitalizeFirst(sentenceText);
      
      // Добавляем знак препинания в конце
      if (isQuestion) {
        sentenceText = _ensurePunctuation(sentenceText, '?');
      } else if (isExclamation) {
        sentenceText = _ensurePunctuation(sentenceText, '!');
      } else {
        sentenceText = _ensurePunctuation(sentenceText, '.');
      }
      
      // Добавляем пробел между предложениями
      if (result.isNotEmpty) {
        result.write(' ');
      }
      result.write(sentenceText);
    }
    
    return result.toString();
  }
  
  /// Разбивает слова на предложения по паузам и длине
  static List<List<(String, double, double)>> _splitIntoSentences(
    List<(String, double, double)> words
  ) {
    List<List<(String, double, double)>> sentences = [];
    List<(String, double, double)> currentSentence = [];
    
    for (int i = 0; i < words.length; i++) {
      var current = words[i];
      currentSentence.add(current);
      
      // Проверяем, нужно ли разбить после этого слова
      bool shouldSplit = false;
      
      if (i < words.length - 1) {
        var next = words[i + 1];
        double pause = next.$2 - current.$3; // пауза между словами
        
        // Разбиваем по паузе
        if (pause >= SENTENCE_PAUSE_THRESHOLD) {
          shouldSplit = true;
        }
        
        // Разбиваем по маркеру + пауза
        if (END_MARKERS.contains(current.$1.toLowerCase()) && pause >= 0.3) {
          shouldSplit = true;
        }
        
        // Разбиваем если предложение уже длинное
        if (currentSentence.length >= MAX_SENTENCE_WORDS) {
          shouldSplit = true;
        }
        
        // Не разбиваем если предложение слишком короткое
        if (currentSentence.length < MIN_SENTENCE_WORDS) {
          shouldSplit = false;
        }
      }
      
      if (shouldSplit || i == words.length - 1) {
        sentences.add(List.from(currentSentence));
        currentSentence = [];
      }
    }
    
    // Если остались слова
    if (currentSentence.isNotEmpty) {
      sentences.add(currentSentence);
    }
    
    return sentences;
  }
  
  /// Проверяет, является ли предложение вопросительным
  static bool _isQuestion(String text) {
    String lower = text.toLowerCase();
    
    // Проверяем вопросительные слова в начале
    for (var word in QUESTION_WORDS) {
      if (lower.startsWith(word + ' ')) return true;
    }
    
    // Проверяем интонацию (если есть данные)
    // Пока просто по словам
    
    return false;
  }
  
  /// Проверяет, является ли предложение восклицательным
  static bool _isExclamation(String text) {
    String lower = text.toLowerCase();
    
    // Слова-маркеры восклицания
    Set<String> exclamationMarkers = {
      'вау', 'ого', 'ух ты', 'невероятно', 'потрясающе',
      'внимание', 'стоп', 'хватит', 'браво', 'ура',
    };
    
    for (var marker in exclamationMarkers) {
      if (lower.contains(marker)) return true;
    }
    
    return false;
  }
  
  /// Делает первую букву заглавной
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  /// Добавляет знак препинания в конец, если его нет
  static String _ensurePunctuation(String text, String punctuation) {
    if (text.isEmpty) return text;
    
    // Убираем существующую пунктуацию в конце
    while (text.endsWith('.') || text.endsWith('?') || text.endsWith('!') || 
           text.endsWith(',') || text.endsWith(';') || text.endsWith(':')) {
      text = text.substring(0, text.length - 1);
    }
    
    // Добавляем новую
    return text + punctuation;
  }
  
  /// Упрощённый метод: добавляет пунктуацию в текст без таймингов
  /// Использует эвристики по длине и маркерам
  static String addPunctuationSimple(String text) {
    if (text.isEmpty) return text;
    
    // Разбиваем на слова
    List<String> words = text.split(' ');
    
    // Создаём фиктивные тайминги
    List<(String, double, double)> wordsWithTimings = [];
    double time = 0.0;
    
    for (var word in words) {
      double duration = 0.3 + word.length * 0.05; // примерная длительность
      wordsWithTimings.add((word, time, time + duration));
      time += duration + 0.2; // пауза между словами
    }
    
    return addPunctuation(wordsWithTimings);
  }
}
