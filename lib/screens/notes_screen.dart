import 'package:flutter/material.dart';
import 'package:nextcloud/notes.dart';
import 'package:openflow/services/nextcloud_service.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../theme/styles_app.dart';
import '../widgets/bottom_bar_app.dart';

class NotesScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const NotesScreen({super.key, required this.cuenta});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late NextcloudService nextcloudService;
  List<Note> notes = [];
  String? category;
  Set<String> categorias = {''};
  Map mapCategories = {};
  String dropdownValue = '';
  bool filterFavorites = false;
  bool isLoading = false;
  bool isGridView = false;

  //Map<Note, CloudFile> mapFiles = {};
  int totalNotes = 0;

  //TextEditingController renameController = TextEditingController();

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    initNotes();
    super.initState();
  }

  Future<void> initNotes() async {
    setState(() => isLoading = true);
    final responseNotes = await nextcloudService.getNotas();
    if (responseNotes == null) return;
    final List<Note> myNotes = List.from(responseNotes);
    myNotes.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    List<String> countCategorias = [];
    for (var note in myNotes) {
      if (note.category.isNotEmpty) {
        countCategorias.add(note.category);
        categorias.add(note.category);
      }
    }
    var map = {};
    for (var cat in countCategorias) {
      if (!map.containsKey(cat)) {
        map[cat] = 1;
      } else {
        map[cat] += 1;
      }
    }
    setState(() {
      notes = myNotes;
      mapCategories = map;
      isLoading = false;
    });
  }

  Future<void> onTapNote(Note note) async {}

  Future<void> onTapMore(Note note) async {}

  Future<void> openNote(Note note) async {}

  Future<void> changeFavorite(Note note, bool isFavorite) async {}

  Future<void> newNote() async {}

  Widget filterCategory() {
    return Expanded(
      flex: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          //padding: EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Colors.white30,
              style: BorderStyle.solid,
              width: 0.80,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: dropdownValue,
              //icon: const Icon(Icons.arrow_downward),
              icon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.filter_alt_outlined, size: 32),
              ),
              elevation: 16,
              //style: const TextStyle(color: Colors.blueAccent),
              //underline: Container(height: 2, color: Colors.blueAccent),
              onChanged: (String? value) {
                setState(() {
                  category = value;
                  if (value == null || value.isEmpty) {
                    category = null;
                  }
                  dropdownValue = value!;
                });
              },
              items: categorias
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: FittedBox(
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            CircleAvatar(
                              child: Text(
                                value.isEmpty
                                    ? '$totalNotes'
                                    : '${mapCategories[value]}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(value.isEmpty ? 'All' : value),
                          ],
                        ),
                      ),
                      /*child: value.isEmpty
                          ? Text('All')
                          : FittedBox(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    child: Text('${mapCategories[value]}'),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(value),
                                ],
                              ),
                            ),*/
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StylesApp.backgroundScreen(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.all(4.0),
            /*child: CuentaAvatar(
              cuenta: widget.cuenta,
              size: 30,
              onlyAvatar: true,
            ),*/
            child: widget.cuenta.avatar != null
                ? Image.memory(widget.cuenta.avatar!, height: 30, width: 30)
                : Icon(Icons.person_off, size: 30, color: Colors.grey),
          ),
          title: Text('Notes: ${notes.length}'),
          actions: [
            IconButton(
              tooltip: 'Sort by name',
              onPressed: () {
                setState(() {
                  notes.sort(
                    (a, b) =>
                        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                  );
                });
              },
              icon: Icon(Icons.sort_by_alpha, size: 32, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Sort by date',
              onPressed: () {
                setState(() {
                  notes.sort((a, b) => b.modified.compareTo(a.modified));
                });
              },
              icon: Icon(Icons.date_range, size: 32, color: Colors.white),
            ),
          ],
          bottom: isLoading == false
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Padding(
                    padding: .symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => filterFavorites = !filterFavorites);
                          },
                          icon: Icon(
                            Icons.star,
                            size: 32,
                            color: filterFavorites == true
                                ? Colors.yellow
                                : Colors.grey,
                          ),
                        ),
                        //const SizedBox(width: 10),
                        const Spacer(),
                        filterCategory(),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        bottomNavigationBar: BottomBarApp(
          cuenta: widget.cuenta,
          destino: Destino.notes,
          funcion: newNote,
          //cancelToken: nextcloudApi.cancelToken,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : notes.isEmpty
            ? Center(child: Text('Sin notas'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: .fromLTRB(4, 4, 4, 60),
                    itemCount: notes.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: Colors.white54,
                        thickness: 0.2,
                        indent: 20,
                        endIndent: 20,
                      );
                    },
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return ListTile(
                        leading: IconButton(
                          onPressed: () {
                            changeFavorite(note, !note.favorite);
                          },
                          icon: Icon(
                            Icons.star,
                            color: note.favorite == true
                                ? Colors.yellow
                                : Colors.grey,
                            size: 42,
                          ),
                        ),
                        title: Text(note.title),
                        subtitle: note.category.isNotEmpty
                            ? Text(note.category)
                            : null,
                        trailing: IconButton(
                          onPressed: () => onTapMore(
                            note,
                            //context: context,
                            //note: note,
                            //path: path,
                          ),
                          icon: Icon(Icons.more_vert),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
