import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:go_router/go_router.dart';
import 'package:preorder/components/appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthManagementScreen extends StatefulWidget {
  @override
  _HealthManagementScreenState createState() => _HealthManagementScreenState();
}

class _HealthManagementScreenState extends State<HealthManagementScreen> {
  int selectedTabIndex = 0; // 탭 선택 상태 (0: 칼로리, 1: 카페인)
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<MyRow>> fetchData(String period, String type) async {
    List<MyRow> userHealthData = await fetchUserHealthData(period, type);
    List<MyRow> averageHealthData = await _fetchAverageHealthData(period, type);
    int recommendedValue = 15;

    // 리스트의 순서를 바꿔 사용자 섭취량이 먼저 오도록 합니다.
    return [
      ...userHealthData,
      MyRow('권장 섭취량', recommendedValue, Colors.green),
      ...averageHealthData,
    ];
  }

  Future<List<MyRow>> fetchUserHealthData(String period, String type) async {
    var healthDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('health')
        .doc(period)
        .get();

    if (!healthDoc.exists) {
      return [];
    }

    var healthData = healthDoc.data();
    return [
      MyRow(
        '사용자 섭취량',
        healthData?[type] ?? 0,
        Color(0xff303742),
      )
    ];
  }

  Future<List<MyRow>> _fetchAverageHealthData(
      String period, String type) async {
    var healthStatsDoc = await FirebaseFirestore.instance
        .collection('healthStats')
        .doc('average')
        .get();

    if (!healthStatsDoc.exists) {
      // 문서가 존재하지 않으면 평균 섭취량을 0으로 설정합니다.
      return [MyRow('평균 섭취량', 0, Colors.yellow)];
    }

    var healthStatsData = healthStatsDoc.data();
    var averageValue = healthStatsData?[period]?[type] ?? 0;
    return [MyRow('평균 섭취량', averageValue, Colors.yellow)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('건강 관리',
        style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color(0xff303742),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/', extra: 2),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabButton('칼로리', 0),
          _buildTabButton('카페인', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Text(
        title,
        style: TextStyle(
          color: selectedTabIndex == index ? Colors.blue : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 선택된 탭에 따라 데이터 세트 결정
    return selectedTabIndex == 0
        ? _buildCalorieCharts()
        : _buildCaffeineCharts();
  }

  Widget _buildCalorieCharts() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChartFuture('일간 칼로리 섭취량', 'daily', 'calories'),
          _buildChartFuture('주간 칼로리 섭취량', 'weekly', 'calories'),
          _buildChartFuture('월간 칼로리 섭취량', 'monthly', 'calories'),
        ],
      ),
    );
  }

  Widget _buildCaffeineCharts() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChartFuture('일간 카페인 섭취량', 'daily', 'caffeine'),
          _buildChartFuture('주간 카페인 섭취량', 'weekly', 'caffeine'),
          _buildChartFuture('월간 카페인 섭취량', 'monthly', 'caffeine'),
        ],
      ),
    );
  }

  Widget _buildChartFuture(String title, String period, String type) {
    return FutureBuilder<List<MyRow>>(
      future: fetchData(period, type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('데이터를 가져오는 데 실패했습니다.');
        }

        var seriesList = <charts.Series<MyRow, String>>[];

        seriesList.add(
          charts.Series<MyRow, String>(
            id: 'Health Data',
            domainFn: (MyRow row, _) => row.category,
            measureFn: (MyRow row, _) => row.value,
            colorFn: (MyRow row, _) => row.barColor,
            data: snapshot.data!,
          ),
        );

        return _buildChartCard(title, seriesList);
      },
    );
  }

  // 차트 카드를 생성하는 위젯
  Widget _buildChartCard(
      String title, List<charts.Series<MyRow, String>> seriesList) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: charts.BarChart(
                seriesList,
                animate: true,
                vertical: false,
                barRendererDecorator: charts.BarLabelDecorator<String>(),
                domainAxis: const charts.OrdinalAxisSpec(),
                defaultRenderer: charts.BarRendererConfig(
                  cornerStrategy: const charts.ConstCornerStrategy(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyRow {
  final String category;
  final int value;
  final charts.Color barColor; // charts_flutter 라이브러리의 Color 타입 사용

  MyRow(this.category, this.value, Color color)
      : barColor = charts.Color(
            r: color.red,
            g: color.green,
            b: color.blue,
            a: color.alpha); // Color 타입을 charts.Color로 변환
}
