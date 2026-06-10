/// Converts Uzbek Latin text to Cyrillic.
/// Multi-character combinations are handled before single characters.
String latinToCyrillic(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  int i = 0;

  while (i < input.length) {
    final ch = input[i];
    final next = i + 1 < input.length ? input[i + 1] : '';
    final pair = ch + next;

    // ── Two-character combinations ──────────────────────────────────────────
    // sh / Sh / SH
    if (pair == 'sh') { buffer.write('ш'); i += 2; continue; }
    if (pair == 'Sh') { buffer.write('Ш'); i += 2; continue; }
    if (pair == 'SH') { buffer.write('Ш'); i += 2; continue; }

    // ch / Ch / CH
    if (pair == 'ch') { buffer.write('ч'); i += 2; continue; }
    if (pair == 'Ch') { buffer.write('Ч'); i += 2; continue; }
    if (pair == 'CH') { buffer.write('Ч'); i += 2; continue; }

    // ng / Ng / NG
    if (pair == 'ng') { buffer.write('нг'); i += 2; continue; }
    if (pair == 'Ng') { buffer.write('Нг'); i += 2; continue; }
    if (pair == 'NG') { buffer.write('НГ'); i += 2; continue; }

    // gh / Gh / GH
    if (pair == 'gh') { buffer.write('ғ'); i += 2; continue; }
    if (pair == 'Gh') { buffer.write('Ғ'); i += 2; continue; }
    if (pair == 'GH') { buffer.write('Ғ'); i += 2; continue; }

    // ts / Ts / TS — keep as тс
    if (pair == 'ts') { buffer.write('тс'); i += 2; continue; }
    if (pair == 'Ts') { buffer.write('Тс'); i += 2; continue; }
    if (pair == 'TS') { buffer.write('ТС'); i += 2; continue; }

    // o' / o' / oʻ  (various apostrophe variants)
    if (ch == 'o' && _isApostrophe(next)) { buffer.write('ў'); i += 2; continue; }
    if (ch == 'O' && _isApostrophe(next)) { buffer.write('Ў'); i += 2; continue; }

    // g' / gʻ
    if (ch == 'g' && _isApostrophe(next)) { buffer.write('ғ'); i += 2; continue; }
    if (ch == 'G' && _isApostrophe(next)) { buffer.write('Ғ'); i += 2; continue; }

    // ── Single characters ───────────────────────────────────────────────────
    buffer.write(_singleChar(ch));
    i++;
  }

  return buffer.toString();
}

bool _isApostrophe(String ch) =>
    ch == "'" || ch == '‘' || ch == '’' || ch == 'ʻ';

String _singleChar(String ch) {
  switch (ch) {
    case 'a': return 'а';
    case 'A': return 'А';
    case 'b': return 'б';
    case 'B': return 'Б';
    case 'd': return 'д';
    case 'D': return 'Д';
    case 'e': return 'е';
    case 'E': return 'Е';
    case 'f': return 'ф';
    case 'F': return 'Ф';
    case 'g': return 'г';
    case 'G': return 'Г';
    case 'h': return 'х';
    case 'H': return 'Х';
    case 'i': return 'и';
    case 'I': return 'И';
    case 'j': return 'ж';
    case 'J': return 'Ж';
    case 'k': return 'к';
    case 'K': return 'К';
    case 'l': return 'л';
    case 'L': return 'Л';
    case 'm': return 'м';
    case 'M': return 'М';
    case 'n': return 'н';
    case 'N': return 'Н';
    case 'o': return 'о';
    case 'O': return 'О';
    case 'p': return 'п';
    case 'P': return 'П';
    case 'q': return 'қ';
    case 'Q': return 'Қ';
    case 'r': return 'р';
    case 'R': return 'Р';
    case 's': return 'с';
    case 'S': return 'С';
    case 't': return 'т';
    case 'T': return 'Т';
    case 'u': return 'у';
    case 'U': return 'У';
    case 'v': return 'в';
    case 'V': return 'В';
    case 'x': return 'х';
    case 'X': return 'Х';
    case 'y': return 'й';
    case 'Y': return 'Й';
    case 'z': return 'з';
    case 'Z': return 'З';
    default: return ch;
  }
}
