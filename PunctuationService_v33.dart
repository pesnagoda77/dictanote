import 'package:flutter/foundation.dart';

class PunctuationService {
  // PUNCT_TEST marker — проверка свежего кода
  static String addPunctuationToText(String text) {
    if (text == 'PUNCT_TEST') return 'PUNCT_TEST_v33';
    if (text.isEmpty) return text;

    // Разбиваем на слова
    List<String> words = text.split(' ');
    if (words.isEmpty) return text;

    List<String> result = [];
    int wordCount = 0;
    bool newSentence = true;

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isEmpty) continue;

      // Очистка от пунктуации в конце
      String cleanedWord = _cleanTrailingPunctuation(word);
      
      // Проверяем, есть ли уже пунктуация в конце слова
      bool hasEndingPunctuation = _hasEndingPunctuation(word);
      
      // Если есть пунктуация — сбрасываем счётчик и начинаем новое предложение
      if (hasEndingPunctuation) {
        wordCount = 0;
        newSentence = true;
        result.add(word);
        continue;
      }

      // Проверяем, можно ли ставить точку после этого слова
      bool isNoBreakWord = cleanedWord.isNotEmpty && _isNoBreakWord(cleanedWord);
      bool isShortWord = cleanedWord.length < 3 && !_isExceptionShortWord(cleanedWord);
      bool isNumber = _isNumber(cleanedWord);
      
      // Следующее слово для проверки
      String? nextWord = (i + 1 < words.length) ? words[i + 1] : null;
      String? nextCleaned = nextWord != null ? _cleanTrailingPunctuation(nextWord) : null;
      bool nextIsNoBreak = nextCleaned != null && _isNoBreakWord(nextCleaned);

      wordCount++;

      // Условия для постановки точки:
      // 1. 8+ слов в предложении
      // 2. Слово не в списке noBreakWords
      // 3. Слово не короткое (< 3 букв)
      // 4. Слово не число
      // 5. Следующее слово не в noBreakWords (не разрываем перед предлогом/союзом)
      // 6. Слово заканчивается на гласную или согласную подходящую для конца предложения
      if (wordCount >= 8 && 
          !isNoBreakWord && 
          !isShortWord && 
          !isNumber &&
          !nextIsNoBreak &&
          _isSentenceEndingWord(cleanedWord)) {
        
        // Заглавная буква в начале
        String punctuatedWord = newSentence ? _capitalize(word) : word;
        punctuatedWord += '.';
        result.add(punctuatedWord);
        
        wordCount = 0;
        newSentence = true;
      } else {
        // Заглавная буква в начале предложения
        String processedWord = newSentence ? _capitalize(word) : word;
        result.add(processedWord);
        newSentence = false;
      }
    }

    return result.join(' ');
  }

  // Очистка пунктуации в конце слова — без RegExp
  static String _cleanTrailingPunctuation(String word) {
    if (word.isEmpty) return word;
    
    String result = word;
    // Убираем точки, запятые, вопросы, восклицания, двоеточия, точки с запятой, тире, многоточия
    List<String> endings = ['.', ',', '?', '!', ':', ';', '-', '—', '…', '...'];
    
    bool changed = true;
    while (changed && result.isNotEmpty) {
      changed = false;
      for (String ending in endings) {
        if (result.endsWith(ending)) {
          result = result.substring(0, result.length - ending.length);
          changed = true;
          break;
        }
      }
    }
    
    return result;
  }

  // Проверка, есть ли пунктуация в конце
  static bool _hasEndingPunctuation(String word) {
    if (word.isEmpty) return false;
    List<String> endings = ['.', '?', '!', ';', ':', '…', '...'];
    for (String ending in endings) {
      if (word.endsWith(ending)) return true;
    }
    return false;
  }

  // Проверка, является ли слово словом-исключением (не ставить точку после)
  static bool _isNoBreakWord(String word) {
    String lower = word.toLowerCase();
    
    // Предлоги
    List<String> prepositions = [
      'в', 'на', 'за', 'под', 'над', 'при', 'про', 'до', 'от', 'по', 'со', 'из', 
      'без', 'к', 'о', 'об', 'через', 'после', 'между', 'около', 'для', 'во', 'ко',
      'обо', 'подо', 'перед', 'передо', 'возле', 'посреди', 'внутри', 'внутрь',
      'вне', 'сверх', 'снизу', 'спереди', 'сзади', 'вдоль', 'поперек', 'вопреки',
      'благодаря', 'согласно', 'вследствие', 'ввиду', 'вплоть', 'вроде', 'вместо',
      'включая', 'исключая', 'касаемо', 'кроме', 'мимо', 'навстречу', 'наподобие',
      'пас', 'подле', 'подобно', 'подпирая', 'поперек', 'посередине', 'посредством',
      'путем', 'ради', 'сверх', 'середи', 'следом', 'смотря', 'согласно', 'спустя',
      'среди', 'сродни', 'стосовательно', 'супротив', 'типа', 'у', 'чрез'
    ];
    
    // Союзы
    List<String> conjunctions = [
      'и', 'а', 'но', 'или', 'что', 'чтобы', 'если', 'когда', 'где', 'куда',
      'пока', 'хотя', 'потому', 'так', 'как', 'ибо', 'да', 'ни', 'не', 'тоже',
      'также', 'либо', 'иначе', 'зато', 'однако', 'вследствие', 'вслед', 'ежели',
      'коли', 'раз', 'ужели', 'хоть', 'бы', 'б', 'же', 'ж', 'ли', 'чтоб'
    ];
    
    // Местоимения
    List<String> pronouns = [
      'я', 'ты', 'он', 'она', 'мы', 'вы', 'они', 'мне', 'тебе', 'ему', 'ей',
      'нам', 'вам', 'им', 'его', 'её', 'их', 'мой', 'твой', 'свой', 'наш',
      'ваш', 'кто', 'что', 'какой', 'который', 'чей', 'сколько', 'каков',
      'каковой', 'каковский', 'некто', 'нечто', 'некоторый', 'некий', 'кое-кто',
      'кое-что', 'кое-какой', 'никто', 'ничто', 'никакой', 'ничей', 'некого',
      'нечего', 'незачем', 'себя', 'себе', 'собой', 'собою'
    ];
    
    // Частицы
    List<String> particles = [
      'бы', 'б', 'же', 'ж', 'ли', 'вот', 'вон', 'даже', 'именно', 'прямо',
      'подлинно', 'точно', 'ровно', 'примерно', 'почти', 'едва', 'лишь',
      'только', 'исключительно', 'преимущественно', 'главным', 'образом',
      'вообще', 'вобщем', 'действительно', 'наверно', 'наверное', 'пожалуй',
      'конечно', 'разумеется', 'вероятно', 'может', 'должно', 'нужно', 'надо'
    ];
    
    // Числительные (короткие — не заканчивают предложение)
    List<String> numerals = [
      'раз', 'два', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять',
      'десять', 'один', 'одна', 'одно', 'две', 'полтора', 'полторы', 'оба',
      'обе', 'первый', 'второй', 'третий', 'четвертый', 'пятый', 'шестой',
      'седьмой', 'восьмой', 'девятый', 'десятый', 'ноль', 'нуль', 'сто',
      'тысяча', 'миллион', 'миллиард'
    ];
    
    // Вопросительные слова (в начале — вопрос, в середине — не заканчивают)
    List<String> interrogatives = [
      'как', 'что', 'где', 'кто', 'почему', 'зачем', 'когда', 'куда', 'откуда',
      'какой', 'который', 'чей', 'сколько', 'каков', 'каковой'
    ];
    
    // Восклицательные слова
    List<String> exclamations = [
      'ах', 'ох', 'ой', 'ну', 'эх', 'браво', 'ура', 'алло', 'здравствуй',
      'здравствуйте', 'привет', 'пока', 'спасибо', 'пожалуйста', 'извините',
      'простите', 'боже', 'господи', 'черт', 'черт возьми', 'десять', 'сто'
    ];
    
    // Сокращения (уже с точкой — не добавлять)
    List<String> abbreviations = [
      'т.д', 'т.е', 'т.к', 'т.н', 'т.о', 'т.п', 'и.т.д', 'и.т.п',
      'др', 'пр', 'г', 'гг', 'ул', 'кв', 'кв.м', 'кв.м.', 'см', 'мм',
      'см.', 'мм.', 'руб', 'руб.', 'долл', 'долл.', 'ед', 'ед.',
      'ст', 'ст.', 'стр', 'стр.', 'гл', 'гл.', 'рис', 'рис.', 'таб',
      'таб.', 'прим', 'прим.', 'см', 'см.', 'им', 'им.', 'д.р', 'д.р.',
      'н.э', 'н.э.', 'до.н.э', 'до.н.э.', 'в.в', 'в.в.', 'век',
      'века', 'вв', 'вв.', 'мин', 'мин.', 'сек', 'сек.', 'час', 'ч.',
      'м', 'м.', 'км', 'км.', 'кг', 'кг.', 'г', 'г.', 'мг', 'мг.'
    ];
    
    // Проверяем все списки
    if (prepositions.contains(lower)) return true;
    if (conjunctions.contains(lower)) return true;
    if (pronouns.contains(lower)) return true;
    if (particles.contains(lower)) return true;
    if (numerals.contains(lower)) return true;
    if (interrogatives.contains(lower)) return true;
    if (exclamations.contains(lower)) return true;
    if (abbreviations.contains(lower)) return true;
    
    return false;
  }

  // Исключения для коротких слов (он, мы, вы — могут заканчивать предложение)
  static bool _isExceptionShortWord(String word) {
    String lower = word.toLowerCase();
    return ['он', 'мы', 'вы'].contains(lower);
  }

  // Проверка, является ли слово числом
  static bool _isNumber(String word) {
    if (word.isEmpty) return false;
    
    // Проверяем, все ли символы — цифры
    for (int i = 0; i < word.length; i++) {
      String char = word[i];
      if (char != '0' && char != '1' && char != '2' && char != '3' && 
          char != '4' && char != '5' && char != '6' && char != '7' && 
          char != '8' && char != '9') {
        return false;
      }
    }
    return word.isNotEmpty;
  }

  // Проверка, подходит ли слово для конца предложения (заканчивается на гласную или подходящую согласную)
  static bool _isSentenceEndingWord(String word) {
    if (word.isEmpty) return false;
    
    String lastChar = word[word.length - 1].toLowerCase();
    
    // Гласные — хорошо заканчивают предложение
    List<String> vowels = ['а', 'о', 'е', 'и', 'у', 'ы', 'э', 'ю', 'я', 'ё'];
    if (vowels.contains(lastChar)) return true;
    
    // Некоторые согласные тоже подходят
    List<String> goodEndings = ['н', 'р', 'с', 'т', 'л', 'в', 'м', 'к', 'д', 'п'];
    if (goodEndings.contains(lastChar)) return true;
    
    return false;
  }

  // Заглавная буква
  static String _capitalize(String word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1);
  }
}
