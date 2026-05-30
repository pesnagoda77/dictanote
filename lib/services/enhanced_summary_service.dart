import 'dart:convert';
import 'package:intl/intl.dart';

/// Улучшенный сервис саммаризации для DictaPro
/// Rule-based с извлечением ключевых данных
class EnhancedSummaryService {
  
  /// Главный метод — генерирует структурированное саммари
  static Map<String, dynamic> generateSummary(String text) {
    if (text.isEmpty) {
      return {
        'type': 'empty',
        'title': 'Нет текста',
        'content': [],
        'actionItems': [],
        'contacts': [],
        'dates': [],
        'amounts': [],
      };
    }
    
    // Определяем тип текста
    final type = _detectType(text);
    
    // Извлекаем ключевые данные
    final contacts = _extractContacts(text);
    final dates = _extractDates(text);
    final amounts = _extractAmounts(text);
    final actionItems = _extractActionItems(text);
    
    // Формируем структуру по типу
    switch (type) {
      case 'business':
        return _generateBusinessSummary(text, contacts, dates, amounts, actionItems);
      case 'lecture':
        return _generateLectureSummary(text, dates, actionItems);
      case 'interview':
        return _generateInterviewSummary(text, contacts, dates, actionItems);
      case 'personal':
        return _generatePersonalSummary(text, dates, amounts, actionItems);
      default:
        return _generateGeneralSummary(text, contacts, dates, amounts, actionItems);
    }
  }
  
  /// Определение типа текста по маркерам
  static String _detectType(String text) {
    final lower = text.toLowerCase();
    
    // Бизнес-маркеры
    final businessMarkers = [
      'встреча', 'договор', 'согласовали', 'цена', 'стоимость', 'оплата',
      'заказ', 'клиент', 'заказчик', 'партнёр', 'сделка', 'бюджет',
      'контракт', 'соглашение', 'переговоры', 'бизнес', 'компания',
      'рублей', 'руб', '₽', 'usd', 'евро', 'доллар'
    ];
    
    // Лекция-маркеры
    final lectureMarkers = [
      'лекция', 'лектор', 'профессор', 'тема', 'вопрос', 'экзамен',
      'студент', 'университет', 'курс', 'дисциплина', 'наука',
      'теория', 'метод', 'практика', 'задача', 'решение'
    ];
    
    // Интервью-маркеры
    final interviewMarkers = [
      'интервью', 'вопрос', 'ответ', 'респондент', 'эксперт',
      'редактор', 'журналист', 'опрос', 'анкета', 'мнение'
    ];
    
    // Личные заметки-маркеры
    final personalMarkers = [
      'идея', 'задача', 'купить', 'позвонить', 'написать',
      'встретиться', 'не забыть', 'напомнить', 'личное',
      'дом', 'семья', 'дети', 'план', 'цель'
    ];
    
    int businessScore = 0;
    int lectureScore = 0;
    int interviewScore = 0;
    int personalScore = 0;
    
    for (final marker in businessMarkers) {
      if (lower.contains(marker)) businessScore++;
    }
    for (final marker in lectureMarkers) {
      if (lower.contains(marker)) lectureScore++;
    }
    for (final marker in interviewMarkers) {
      if (lower.contains(marker)) interviewScore++;
    }
    for (final marker in personalMarkers) {
      if (lower.contains(marker)) personalScore++;
    }
    
    final scores = {
      'business': businessScore,
      'lecture': lectureScore,
      'interview': interviewScore,
      'personal': personalScore,
    };
    
    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    
    if (maxScore == 0) return 'general';
    
    return scores.entries.firstWhere((e) => e.value == maxScore).key;
  }
  
  /// Извлечение контактов (телефоны, email, Telegram)
  static List<String> _extractContacts(String text) {
    final contacts = <String>[];
    
    // Телефоны: +7, 8, и т.д.
    final phoneRegex = RegExp(r'[\+]?[7-8][\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{2}[\s\-]?\d{2}');
    contacts.addAll(phoneRegex.allMatches(text).map((m) => m.group(0)!));
    
    // Email
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    contacts.addAll(emailRegex.allMatches(text).map((m) => m.group(0)!));
    
    // Telegram (@username)
    final tgRegex = RegExp(r'@[a-zA-Z0-9_]{5,32}');
    contacts.addAll(tgRegex.allMatches(text).map((m) => m.group(0)!));
    
    return contacts.toSet().toList(); // уникальные
  }
  
  /// Извлечение дат
  static List<String> _extractDates(String text) {
    final dates = <String>[];
    
    // Форматы: 15.06.2024, 15 июня, 15.06, и т.д.
    final dateRegex = RegExp(
      r'\b(\d{1,2}[\.\/]\d{1,2}[\.\/]?\d{0,4}|\d{1,2}\s+(января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)(\s+\d{4})?)\b',
      caseSensitive: false,
    );
    dates.addAll(dateRegex.allMatches(text).map((m) => m.group(0)!));
    
    // Относительные даты
    final relativeDates = ['сегодня', 'завтра', 'послезавтра', 'на следующей неделе', 'в понедельник', 'во вторник', 'в среду', 'в четверг', 'в пятницу', 'в субботу', 'в воскресенье'];
    final lower = text.toLowerCase();
    for (final date in relativeDates) {
      if (lower.contains(date)) dates.add(date);
    }
    
    return dates.toSet().toList();
  }
  
  /// Извлечение сумм и цен
  static List<String> _extractAmounts(String text) {
    final amounts = <String>[];
    
    // Суммы: 5000 рублей, 1500 ₽, $100, 1000 руб.
    final amountRegex = RegExp(
      r'\b(\d+[\s\.]?\d*)\s*(рублей|руб|₽|usd|\$|евро|€|eur)\b',
      caseSensitive: false,
    );
    amounts.addAll(amountRegex.allMatches(text).map((m) => m.group(0)!));
    
    return amounts.toSet().toList();
  }
  
  /// Извлечение экшн-айтемов
  static List<String> _extractActionItems(String text) {
    final actions = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));
    
    final actionMarkers = [
      'надо', 'нужно', 'необходимо', 'следует', 'стоит',
      'купить', 'позвонить', 'написать', 'отправить', 'сделать',
      'встретиться', 'договориться', 'подготовить', 'проверить',
      'заказать', 'оплатить', 'перевести', 'согласовать',
      'не забыть', 'напомнить', 'запланировать'
    ];
    
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase().trim();
      if (lower.isEmpty) continue;
      
      for (final marker in actionMarkers) {
        if (lower.contains(marker)) {
          actions.add(sentence.trim());
          break;
        }
      }
    }
    
    return actions.take(5).toList(); // максимум 5
  }
  
  /// Извлечение ключевых предложений (TextRank-like)
  static List<String> _extractKeySentences(String text, int count) {
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().length > 10).toList();
    if (sentences.isEmpty) return [];
    
    // Простая эвристика: первое и последнее предложение + самые длинные
    final keySentences = <String>[];
    
    if (sentences.isNotEmpty) keySentences.add(sentences.first.trim());
    if (sentences.length > 1) keySentences.add(sentences.last.trim());
    
    // Добавляем предложения с ключевыми словами
    final keywords = ['важно', 'итак', 'поэтому', 'результат', 'вывод', 'значит', 'следовательно', 'итого', 'в итоге'];
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      for (final keyword in keywords) {
        if (lower.contains(keyword) && !keySentences.contains(sentence.trim())) {
          keySentences.add(sentence.trim());
          break;
        }
      }
    }
    
    return keySentences.take(count).toList();
  }
  
  /// Генерация саммари для бизнес-встречи
  static Map<String, dynamic> _generateBusinessSummary(
    String text,
    List<String> contacts,
    List<String> dates,
    List<String> amounts,
    List<String> actionItems,
  ) {
    final keySentences = _extractKeySentences(text, 3);
    
    return {
      'type': 'business',
      'typeLabel': 'Бизнес-встреча',
      'icon': '💼',
      'color': '#4A90E2',
      'title': keySentences.isNotEmpty ? keySentences.first : 'Бизнес-встреча',
      'sections': [
        {
          'title': 'Темы',
          'icon': '📋',
          'items': keySentences,
        },
        if (amounts.isNotEmpty)
          {
            'title': 'Финансы',
            'icon': '💰',
            'items': amounts,
          },
        if (dates.isNotEmpty)
          {
            'title': 'Сроки',
            'icon': '📅',
            'items': dates,
          },
        if (contacts.isNotEmpty)
          {
            'title': 'Контакты',
            'icon': '📞',
            'items': contacts,
          },
        if (actionItems.isNotEmpty)
          {
            'title': 'Экшн-айтемы',
            'icon': '☐',
            'items': actionItems,
          },
      ],
      'contacts': contacts,
      'dates': dates,
      'amounts': amounts,
      'actionItems': actionItems,
    };
  }
  
  /// Генерация саммари для лекции
  static Map<String, dynamic> _generateLectureSummary(
    String text,
    List<String> dates,
    List<String> actionItems,
  ) {
    final keySentences = _extractKeySentences(text, 5);
    
    // Ищем определения (слово "это", "называется", "определяется")
    final definitions = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      if (lower.contains('это') || lower.contains('называется') || lower.contains('определяется')) {
        definitions.add(sentence.trim());
      }
    }
    
    return {
      'type': 'lecture',
      'typeLabel': 'Лекция',
      'icon': '🎓',
      'color': '#9B59B6',
      'title': keySentences.isNotEmpty ? keySentences.first : 'Лекция',
      'sections': [
        {
          'title': 'Тема',
          'icon': '📚',
          'items': keySentences.take(1).toList(),
        },
        if (definitions.isNotEmpty)
          {
            'title': 'Определения',
            'icon': '📝',
            'items': definitions.take(3).toList(),
          },
        {
          'title': 'Ключевые тезисы',
          'icon': '💡',
          'items': keySentences.skip(1).take(3).toList(),
        },
        if (actionItems.isNotEmpty)
          {
            'title': 'Вопросы / Задания',
            'icon': '❓',
            'items': actionItems,
          },
      ],
      'dates': dates,
      'actionItems': actionItems,
    };
  }
  
  /// Генерация саммари для интервью
  static Map<String, dynamic> _generateInterviewSummary(
    String text,
    List<String> contacts,
    List<String> dates,
    List<String> actionItems,
  ) {
    final keySentences = _extractKeySentences(text, 4);
    
    // Ищем вопросы
    final questions = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.endsWith('?') || trimmed.toLowerCase().startsWith('вопрос')) {
        questions.add(trimmed);
      }
    }
    
    return {
      'type': 'interview',
      'typeLabel': 'Интервью',
      'icon': '🎤',
      'color': '#E74C3C',
      'title': keySentences.isNotEmpty ? keySentences.first : 'Интервью',
      'sections': [
        if (questions.isNotEmpty)
          {
            'title': 'Вопросы',
            'icon': '❓',
            'items': questions.take(3).toList(),
          },
        {
          'title': 'Инсайты',
          'icon': '💎',
          'items': keySentences.take(3).toList(),
        },
        if (contacts.isNotEmpty)
          {
            'title': 'Контакты',
            'icon': '📞',
            'items': contacts,
          },
        if (actionItems.isNotEmpty)
          {
            'title': 'Следующие шаги',
            'icon': '☐',
            'items': actionItems,
          },
      ],
      'contacts': contacts,
      'dates': dates,
      'actionItems': actionItems,
    };
  }
  
  /// Генерация саммари для личных заметок
  static Map<String, dynamic> _generatePersonalSummary(
    String text,
    List<String> dates,
    List<String> amounts,
    List<String> actionItems,
  ) {
    final keySentences = _extractKeySentences(text, 3);
    
    // Ищем идеи (если есть)
    final ideas = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));
    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      if (lower.contains('идея') || lower.contains('можно') || lower.contains('стоит попробовать')) {
        ideas.add(sentence.trim());
      }
    }
    
    return {
      'type': 'personal',
      'typeLabel': 'Личные заметки',
      'icon': '📌',
      'color': '#2ECC71',
      'title': keySentences.isNotEmpty ? keySentences.first : 'Личные заметки',
      'sections': [
        if (ideas.isNotEmpty)
          {
            'title': 'Идеи',
            'icon': '💡',
            'items': ideas.take(3).toList(),
          },
        if (actionItems.isNotEmpty)
          {
            'title': 'Задачи',
            'icon': '☐',
            'items': actionItems,
          },
        if (dates.isNotEmpty)
          {
            'title': 'Даты',
            'icon': '📅',
            'items': dates,
          },
        if (amounts.isNotEmpty)
          {
            'title': 'Покупки / Расходы',
            'icon': '💰',
            'items': amounts,
          },
      ],
      'dates': dates,
      'amounts': amounts,
      'actionItems': actionItems,
    };
  }
  
  /// Генерация общего саммари
  static Map<String, dynamic> _generateGeneralSummary(
    String text,
    List<String> contacts,
    List<String> dates,
    List<String> amounts,
    List<String> actionItems,
  ) {
    final keySentences = _extractKeySentences(text, 5);
    
    return {
      'type': 'general',
      'typeLabel': 'Общая запись',
      'icon': '📝',
      'color': '#95A5A6',
      'title': keySentences.isNotEmpty ? keySentences.first : 'Запись',
      'sections': [
        {
          'title': 'Тема',
          'icon': '📌',
          'items': keySentences.take(1).toList(),
        },
        {
          'title': 'Ключевые мысли',
          'icon': '💡',
          'items': keySentences.skip(1).take(3).toList(),
        },
        if (actionItems.isNotEmpty)
          {
            'title': 'Что сделать',
            'icon': '☐',
            'items': actionItems,
          },
        if (dates.isNotEmpty)
          {
            'title': 'Важные даты',
            'icon': '📅',
            'items': dates,
          },
        if (contacts.isNotEmpty)
          {
            'title': 'Контакты',
            'icon': '📞',
            'items': contacts,
          },
        if (amounts.isNotEmpty)
          {
            'title': 'Суммы',
            'icon': '💰',
            'items': amounts,
          },
      ],
      'contacts': contacts,
      'dates': dates,
      'amounts': amounts,
      'actionItems': actionItems,
    };
  }
  
  /// Форматирование саммари для отображения в UI
  static String formatSummaryForDisplay(Map<String, dynamic> summary) {
    final buffer = StringBuffer();
    
    // Заголовок с бейджем
    buffer.writeln('${summary['icon']} ${summary['typeLabel']}');
    buffer.writeln('═' * 40);
    buffer.writeln();
    
    // Секции
    final sections = summary['sections'] as List<dynamic>? ?? [];
    for (final section in sections) {
      final sectionMap = section as Map<String, dynamic>;
      buffer.writeln('${sectionMap['icon']} ${sectionMap['title']}');
      buffer.writeln('─' * 30);
      
      final items = sectionMap['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        buffer.writeln('• $item');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
