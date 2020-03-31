import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:new_coronavirus/components/row_text.dart';
import 'package:new_coronavirus/models/DataGroup.dart';
import 'package:new_coronavirus/models/National.dart';
import 'package:new_coronavirus/models/Regional.dart';
import 'package:new_coronavirus/models/ResponseStatus.dart';
import 'package:new_coronavirus/network/HomeNetwork/HomeNetwork.dart';
import 'package:new_coronavirus/redux/actions/DataActions.dart';
import 'package:new_coronavirus/redux/store/AppState.dart';
import 'package:http/http.dart' as http;
import 'package:new_coronavirus/screens/HomePage/components/LabelWithData.dart';
import 'package:redux/redux.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<bool> futureSuccess;

  Future<bool> getTotalData(Store<AppState> store) async {
    bool totalSuccess = true;
    int i = 0;
    http.Client client = http.Client();

    List<ResponseStatus> list = await Future.wait([
      HomeNetwork.getNationalData(client),
      HomeNetwork.getRegionalData(client),
    ]);

    client.close();

    while (i < list.length && totalSuccess) {
      if (!list[i].success) totalSuccess = false;
      i++;
    }

    if (totalSuccess) {
      DataGroup dataGroup = DataGroup(
        national: list[0].data,
        regional: list[1].data,
      );
      store.dispatch(SaveData(dataGroup));
    }

    return totalSuccess;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ITALIA 🇮🇹"),
      ),
      body: StoreConnector<AppState, AppState>(
        onInit: (store) => futureSuccess = getTotalData(store),
        converter: (store) => store.state,
        builder: (context, state) {
          return FutureBuilder(
            future: futureSuccess,
            builder: (_, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return Center(child: CircularProgressIndicator());

              if (!snapshot.data)
                return Center(
                  child: Text("Si è verificato un errore"),
                );

              List<National> nationals = state.nationals;
              List<Regional> regionalList = state.regional;
              National lastNational = nationals[0];
              return ListView(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 25,
                ),
                children: <Widget>[
                  RowText(
                    text1: "Andamento nazionale",
                    text2: "Di più",
                    onTextTap: () => print("prova"),
                  ),
                  GridView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 10 / 8,
                      crossAxisCount: 2,
                      crossAxisSpacing: 5.0,
                      mainAxisSpacing: 5.0,
                    ),
                    children: <Widget>[
                      LabelWithData(
                        label: "Casi totali",
                        data: lastNational.totalCases.toString(),
                      ),
                      LabelWithData(
                        label: "Nuovi infetti",
                        data: lastNational.newInfected.toString(),
                      ),
                      LabelWithData(
                        label: "Deceduti",
                        data: lastNational.dead.toString(),
                      ),
                      LabelWithData(
                        label: "Guariti",
                        data: lastNational.recovered.toString(),
                      ),
                    ],
                  ),
                  RowText(
                    text1: "Classifica regioni",
                    text2: "Di più",
                    onTextTap: () => print("prova"),
                  ),
                  SizedBox(height: 20),
                  Builder(
                    builder: (context) {
                      List<Regional> regionalRange =
                          regionalList.getRange(0, 3).toList();

                      List<LinearGradient> gradients = [
                        LinearGradient(
                          colors: [
                            Theme.of(context).accentColor,
                            Color(0xFF599287),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          stops: [0.4, 1],
                        ),
                        LinearGradient(
                          colors: [
                            Color(0xFFF0896F),
                            Color(0xFFF19A82),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          stops: [0.7, 1],
                        ),
                        LinearGradient(
                          colors: [
                            Color(0xFFF7D374),
                            Color(0xFFEACF75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                        ),
                      ];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: regionalRange
                              .asMap()
                              .map(
                                (int i, Regional regional) {
                                  return MapEntry(
                                    i,
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      height: 250,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        gradient: gradients[i],
                                      ),
                                      child: Stack(
                                        children: <Widget>[
                                          Image.asset(
                                            "assets/line.png",
                                            fit: BoxFit.cover,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: <Widget>[
                                                Text(
                                                  regional.name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w300,
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  regional.dead.toString(),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 19,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                              .values
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
