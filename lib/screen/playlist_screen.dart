import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'dart:io';

import 'package:hive/hive.dart';

import '../utilities/constants.dart';
import 'customBody.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  ///Creating HiveBox instances
  var _songList;

  ///Creating a list of [songInfo] to add  songs taken from the HiveBox
  ///The SongInfo is taken by its songId {which we store in the [CustomBody] Ref-[1129]}
  List<SongInfo> songs;

  ///List of  SongsId
  List<String> songIds = [];
  getData() async {
    _songList = await Hive.openBox('myBox');
    _songList.values.forEach((songId) {
      print(songId.songInfo);
      print("dsndni");
      songIds.add(songId.songInfo);
    });
    songs = await audioQuery.getSongsById(ids: songIds);
    print(songs);
    return songs;
  }


  int currentIndex = 0;
  final GlobalKey<CustomBodyState> key = GlobalKey<CustomBodyState>();

  void changeTrack(bool isNext) {
    if (isNext) {
      if (currentIndex != songs.length - 1) {
        currentIndex++;
      }
    } else {
      if (currentIndex != 0) {
        currentIndex--;
      }
    }
    key.currentState.setSong(songs[currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 45, left: 16),
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(left: 10),
            child: Text(
              'Playlist',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20,),
          FutureBuilder(
              future: getData(),
              builder: (_, songSnapShot) => songSnapShot.hasData
                  ? ListView.builder(
                      itemCount: songSnapShot.data.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (_, index) => ListTile(
                            tileColor: Colors.black38,
                            leading: CircleAvatar(
                              backgroundImage: songs[index].albumArtwork == null
                                  ? NetworkImage(
                                      'https://images.macrumors.com/t/sqodWOqvWOvq6cU8t2ahMlU4AJM=/1600x0/article-new/2018/05/apple-music-note.jpg')
                                  : FileImage(File(songs[index].albumArtwork)),
                            ),
                            title: Text(
                              songs[index].title,
                              style: kMusicTitleTextStyle,
                            ),
                            subtitle: Text(
                              songs[index].artist,
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                        trailing: IconButton(
                          splashColor: Colors.red,

                          icon: Icon(Icons.delete,color: Colors.red,),
                          onPressed: () async{
                            var _songLists = await Hive.openBox('myBox');
                            setState(() {
                              _songLists.deleteAt(index);
                            });
                          },
                        ),
                            onTap: () {
                              currentIndex = index;
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => CustomBody(
                                      changeTrack: changeTrack,
                                      songInfo: songs[index],
                                      key: key)));
                            },
                          ))
                  : Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(
                        "Empty",
                        style: kMusicTitleTextStyle.copyWith(
                            color: Colors.white, fontSize: 20),
                      ),
                    ))
        ],
      ),
    );
  }
}
