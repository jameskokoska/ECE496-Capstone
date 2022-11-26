import 'dart:async';
import 'dart:typed_data';

import 'package:capstone/database/tables.dart';
import 'package:capstone/pages/CreateUserPage.dart';
import 'package:capstone/pages/Face%20Scanner.dart';
import 'package:capstone/pages/Model.dart';
import 'package:capstone/pages/RecordAudio.dart';
import 'package:capstone/struct/databaseGlobal.dart';
import 'package:capstone/widgets/UserEntry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Home'),
            trailing: CupertinoButton(
              child: const Icon(CupertinoIcons.plus_app),
              onPressed: () {
                Navigator.push(context,
                    CupertinoPageRoute<Widget>(builder: (BuildContext context) {
                  return CreateUserPage();
                }));
              },
              padding: EdgeInsets.zero,
            ),
          ),
          SliverToBoxAdapter(
            child: RecordAudio(),
          ),
          SliverToBoxAdapter(
            child: CupertinoButton(
              onPressed: () {
                Navigator.push(context,
                    CupertinoPageRoute<Widget>(builder: (BuildContext context) {
                  return FaceScannerPage();
                }));
              },
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Icon(CupertinoIcons.camera),
                    Text("Scan Face"),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoButton(
              onPressed: () {
                Navigator.push(context,
                    CupertinoPageRoute<Widget>(builder: (BuildContext context) {
                  return Model();
                }));
              },
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Icon(CupertinoIcons.camera),
                    Text("Model"),
                  ],
                ),
              ),
            ),
          ),
          StreamBuilder<List<User>>(
            stream: database.watchUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return UserEntry(user: snapshot.data![index]);
                      },
                      childCount: snapshot.data?.length,
                    ),
                  ),
                );
              } else {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
