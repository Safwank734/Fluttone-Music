import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:favorite_button/favorite_button.dart';
import 'package:fluttone_music/model/hive_model.dart';
import 'package:fluttone_music/screen/headerBackground.dart';
import 'package:fluttone_music/utilities/constants.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';

class CustomBody extends StatefulWidget {
  SongInfo songInfo;
  Function changeTrack;

  final GlobalKey<CustomBodyState> key;

  CustomBody({this.songInfo, this.changeTrack, this.key}) : super(key: key);

  CustomBodyState createState() => CustomBodyState();
}

class CustomBodyState extends State<CustomBody> {
  Icon playli = Icon(
    Icons.playlist_add,
    color: Colors.white54,
  );
  int playlistIconNum = 0;
  double minimumValue = 0.0, maximumValue = 0.0, currentValue = 0.0;
  String currentTime = '', endTime = '';

  bool isPlaying = false;
  String status = 'hidden';

  final AudioPlayer player = AudioPlayer();

  StreamSubscription mediaPlayer;

  void initState() {
    super.initState();
    initiateHive();
    mediaPlayer = player.positionStream.listen((event) => event);
    setSong(widget.songInfo);
    MediaNotification.setListener('pause', () {
      setState(() {
        status = 'pause';
      });
      changeStatus();
    });
    MediaNotification.setListener('play', () {
      setState(() {
        status = 'play';
      });
      changeStatus();
    });
    MediaNotification.setListener('next', () {
      widget.changeTrack(true);
    });
    MediaNotification.setListener('prev', () {
      widget.changeTrack(false);
    });
    MediaNotification.setListener('prev', () {
      widget.changeTrack(false);
    });
    MediaNotification.setListener('select', () {});
  }

  void dispose() {
    super.dispose();
    hideNotfication();
    player?.dispose();
    mediaPlayer?.cancel();
  }

  void setSong(SongInfo songInfo) async {
    widget.songInfo = songInfo;

    currentNotificaton();
    await player.setUrl(widget.songInfo.uri);
    currentValue = minimumValue;
    maximumValue = player.duration.inMilliseconds.toDouble();
    setState(() {
      currentTime = getDuration(currentValue);
      endTime = getDuration(maximumValue);
    });

    isPlaying = false;
    changeStatus();
    mediaPlayer.onData((data) {
      currentValue = data.inMilliseconds.toDouble();
      currentTime = getDuration(currentValue);
      setState(() {});
      if (currentValue >= maximumValue) {
        widget.changeTrack(true);
      }
    });
  }

  void changeStatus() {
    setState(() {
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      player.play();
      currentNotificaton();
    } else {
      player.pause();
      pausNotification();
    }
  }

  String getDuration(double value) {
    Duration duration = Duration(milliseconds: value.round());
    return [duration.inMinutes, duration.inSeconds]
        .map((e) => e.remainder(60).toString().padLeft(2, '0'))
        .join(':');
  }

  //background play notification
  void currentNotificaton() {
    MediaNotification.showNotification(
        title: widget.songInfo.title, author: widget.songInfo.artist);
  }

  //background pause notification
  void pausNotification() {
    MediaNotification.showNotification(
        title: widget.songInfo.title,
        author: widget.songInfo.artist,
        isPlaying: false);
  }

  //function for playing
  void playNotification() {
    MediaNotification.showNotification(
      title: widget.songInfo.title,
      author: widget.songInfo.artist,
      isPlaying: true,
    );
  }

  //hide background play
  void hideNotfication() {
    MediaNotification.hideNotification();
  }

  var savedList;

  Future initiateHive() async {
    ///Creating a HiveBox to Store data
    savedList = await Hive.openBox('myBox');
  }

  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // double listHeight =
    //     ((size.height * 0.6) * widget.songInfo.track.length).toDouble();
    return Material(
      child: Column(
        children: [
          CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40 * 1.5),
                    child: Slider(
                      inactiveColor: Colors.black,
                      activeColor: Colors.red,
                      min: minimumValue,
                      max: maximumValue,
                      value: currentValue,
                      onChanged: (value) {
                        currentValue = value;
                        player
                            .seek(Duration(milliseconds: currentValue.round()));
                      },
                    ),
                  ),
                  Container(
                    transform: Matrix4.translationValues(0, -15, 0),
                    margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentTime,
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500)),
                        Text(endTime,
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          child: Icon(Icons.skip_previous,
                              color: Colors.red, size: 55),
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            widget.changeTrack(false);
                            setState(() {
                              playli = Icon(
                                Icons.playlist_add,
                                color: Colors.white54,
                              );
                            });
                          },
                        ),
                        GestureDetector(
                          child: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: Colors.red,
                              size: 85),
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            changeStatus();
                          },
                        ),
                        GestureDetector(
                          child: Icon(Icons.skip_next,
                              color: Colors.red, size: 55),
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            widget.changeTrack(true);
                            setState(() {
                              playli = Icon(
                                Icons.playlist_add,
                                color: Colors.white54,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  CustomHeader() {
    Size size = MediaQuery.of(context).size;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        HeaderBackground(),
        Container(
          alignment: Alignment.center,
          height: size.height * 0.7,
          padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: size.height * 0.06,
                width: size.width,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Colors.white.withOpacity(0.5)),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                          icon: playli,
                          onPressed: () {
                            setState(() {
                              if (playlistIconNum == 0) {
                                playli = Icon(
                                  Icons.playlist_add_check,
                                  color: Colors.red,
                                );
                                playlistIconNum = 1;
                              } else {
                                playli = Icon(
                                  Icons.playlist_add,
                                  color: Colors.white54,
                                );
                                playlistIconNum = 0;
                              }
                            });
                            savedList.keys.contains(widget.songInfo.id);

                            ///Initializing [SongPlayList] and the added to the box
                            var songFav = SongPlayList()
                              ..songInfo = widget.songInfo.id;

                            ///Grabbed the songId, so that the song can be identified in the [FavouriteScreen]
                            savedList.put(widget.songInfo.id, songFav);
                            print(songFav);
                          }),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.4,
              ),
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  widget.songInfo.title,
                  style: kSongTitile,
                ),
              ),
              // SizedBox(
              //   height: size.height * 0.1,
              // ),

              Text(
                widget.songInfo.album,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    height: 1.5),
              ),

              // Spacer(),
              // Text(
              //   widget.songInfo.title,
              //   style: TextStyle(color: Colors.black.withOpacity(0.5)),
              // ),
              // Container(
              //   margin: EdgeInsets.only(top: size.height * 0.025),
              //   width: size.width * 0.3,
              //   height: 2,
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.centerLeft,
              //       end: Alignment.centerRight,
              //       colors: [
              //         Colors.grey.withOpacity(0.05),
              //         Colors.grey.withOpacity(0.8),
              //         Colors.grey.withOpacity(0.05),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        Positioned(
          top: size.height * 0.3,
          child: Container(
            height: 200,
            width: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2.0, color: Colors.white),
              image: DecorationImage(
                  image: NetworkImage(
                    'https://images.macrumors.com/t/sqodWOqvWOvq6cU8t2ahMlU4AJM=/1600x0/article-new/2018/05/apple-music-note.jpg',
                  ),
                  fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}
