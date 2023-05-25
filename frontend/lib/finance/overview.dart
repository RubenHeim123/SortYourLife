import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../general/navigationdrawer.dart'  as m;
import '../globals.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/account.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class Overview extends StatefulWidget {
  const Overview({super.key, required this.offline});
  final bool offline;

  @override
  State<Overview> createState() => _Overview();
}

class _Overview extends State<Overview> {
  final global = Globals();
  Client client = Client();
  double sumAccounts = 0;
  List<Map<String, dynamic>> incomeData = []; 
  List<Map<String, dynamic>> outgoingData = []; 
  Map<String, double> accountMapPositive = {};
  Map<String, double> accountMapNegative = {};

  Future<void> _getIncomeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('auth_token')!;
    List response = json.decode(utf8.decode((await client.get(Uri.parse(
      "${global.URL_PREFIX}finance/cumulatedTransactions/Einnahme"),
      headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));
    incomeData = response.cast<Map<String, dynamic>>();
  }

  Future<void> _getOutgoingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('auth_token')!;
    List response = json.decode(utf8.decode((await client.get(Uri.parse(
      "${global.URL_PREFIX}finance/cumulatedTransactions/Ausgabe"),
      headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));
    outgoingData = response.cast<Map<String, dynamic>>();
  }

  ZoomPanBehavior  zoomPan = ZoomPanBehavior(
    enablePinching: true,
    enableSelectionZooming: true,
    enableMouseWheelZooming: true,
    enablePanning: true,
    zoomMode: ZoomMode.x,
  );

  @override
  void initState() {
    super.initState();   
  }

  Future<void> _getAccountList() async {
    var accounts = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('auth_token')!;

    List response = json.decode(utf8.decode((await client.get(
      Uri.parse("${global.URL_PREFIX}finance/accountsdetails/"),
      headers: <String, String>{'Authorization': 'Token $token'}
    )).bodyBytes));

    for (var element in response) {
      accounts.add(Account.fromMap(element));
    }
    for (var item in accounts) {
      if (item.accountAmount == null){
        continue;
      } else if (double.parse(item.accountAmount) > 0) {
        accountMapPositive[item.accountName] = double.parse(item.accountAmount);
      } else if (double.parse(item.accountAmount) < 0) {
        accountMapNegative[item.accountName] = double.parse(item.accountAmount);
      }
    }

    sumAccounts = 0;

    if(accountMapPositive.isNotEmpty){
      sumAccounts += double.parse(accountMapPositive.values.reduce((a, b) => a + b).toStringAsFixed(2));
    }
    if (accountMapNegative.isNotEmpty){
      sumAccounts += double.parse(accountMapNegative.values.reduce((a, b) => a + b).toStringAsFixed(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übersicht'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: widget.offline ?
      const Center(
        child: Text('Diese Anzeige kann nur mit Internetverbindung angezeigt werden'),
      )
      : FutureBuilder(
        future: Future.wait([_getIncomeData(), _getAccountList(), _getOutgoingData()]),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasData){
            return SingleChildScrollView(
              child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  accountMapPositive.isNotEmpty ? 
                  Column(
                    children: [
                      const SizedBox(height: 25),
                      const Text('Positive Konten'),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: PieChart(
                          dataMap: accountMapPositive,
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValues:true,
                            showChartValuesOutside: true,
                            decimalPlaces: 2,
                          ),
                        ),
                      ),
                    ]
                  ) : Container(),
                  accountMapNegative.isNotEmpty ? 
                  Column(
                    children: [
                      const SizedBox(height: 15),
                      const Text('Negative Konten'),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: PieChart(
                          dataMap: accountMapNegative.map((key, value) => MapEntry(
                            key,
                            -value,
                          )),
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValues:true,
                            showChartValuesOutside: true,
                            decimalPlaces: 2,
                          ),
                        ),
                      ),
                    ]
                  ) : Container(),
                  const SizedBox(height: 15),
                  Text('Summe aller Konten: $sumAccounts'),
                  incomeData.isNotEmpty ? 
                  Column(
                    children: [ 
                      const SizedBox(height: 25),
                      const Text('Einnahmen'),
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        zoomPanBehavior: zoomPan,
                        series: List.generate(incomeData[0].keys.toList().length - 2, (index) {
                          final ikeys = incomeData[0].keys.toList()..remove('Woche');
                          return SplineSeries<Map<String, dynamic>, String>(
                            dataSource: incomeData,
                            xValueMapper: (Map<String, dynamic> sales, _) => sales['Woche'],
                            yValueMapper: (Map<String, dynamic> sales, _) => sales[ikeys[index]],
                            name: ikeys[index],
                          );
                        }),
                      ),
                    ]
                  ):Container(),
                  incomeData.isNotEmpty ? 
                  Column(
                    children: [                   
                      const SizedBox(height: 15),
                      const Text('Ausgaben'),
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        zoomPanBehavior: zoomPan,
                        series: List.generate(outgoingData[0].keys.toList().length - 2, (index) {
                          final okeys = outgoingData[0].keys.toList()..remove('Woche');
                          return SplineSeries<Map<String, dynamic>, String>(
                            dataSource: outgoingData,
                            xValueMapper: (Map<String, dynamic> sales, _) => sales['Woche'],
                            yValueMapper: (Map<String, dynamic> sales, _) => sales[okeys[index]],
                            name: okeys[index],
                          );
                        }),
                      ),
                    ]
                  ) : Container(),
                ]
              )
            );
          } else if (snapshot.hasError) {
            // Wenn ein Fehler auftritt, zeige eine Fehlermeldung an
            return const Center(
              child: Text('Fehler beim Laden der Daten')
              );
          } else {
            return const Center(
              child: CircularProgressIndicator()
            );
          }
        }
      )
    );
  }
}
