import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/utils/filter_params.dart';

void main() {
  test('v3 lowercase echo updates the v2 chip key and does not keep both', () {
    final selected = {'Category': '9', 'category': '9'};
    final next = FilterParams.applyEcho(
      selected,
      ['pid', 'category', 'plot', 'area', 'language', 'year', 'sort'],
      ['2', '14', '', '', '', '', ''],
    );
    expect(next, {'Category': '14'});
    expect(FilterParams.fold(next).keys, ['Category']);
  });

  test('chip key wins over a stale lowercase alias', () {
    final folded = FilterParams.fold({
      'category': '9',
      'Category': '14',
      'Plot': '喜剧',
    });
    expect(folded, {'Category': '14', 'Plot': '喜剧'});
  });

  test('empty echo clears that dimension', () {
    final next = FilterParams.applyEcho(
      {'Category': '14', 'Plot': '喜剧'},
      ['Category', 'Plot'],
      ['', '喜剧'],
    );
    expect(next, {'Plot': '喜剧'});
  });
}
