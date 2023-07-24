import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'ayat.dart';
import 'page_constants.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'ayah_offsets.dart';
import 'settings.dart';
import 'surahs.dart';

class MutashabihasPage extends StatelessWidget {
  const MutashabihasPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final NavigatorState nav = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mutashabihas By Para"),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: 30,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Para ${index + 1}"),
            onTap: () {
              Navigator.of(context)
                  .pushNamed(paraMutashabihasPage, arguments: index);
            },
          );
        },
      ),
    );
  }
}

class MutashabihaAyat extends Ayat {
  final int paraIdx;
  final int surahIdx;
  final int ayahIdx;
  MutashabihaAyat(this.paraIdx, this.surahIdx, this.ayahIdx, super.text);
}

class Mutashabiha {
  final MutashabihaAyat src;
  final List<MutashabihaAyat> matches;
  Mutashabiha(this.src, this.matches);
}

MutashabihaAyat _ayatFromJsonObj(dynamic m, final ByteBuffer quranTextUtf8) {
  try {
    final int ayahIdx = m["ayah"];
    final int surahIdx = m["sIdx"];
    final int paraIdx = m["pIdx"];
    final ayahRange = getAyahRange(ayahIdx);
    final textUtf8 = quranTextUtf8.asUint8List(ayahRange.start, ayahRange.len);
    String text = utf8.decode(textUtf8);
    int surahAyah = toSurahAyahOffset(surahIdx, ayahIdx);
    // print("ayahRange: ${ayahRange.start}, ${ayahRange.len}, $text");
    return MutashabihaAyat(paraIdx, surahIdx, surahAyah, text);
  } catch (e) {
    print(e);
    rethrow;
  }
}

class AyatListItemWithMetadata extends StatelessWidget {
  final MutashabihaAyat _ayah;
  final VoidCallback? onTap;
  final Widget? leading;
  const AyatListItemWithMetadata(this._ayah,
      {this.onTap, this.leading, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        _ayah.text,
        softWrap: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: Settings.instance.fontSize.toDouble(),
            letterSpacing: 0.0,
            wordSpacing: Settings.instance.wordSpacing.toDouble()),
      ),
      subtitle: Text(
          "${surahNameForIdx(_ayah.surahIdx)}:${_ayah.ayahIdx + 1} - Para: ${_ayah.paraIdx + 1}"),
      onTap: onTap,
    );
  }
}

class MutashabihaAyatListItem extends StatelessWidget {
  final Mutashabiha mutashabiha;
  final ValueNotifier<bool> _showMatches = ValueNotifier(false);
  MutashabihaAyatListItem({super.key, required this.mutashabiha});

  void _onTap() {
    _showMatches.value = !_showMatches.value;
  }

  Widget _buildMatches(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border.all(color: Colors.red, width: 1),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor,
              blurRadius: 4,
              offset: const Offset(4, 2)),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (ctx, index) => const Divider(height: 1),
        itemCount: mutashabiha.matches.length,
        itemBuilder: (ctx, index) {
          return AyatListItemWithMetadata(mutashabiha.matches[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AyatListItemWithMetadata(
          mutashabiha.src,
          onTap: _onTap,
          leading: ValueListenableBuilder(
            valueListenable: _showMatches,
            builder: (ctx, value, _) {
              return Icon(value ? Icons.expand_more : Icons.chevron_right);
            },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _showMatches,
          builder: (ctx, value, _) {
            if (!value) {
              return const SizedBox.shrink();
            }
            return _buildMatches(Theme.of(context));
          },
        )
      ],
    );
  }
}

class ParaMutashabihas extends StatelessWidget {
  final int _para;
  const ParaMutashabihas(this._para, {super.key});

  Future<List<Mutashabiha>> _importParaMutashabihas() async {
    final mutashabihasJson =
        await rootBundle.loadString("assets/mutashabiha_data.json");
    final map = jsonDecode(mutashabihasJson) as Map<String, dynamic>;
    int paraNum = _para + 1;
    final list = map[paraNum.toString()] as List<dynamic>;

    List<Mutashabiha> mutashabihas = [];
    final ByteData data = await rootBundle.load("assets/quran.txt");
    for (final m in list) {
      MutashabihaAyat src = _ayatFromJsonObj(m["src"], data.buffer);
      List<MutashabihaAyat> matches = [];
      for (final match in m["muts"]) {
        matches.add(_ayatFromJsonObj(match, data.buffer));
      }
      mutashabihas.add(Mutashabiha(src, matches));
    }
    return mutashabihas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mutashabihas for Para ${_para + 1}")),
      body: FutureBuilder(
        future: _importParaMutashabihas(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          } else if (data.isEmpty) {
            return const SizedBox.shrink();
          }
          return ListView.separated(
            separatorBuilder: (ctx, index) => const Divider(height: 1),
            itemCount: data.length,
            itemBuilder: (ctx, index) {
              return MutashabihaAyatListItem(mutashabiha: data[index]);
            },
          );
        },
      ),
    );
  }
}
