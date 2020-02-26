import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pizza Map',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.pink[50],
      ),
      home: MyHomePage(title: 'Pizza Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Stream<QuerySnapshot> _PizzaStores;

  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();

    _PizzaStores = Firestore.instance
        .collection('pizza_store')
        .orderBy('name')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _PizzaStores,
        builder: (context, snapshots) {
          if (snapshots.hasError) {
            return Center(child: Text('Error: ${snapshots.error}'));
          }
          if (!snapshots.hasData) {
            return Center(child: const Text('Loading...'));
          }

          return Column(
            children: <Widget>[
              Flexible(
                flex: 2,
                child: StoreMap(
                  documents: snapshots.data.documents,
                  initialPosition: const LatLng(23.000530, 72.501961),
                  mapController: _mapController,
                ),
              ),
              Flexible(
                flex: 3,
                child: StoreList(
                  documents: snapshots.data.documents,
                  mapController: _mapController,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StoreList extends StatelessWidget {
  final List<DocumentSnapshot> documents;
  final Completer<GoogleMapController> mapController;

  StoreList({Key key, @required this.documents, @required this.mapController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: documents.length,
        itemBuilder: (builder, index) {
          final document = documents[index];

          return ListTile(
            title: Text(document['name']),
            subtitle: Text(document['address']),
            onTap: () async {
              final conroller = await mapController.future;
              await conroller
                  .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                      target: LatLng(
                        document['location'].latitude,
                        document['location'].longitude,
                      ),
                      zoom: 16)));
            },
          );
        });
  }
}

const _pinkHue = 350.0;

class StoreMap extends StatelessWidget {
  final List<DocumentSnapshot> documents;
  final LatLng initialPosition;
  final Completer<GoogleMapController> mapController;

  StoreMap(
      {Key key,
      @required this.documents,
      @required this.initialPosition,
      @required this.mapController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 14,
      ),
      markers: documents
          .map((document) => Marker(
                markerId: MarkerId("yash's Marker"),
                icon: BitmapDescriptor.defaultMarkerWithHue(_pinkHue),
                position: LatLng(
                  document['location'].latitude,
                  document['location'].longitude,
                ),
                infoWindow: InfoWindow(
                  title: document['name'],
                  snippet: document['address'],
                ),
              ))
          .toSet(),
      onMapCreated: (mapController) {
        this.mapController.complete(mapController);
      },
    );
  }
}
