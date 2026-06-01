import 'dart:developer' as developer;

/// Сервис пунктуации с учетом "хвостовых слов"
/// Не разрывает предложение после союзов, вводных слов и начальных конструкций
class PunctuationService {
  static const double PAUSE_THRESHOLD = 0.4; // секунды
  static const int MIN_WORDS_PER_SENTENCE = 4;
  
  // Слова, после которых НЕ ставим точку даже при паузе > threshold
  static final Set<String> _tailWords = {
    // Союзы
    'и', 'или', 'но', 'а', 'что', 'когда', 'если', 'потому', 'поэтому',
    'как', 'так', 'чтобы', 'хотя', 'пока', 'после', 'перед', 'будто',
    // Вводные
    'например', 'однако', 'также', 'следовательно', 'во-первых', 'во-вторых',
    'в-третьих', 'наконец', 'кроме', 'более', 'менее', 'между', 'прочим',
    'кстати', 'вообще', 'вероятно', 'видимо', 'очевидно', 'действительно',
    'пожалуй', 'конечно', 'безусловно', 'несомненно', 'возможно',
    // Начальные конструкции
    'можно', 'нужно', 'нельзя', 'будем', 'будет', 'может', 'должны',
    'следует', 'стоит', 'пора', 'пришлось', 'придется',
  };
  
  // Предлоги — если после паузы первое слово предлог, склеиваем
  static final Set<String> _prepositions = {
    'в', 'на', 'с', 'по', 'к', 'у', 'о', 'об', 'от', 'для',
    'за', 'под', 'над', 'при', 'перед', 'через', 'между',
    'из', 'до', 'после', 'без', 'около', 'возле', 'против',
  };
  
  // Союзы с маленькой буквы — тоже склеиваем
  static final Set<String> _lowercaseConjunctions = {
    'и', 'или', 'но', 'а', 'что', 'как', 'так', 'чтобы',
  };

  /// Добавляет пунктуацию в текст на основе таймингов слов
  static String addPunctuation(List<WordTiming> words) {
    if (words.isEmpty) return '';
    
    List<String> sentences = [];
    List<String> currentSentence = [];
    double lastEndTime = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final pause = word.startTime - lastEndTime;
      final wordText = word.text.toLowerCase().trim();
      
      // Проверяем, нужно ли начать новое предложение
      bool shouldBreak = false;
      
      if (pause > PAUSE_THRESHOLD && currentSentence.isNotEmpty) {
        // Проверяем "хвостовое слово" — последнее слово текущего предложения
        final lastWord = currentSentence.last.toLowerCase().trim();
        
        // Не разрываем после хвостовых слов
        if (!_tailWords.contains(lastWord)) {
          // Проверяем следующее слово — если предлог или союз с маленькой, склеиваем
          if (i < words.length - 1) {
            final nextWord = words[i + 1].text.toLowerCase().trim();
            if (!_prepositions.contains(nextWord) && !_lowercaseConjunctions.contains(nextWord)) {
              shouldBreak = true;
            }
          } else {
            shouldBreak = true;
          }
        }
        
        // Минимальная длина предложения
        if (currentSentence.length < MIN_WORDS_PER_SENTENCE) {
          shouldBreak = false;
        }
      }
      
      if (shouldBreak) {
        sentences.add(_finishSentence(currentSentence));
        currentSentence = [];
      }
      
      currentSentence.add(word.text);
      lastEndTime = word.endTime;
    }
    
    // Последнее предложение
    if (currentSentence.isNotEmpty) {
      sentences.add(_finishSentence(currentSentence));
    }
    
    return sentences.join(' ');
  }
  
  /// Завершает предложение: заглавная буква, точка в конце
  static String _finishSentence(List<String> words) {
    if (words.isEmpty) return '';
    
    String text = words.join(' ');
    
    // Заглавная буква в начале
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    
    // Точка в конце, если нет пунктуации
    if (!text.endsWith('.') && !text.endsWith('?') && !text.endsWith('!') && !text.endsWith('...')) {
      text += '.';
    }
    
    return text;
  }
  
  /// Проверяет, достаточно ли длины текста для саммари
  static bool isEnoughForSummary(String text) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return wordCount >= 100;
  }
  
  /// Проверяет, достаточно ли длины аудио для саммари (в секундах)
  static bool isEnoughForSummaryAudio(double durationSeconds) {
    return durationSeconds >= 120; // 2 минуты
  }
}

/// Класс для хранения тайминга слова
class WordTiming {
  final String text;
  final double startTime;
  final double endTime;
  
  WordTiming({
    required this.text,
    required this.startTime,
    required this.endTime,
  });
}
