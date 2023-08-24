import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_and_mutashabiha_list_view.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final ValueNotifier<bool> _multipleSelectMode = ValueNotifier(false);
  final ItemScrollController _drawerItemsScrollController =
      ItemScrollController();

  @override
  void initState() {
    _multipleSelectMode.addListener(() => _paraModel.resetSelection());
    _paraModel.onParaChange = (() => _multipleSelectMode.value = false);

    _paraModel.readJsonDB();
    Settings.instance.readSettings();

    super.initState();
  }

  @override
  void dispose() {
    _paraModel.dispose();
    _multipleSelectMode.dispose();
    super.dispose();
  }

  void _openQuizParaSelectionPage() async {
    final quizCreationArgs = await Navigator.of(context)
        .pushNamed(quizSelectionPage) as QuizCreationArgs?;
    if (!mounted) return;
    if (quizCreationArgs == null) return;
    if (quizCreationArgs.selectedParas.isEmpty) return;
    final ayahsToAdd = await Navigator.of(context).pushNamed(quizPage,
        arguments: quizCreationArgs) as Map<int, List<Ayat>>?;
    if (!mounted) return;
    if (ayahsToAdd == null || ayahsToAdd.isEmpty) return;
    _paraModel.merge(ayahsToAdd);
  }

  void _openSettings() async {
    await Navigator.pushNamed(context, settingsPageRoute,
        arguments: _paraModel);
  }

  void _openMutashabihas() {
    Navigator.pushNamed(context, mutashabihasPage, arguments: _paraModel);
  }

  void _onDeletePress() {
    assert(_multipleSelectMode.value);
    _paraModel.removeSelectedAyahs();
    _multipleSelectMode.value = false;
  }

  void _onExitMultiSelectMode() {
    assert(_multipleSelectMode.value == true);
    _multipleSelectMode.toggle();
  }

  void _readQuran() {
    Navigator.pushNamed(context, readQuranPage, arguments: _paraModel);
  }

  Widget buildThreeDotMenu() {
    final Map<String, VoidCallback> actions = {
      'Take Quiz': _openQuizParaSelectionPage,
      'Mutashabihas': _openMutashabihas,
      'Settings': _openSettings,
    };
    return PopupMenuButton<String>(
      onSelected: (String value) {
        final actionCallback = actions[value];
        if (actionCallback == null) throw "Unknown action: $value";
        actionCallback();
      },
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) {
        return actions.keys.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_multipleSelectMode.value) {
          _multipleSelectMode.value = false;
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: _paraModel.currentParaNotifier,
            builder: (context, value, _) {
              return Text("Para $value");
            },
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _multipleSelectMode,
              builder: (context, value, threeDotMenu) {
                if (value) {
                  return Row(children: [
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _onDeletePress),
                    IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () => _paraModel.selectAll()),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _onExitMultiSelectMode),
                  ]);
                } else {
                  return threeDotMenu!;
                }
              },
              child: Row(children: [
                IconButton(
                  tooltip: "Read para",
                  icon: const Icon(Icons.menu_book),
                  onPressed: _readQuran,
                ),
                buildThreeDotMenu()
              ]),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge(
              [_multipleSelectMode, _paraModel, Settings.instance]),
          builder: (context, child) {
            return AyatAndMutashabihaListView(
              _paraModel.ayahs,
              selectionMode: _multipleSelectMode.value,
              onLongPress: _multipleSelectMode.toggle,
            );
          },
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ScrollablePositionedList.builder(
              itemCount: 30,
              itemScrollController: _drawerItemsScrollController,
              itemBuilder: (context, index) {
                return ListTile(
                  minVerticalPadding: 0,
                  visualDensity: VisualDensity.compact,
                  title: Text("Para ${index + 1}"),
                  onTap: () {
                    _paraModel.setCurrentPara(index + 1);
                    _scaffoldKey.currentState?.closeDrawer();
                  },
                  selected: (_paraModel.currentPara - 1) == index,
                  selectedTileColor: Theme.of(context).highlightColor,
                );
              },
            ),
          ),
        ),
        onDrawerChanged: (opened) {
          if (opened) {
            Future.delayed(const Duration(milliseconds: 150), () {
              _drawerItemsScrollController.jumpTo(
                  index: _paraModel.currentPara - 1, alignment: 0.5);
            });
          }
        },
      ),
    );
  }
}
