import 'dart:math';

/// Сервис саммаризации для DictaPro
/// Создаёт структурированное саммари по шаблонам
class SummaryService {
  
  // Типы текстов
  static const String TYPE_BUSINESS = 'business';
  static const String TYPE_LECTURE = 'lecture';
  static const String TYPE_INTERVIEW = 'interview';
  static const String TYPE_NOTES = 'notes';
  static const String TYPE_GENERAL = 'general';
  
  // Маркеры типов текстов
  static final Map<String, List<String>> TYPE_MARKERS = {
    TYPE_BUSINESS: [
      'встреча', 'согласовали', 'договорились', 'цена', 'стоимость',
      'бюджет', 'заказчик', 'клиент', 'договор', 'сделка',
      'оплата', 'оплатить', 'заплатить', 'рубл', 'доллар',
      'срок', 'дедлайн', 'до какого числа', 'когда',
      'контакт', 'телефон', 'email', 'почта', 'звонить',
      'решили', 'итог', 'договоренность',
    ],
    TYPE_LECTURE: [
      'лекция', 'тема', 'предмет', 'профессор', 'преподаватель',
      'студент', 'экзамен', 'зачет', 'контрольная',
      'теория', 'определение', 'понятие', 'закон', 'формула',
      'вопрос', 'ответ', 'тезис', 'гипотеза',
      'во-первых', 'во-вторых', 'в-третьих', 'итак', 'следовательно',
    ],
    TYPE_INTERVIEW: [
      'интервью', 'вопрос', 'ответ', 'расскажите', 'как вы',
      'почему', 'зачем', 'каким образом', 'что вы думаете',
      'опыт', 'работали', 'проект', 'достижения',
      'кандидат', 'собеседование', 'вакансия', 'резюме',
    ],
    TYPE_NOTES: [
      'идея', 'задача', 'надо', 'нужно', 'сделать',
      'купить', 'позвонить', 'написать', 'встретиться',
      'запомнить', 'не забыть', 'важно', 'срочно',
      'завтра', 'послезавтра', 'на неделе', 'в понедельник',
    ],
  };
  
  /// Создаёт саммари из текста
  /// 
  /// [text] - распознанный текст с пунктуацией
  /// Возвращает структурированное саммари
  static SummaryResult summarize(String text) {
    if (text.isEmpty) {
      return SummaryResult(
        type: TYPE_GENERAL,
        title: 'Пустая запись',
        sections: [],
        actionItems: [],
      );
    }
    
    // Определяем тип текста
    String type = _detectType(text);
    
    // Разбиваем на предложения
    List<String> sentences = _splitIntoSentences(text);
    
    // Извлекаем ключевые данные
    List<String> dates = _extractDates(text);
    List<String> amounts = _extractAmounts(text);
    List<String> contacts = _extractContacts(text);
    List<String> names = _extractNames(text);
    
    // Создаём секции по типу
    List<SummarySection> sections = _createSections(type, sentences, text);
    
    // Извлекаем экшн-айтемы
    List<String> actionItems = _extractActionItems(sentences);
    
    // Создаём заголовок
    String title = _createTitle(type, sentences, text);
    
    return SummaryResult(
      type: type,
      title: title,
      sections: sections,
      actionItems: actionItems,
      metadata: {
        'dates': dates,
        'amounts': amounts,
        'contacts': contacts,
        'names': names,
        'sentenceCount': sentences.length,
      },
    );
  }
  
  /// Определяет тип текста по маркерам
  static String _detectType(String text) {
    String lower = text.toLowerCase();
    Map<String, int> scores = {};
    
    for (var entry in TYPE_MARKERS.entries) {
      int score = 0;
      for (var marker in entry.value) {
        if (lower.contains(marker)) {
          score++;
        }
      }
      scores[entry.key] = score;
    }
    
    // Находим тип с максимальным счётом
    String bestType = TYPE_GENERAL;
    int bestScore = 0;
    
    for (var entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestType = entry.key;
      }
    }
    
    // Если счёт слишком мал — общий тип
    if (bestScore < 2) {
      return TYPE_GENERAL;
    }
    
    return bestType;
  }
  
  /// Разбивает текст на предложения
  static List<String> _splitIntoSentences(String text) {
    // Разбиваем по точкам, вопросительным и восклицательным знакам
    List<String> sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    return sentences;
  }
  
  /// Извлекает даты из текста
  static List<String> _extractDates(String text) {
    List<String> dates = [];
    
    // Паттерны дат
    List<RegExp> patterns = [
      RegExp(r'\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b'), // 15.06.2024
      RegExp(r'\b\d{1,2}\s+(января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)\b'),
      RegExp(r'\b(завтра|послезавтра|сегодня|вчера)\b'),
      RegExp(r'\b(в\s+понедельник|в\s+вторник|в\s+среду|в\s+четверг|в\s+пятницу|в\s+субботу|в\s+воскресенье)\b'),
      RegExp(r'\b(до\s+\d{1,2}[./]\d{1,2}|к\s+\d{1,2}[./]\d{1,2})\b'),
    ];
    
    for (var pattern in patterns) {
      for (var match in pattern.allMatches(text)) {
        dates.add(match.group(0)!);
      }
    }
    
    return dates.toSet().toList(); // убираем дубликаты
  }
  
  /// Извлекает суммы/цены из текста
  static List<String> _extractAmounts(String text) {
    List<String> amounts = [];
    
    // Паттерны сумм
    List<RegExp> patterns = [
      RegExp(r'\b\d+[\s\u00A0]?\d*\s*(руб|рубл|₽|р\b)\.?'),
      RegExp(r'\b\d+[\s\u00A0]?\d*\s*(usd|\$|доллар)\.?'),
      RegExp(r'\b\d+[\s\u00A0]?\d*\s*(евро|€)\.?'),
      RegExp(r'\b\d+[\s\u00A0]?\d*\s*(тыс|тысяч|млн|миллион)\.?'),
      RegExp(r'\b(цена|стоимость|бюджет|сумма)\s*:?\s*\d+[\s\u00A0]?\d*'),
    ];
    
    for (var pattern in patterns) {
      for (var match in pattern.allMatches(text.toLowerCase())) {
        amounts.add(match.group(0)!);
      }
    }
    
    return amounts.toSet().toList();
  }
  
  /// Извлекает контакты из текста
  static List<String> _extractContacts(String text) {
    List<String> contacts = [];
    
    // Телефоны
    RegExp phonePattern = RegExp(
      r'\+?7[\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}'
    );
    for (var match in phonePattern.allMatches(text)) {
      contacts.add('📞 ' + match.group(0)!);
    }
    
    // Email
    RegExp emailPattern = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    );
    for (var match in emailPattern.allMatches(text)) {
      contacts.add('📧 ' + match.group(0)!);
    }
    
    // Telegram
    RegExp tgPattern = RegExp(r'@\w+');
    for (var match in tgPattern.allMatches(text)) {
      contacts.add('💬 ' + match.group(0)!);
    }
    
    return contacts.toSet().toList();
  }
  
  /// Извлекает имена (заглавные буквы в середине)
  static List<String> _extractNames(String text) {
    List<String> names = [];
    
    // Ищем заглавные буквы в середине текста (вероятно, имена)
    RegExp namePattern = RegExp(r'\b[А-ЯЁ][а-яё]+\s+[А-ЯЁ][а-яё]+\b');
    for (var match in namePattern.allMatches(text)) {
      String name = match.group(0)!;
      // Исключаем общеупотребительные слова
      if (!_isCommonWord(name)) {
        names.add(name);
      }
    }
    
    return names.toSet().toList();
  }
  
  /// Проверяет, является ли слово общеупотребительным
  static bool _isCommonWord(String word) {
    Set<String> commonWords = {
      'Россия', 'Москва', 'Петербург', 'Русский', 'Английский',
      'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница',
      'Суббота', 'Воскресенье', 'Январь', 'Февраль', 'Март',
    };
    return commonWords.contains(word);
  }
  
  /// Создаёт секции саммари по типу текста
  static List<SummarySection> _createSections(
    String type,
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    switch (type) {
      case TYPE_BUSINESS:
        sections = _createBusinessSections(sentences, fullText);
        break;
      case TYPE_LECTURE:
        sections = _createLectureSections(sentences, fullText);
        break;
      case TYPE_INTERVIEW:
        sections = _createInterviewSections(sentences, fullText);
        break;
      case TYPE_NOTES:
        sections = _createNotesSections(sentences, fullText);
        break;
      default:
        sections = _createGeneralSections(sentences, fullText);
    }
    
    return sections;
  }
  
  /// Секции для бизнес-встречи
  static List<SummarySection> _createBusinessSections(
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    // Участники
    List<String> names = _extractNames(fullText);
    if (names.isNotEmpty) {
      sections.add(SummarySection(
        title: '👥 Участники',
        items: names,
        icon: 'people',
      ));
    }
    
    // Решения
    List<String> decisions = sentences
        .where((s) => 
          s.toLowerCase().contains('согласовали') ||
          s.toLowerCase().contains('решили') ||
          s.toLowerCase().contains('договорились') ||
          s.toLowerCase().contains('утвердили')
        )
        .toList();
    if (decisions.isNotEmpty) {
      sections.add(SummarySection(
        title: '✅ Решения',
        items: decisions,
        icon: 'check',
      ));
    }
    
    // Финансы
    List<String> amounts = _extractAmounts(fullText);
    if (amounts.isNotEmpty) {
      sections.add(SummarySection(
        title: '💰 Финансы',
        items: amounts,
        icon: 'money',
      ));
    }
    
    // Сроки
    List<String> dates = _extractDates(fullText);
    if (dates.isNotEmpty) {
      sections.add(SummarySection(
        title: '📅 Сроки',
        items: dates,
        icon: 'calendar',
      ));
    }
    
    // Контакты
    List<String> contacts = _extractContacts(fullText);
    if (contacts.isNotEmpty) {
      sections.add(SummarySection(
        title: '📞 Контакты',
        items: contacts,
        icon: 'contact',
      ));
    }
    
    return sections;
  }
  
  /// Секции для лекции
  static List<SummarySection> _createLectureSections(
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    // Тема (первое предложение или предложение с "тема")
    String? topic = sentences.firstWhere(
      (s) => s.toLowerCase().contains('тема') || s.toLowerCase().contains('лекция'),
      orElse: () => sentences.isNotEmpty ? sentences.first : '',
    );
    if (topic.isNotEmpty) {
      sections.add(SummarySection(
        title: '📚 Тема',
        items: [topic],
        icon: 'book',
      ));
    }
    
    // Ключевые понятия (предложения с "это", "называется", "определяется")
    List<String> concepts = sentences
        .where((s) => 
          s.toLowerCase().contains('это') ||
          s.toLowerCase().contains('называется') ||
          s.toLowerCase().contains('определяется') ||
          s.toLowerCase().contains('понятие')
        )
        .toList();
    if (concepts.isNotEmpty) {
      sections.add(SummarySection(
        title: '💡 Ключевые понятия',
        items: concepts,
        icon: 'lightbulb',
      ));
    }
    
    // Тезисы (предложения с номерами или маркерами)
    List<String> theses = sentences
        .where((s) => 
          s.toLowerCase().contains('во-первых') ||
          s.toLowerCase().contains('во-вторых') ||
          s.toLowerCase().contains('итак') ||
          s.toLowerCase().contains('следовательно') ||
          s.toLowerCase().contains('таким образом')
        )
        .toList();
    if (theses.isNotEmpty) {
      sections.add(SummarySection(
        title: '📝 Тезисы',
        items: theses,
        icon: 'notes',
      ));
    }
    
    return sections;
  }
  
  /// Секции для интервью
  static List<SummarySection> _createInterviewSections(
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    // Вопросы (предложения с вопросительными словами)
    List<String> questions = sentences
        .where((s) => 
          s.toLowerCase().contains('?') ||
          s.toLowerCase().startsWith('как') ||
          s.toLowerCase().startsWith('что') ||
          s.toLowerCase().startsWith('почему') ||
          s.toLowerCase().startsWith('зачем')
        )
        .toList();
    if (questions.isNotEmpty) {
      sections.add(SummarySection(
        title: '❓ Вопросы',
        items: questions,
        icon: 'question',
      ));
    }
    
    // Инсайты (неожиданные ответы, опыт)
    List<String> insights = sentences
        .where((s) => 
          s.toLowerCase().contains('опыт') ||
          s.toLowerCase().contains('считаю') ||
          s.toLowerCase().contains('думаю') ||
          s.toLowerCase().contains('верю') ||
          s.toLowerCase().contains('важно')
        )
        .toList();
    if (insights.isNotEmpty) {
      sections.add(SummarySection(
        title: '💡 Инсайты',
        items: insights,
        icon: 'insight',
      ));
    }
    
    return sections;
  }
  
  /// Секции для личных заметок
  static List<SummarySection> _createNotesSections(
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    // Идеи (предложения с "идея", "можно", "стоит")
    List<String> ideas = sentences
        .where((s) => 
          s.toLowerCase().contains('идея') ||
          s.toLowerCase().contains('можно') ||
          s.toLowerCase().contains('стоит') ||
          s.toLowerCase().contains('хорошо бы')
        )
        .toList();
    if (ideas.isNotEmpty) {
      sections.add(SummarySection(
        title: '💡 Идеи',
        items: ideas,
        icon: 'idea',
      ));
    }
    
    // Задачи (предложения с "надо", "нужно", "сделать")
    List<String> tasks = sentences
        .where((s) => 
          s.toLowerCase().contains('надо') ||
          s.toLowerCase().contains('нужно') ||
          s.toLowerCase().contains('сделать') ||
          s.toLowerCase().contains('купить') ||
          s.toLowerCase().contains('позвонить') ||
          s.toLowerCase().contains('написать')
        )
        .toList();
    if (tasks.isNotEmpty) {
      sections.add(SummarySection(
        title: '☐ Задачи',
        items: tasks,
        icon: 'task',
      ));
    }
    
    // Даты
    List<String> dates = _extractDates(fullText);
    if (dates.isNotEmpty) {
      sections.add(SummarySection(
        title: '📅 Даты',
        items: dates,
        icon: 'calendar',
      ));
    }
    
    return sections;
  }
  
  /// Секции для общего текста
  static List<SummarySection> _createGeneralSections(
    List<String> sentences,
    String fullText,
  ) {
    List<SummarySection> sections = [];
    
    // Главная мысль (первое и последнее предложение часто главные)
    List<String> keyPoints = [];
    if (sentences.isNotEmpty) {
      keyPoints.add(sentences.first);
    }
    if (sentences.length > 2) {
      keyPoints.add(sentences.last);
    }
    
    // Добавляем предложения с маркерами важности
    List<String> important = sentences
        .where((s) => 
          s.toLowerCase().contains('важно') ||
          s.toLowerCase().contains('главное') ||
          s.toLowerCase().contains('итог') ||
          s.toLowerCase().contains('вывод') ||
          s.toLowerCase().contains('суть')
        )
        .toList();
    keyPoints.addAll(important);
    
    if (keyPoints.isNotEmpty) {
      sections.add(SummarySection(
        title: '📝 Ключевые мысли',
        items: keyPoints.toSet().toList(),
        icon: 'key',
      ));
    }
    
    return sections;
  }
  
  /// Извлекает экшн-айтемы из предложений
  static List<String> _extractActionItems(List<String> sentences) {
    List<String> actions = [];
    
    for (var sentence in sentences) {
      String lower = sentence.toLowerCase();
      
      // Маркеры действий
      if (lower.contains('надо') ||
          lower.contains('нужно') ||
          lower.contains('сделать') ||
          lower.contains('купить') ||
          lower.contains('позвонить') ||
          lower.contains('написать') ||
          lower.contains('встретиться') ||
          lower.contains('отправить') ||
          lower.contains('проверить') ||
          lower.contains('заказать') ||
          lower.contains('оплатить')) {
        actions.add('☐ ' + sentence);
      }
    }
    
    return actions;
  }
  
  /// Создаёт заголовок для саммари
  static String _createTitle(String type, List<String> sentences, String fullText) {
    if (sentences.isEmpty) return 'Запись';
    
    // Для бизнеса — первое предложение часто тема
    if (type == TYPE_BUSINESS) {
      String first = sentences.first;
      if (first.length > 50) {
        first = first.substring(0, 50) + '...';
      }
      return '🤝 ' + first;
    }
    
    // Для лекции — ищем слово "тема"
    if (type == TYPE_LECTURE) {
      for (var sentence in sentences) {
        if (sentence.toLowerCase().contains('тема')) {
          return '📚 ' + sentence;
        }
      }
      return '📚 ' + sentences.first;
    }
    
    // Для интервью
    if (type == TYPE_INTERVIEW) {
      return '🎤 Интервью: ' + sentences.first;
    }
    
    // Для заметок
    if (type == TYPE_NOTES) {
      return '📝 Заметки: ' + sentences.first;
    }
    
    // Общий случай
    String first = sentences.first;
    if (first.length > 60) {
      first = first.substring(0, 60) + '...';
    }
    return '📝 ' + first;
  }
  
  /// Форматирует саммари для отображения
  static String formatSummary(SummaryResult summary) {
    StringBuffer buffer = StringBuffer();
    
    // Заголовок
    buffer.writeln('╔══════════════════════════════════════╗');
    buffer.writeln('║  📋 САММАРИ                          ║');
    buffer.writeln('╚══════════════════════════════════════╝');
    buffer.writeln();
    
    // Тип
    String typeEmoji = _getTypeEmoji(summary.type);
    buffer.writeln('$typeEmoji ${summary.title}');
    buffer.writeln();
    
    // Секции
    for (var section in summary.sections) {
      buffer.writeln('┌─ ${section.title} ─────────────────────┐');
      for (var item in section.items) {
        // Обрезаем длинные строки
        String display = item;
        if (display.length > 50) {
          display = display.substring(0, 50) + '...';
        }
        buffer.writeln('│ • $display');
      }
      buffer.writeln('└──────────────────────────────────────┘');
      buffer.writeln();
    }
    
    // Экшн-айтемы
    if (summary.actionItems.isNotEmpty) {
      buffer.writeln('┌─ ⚡ ЭКШН-АЙТЕМЫ ───────────────────┐');
      for (var item in summary.actionItems) {
        String display = item;
        if (display.length > 50) {
          display = display.substring(0, 50) + '...';
        }
        buffer.writeln('│ $display');
      }
      buffer.writeln('└──────────────────────────────────────┘');
      buffer.writeln();
    }
    
    // Метаданные
    if (summary.metadata != null) {
      var dates = summary.metadata!['dates'] as List<String>?;
      var amounts = summary.metadata!['amounts'] as List<String>?;
      var contacts = summary.metadata!['contacts'] as List<String>?;
      
      if ((dates != null && dates.isNotEmpty) ||
          (amounts != null && amounts.isNotEmpty) ||
          (contacts != null && contacts.isNotEmpty)) {
        buffer.writeln('┌─ 📊 ДАННЫЕ ──────────────────────────┐');
        if (dates != null && dates.isNotEmpty) {
          buffer.writeln('│ 📅 ${dates.join(", ")}');
        }
        if (amounts != null && amounts.isNotEmpty) {
          buffer.writeln('│ 💰 ${amounts.join(", ")}');
        }
        if (contacts != null && contacts.isNotEmpty) {
          buffer.writeln('│ 📞 ${contacts.join(", ")}');
        }
        buffer.writeln('└──────────────────────────────────────┘');
      }
    }
    
    return buffer.toString();
  }
  
  /// Возвращает эмодзи для типа текста
  static String _getTypeEmoji(String type) {
    switch (type) {
      case TYPE_BUSINESS:
        return '🤝';
      case TYPE_LECTURE:
        return '📚';
      case TYPE_INTERVIEW:
        return '🎤';
      case TYPE_NOTES:
        return '📝';
      default:
        return '📄';
    }
  }
}

/// Результат саммаризации
class SummaryResult {
  final String type;
  final String title;
  final List<SummarySection> sections;
  final List<String> actionItems;
  final Map<String, dynamic>? metadata;
  
  SummaryResult({
    required this.type,
    required this.title,
    required this.sections,
    required this.actionItems,
    this.metadata,
  });
}

/// Секция саммари
class SummarySection {
  final String title;
  final List<String> items;
  final String icon;
  
  SummarySection({
    required this.title,
    required this.items,
    required this.icon,
  });
}
