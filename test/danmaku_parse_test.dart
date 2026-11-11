import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/models/film_models.dart';

void main() {
  test('parses server-normalized danmaku item', () {
    final c = DanmakuComment.tryParse({'text': ' 前方高能 ', 'time': 12.5, 'color': '#ff0000', 'mode': 1, 'border': true})!;
    expect(c.text, '前方高能');
    expect(c.time, 12.5);
    expect(c.color, '#FF0000');
    expect(c.mode, 1);
    expect(c.border, isTrue);
  });

  test('tolerates string numbers, raw bilibili modes and decimal colors', () {
    final top = DanmakuComment.tryParse({'text': 'a', 'time': '3.2', 'color': 16711680, 'mode': '5'})!;
    expect(top.time, closeTo(3.2, 1e-9));
    expect(top.color, '#FF0000');
    expect(top.mode, 1);
    expect(top.border, isFalse);

    final bottom = DanmakuComment.tryParse({'text': 'b', 'time': 1, 'color': '65280', 'mode': 4})!;
    expect(bottom.mode, 2);
    expect(bottom.color, '#00FF00');

    expect(DanmakuComment.tryParse({'text': 'c', 'time': 0, 'mode': 2})!.mode, 2);
    expect(DanmakuComment.tryParse({'text': 'd', 'time': 0, 'mode': 3})!.mode, 0);
  });

  test('normalizes color variants', () {
    expect(DanmakuComment.normalizeColor('#fff'), '#FFFFFF');
    expect(DanmakuComment.normalizeColor('#80ff8800'), '#FF8800');
    expect(DanmakuComment.normalizeColor('0x00ff00'), '#00FF00');
    expect(DanmakuComment.normalizeColor('not-a-color'), '#FFFFFF');
    expect(DanmakuComment.normalizeColor(null), '#FFFFFF');
  });

  test('skips invalid rows instead of throwing', () {
    expect(DanmakuComment.tryParse({'text': '', 'time': 1}), isNull);
    expect(DanmakuComment.tryParse({'text': 'x', 'time': 'abc'}), isNull);
    expect(DanmakuComment.tryParse({'text': 'x'}), isNull);
  });
}
