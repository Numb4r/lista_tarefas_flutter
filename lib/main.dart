import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
//import '';

main(List<String> args) {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(primaryColor: Colors.black, highlightColor: Colors.indigo),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _controladorTarefa = TextEditingController();
  List _todoList = [];
  Map<String, dynamic> _ultimoElementoRemovido;
  int _indiceUltimoElementoRemovido;

  Future<File> _getArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/listafazer.json');
  }

  Future<File> _salvarArquivo() async {
    String dados = json.encode(_todoList);
    final arquivo = await _getArquivo();
    return arquivo.writeAsString(dados);
  }

  Future<String> _lerArquivo() async {
    try {
      final arquivo = await _getArquivo();
      return arquivo.readAsString();
    } catch (ex) {
      return null;
    }
  }

  void _adicionar() {
    setState(() {
      if (_controladorTarefa.text.isNotEmpty) {
        Map<String, dynamic> novoItem = Map();
        novoItem["title"] = _controladorTarefa.text;
        novoItem["ok"] = false;
        _controladorTarefa.text = '';
        _todoList.add(novoItem);
        _salvarArquivo();
      }
    });
  }

  Future<Null> _aoAtualizar() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _salvarArquivo();
    });
    return null;
  }

  Widget construtorItens(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()), //random key
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direcao) {
        setState(() {
          _ultimoElementoRemovido = Map.from(_todoList[index]);
          _indiceUltimoElementoRemovido = index;
          _todoList.removeAt(index);
          _salvarArquivo();
          final alert = SnackBar(
            content: Text(
              "Tarefa \"${_ultimoElementoRemovido['title']}\" removido com sucesso!! ",
            ),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(
                        _indiceUltimoElementoRemovido, _ultimoElementoRemovido);
                    _salvarArquivo();
                  });
                }),
            duration: Duration(seconds: 1),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(alert);
        });
      },
      child: CheckboxListTile(
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        onChanged: (checked) {
          setState(() {
            _todoList[index]["ok"] = checked;
            _salvarArquivo();
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _lerArquivo().then((onValue) {
      setState(() {
        _todoList = jsonDecode(onValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controladorTarefa,
                      decoration: InputDecoration(
                        hintText: "Nova Tarefa",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.plus_one,
                      color: Colors.blue,
                    ),
                    onPressed: _adicionar,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _aoAtualizar,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _todoList.length,
                  itemBuilder: construtorItens,
                ),
              ),
            )
          ],
        ));
  }
}
