import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lets_chat/api/apis.dart';
import 'package:lets_chat/main.dart';
import 'package:lets_chat/models/chat_user.dart';
import 'package:lets_chat/models/message.dart';
import 'package:lets_chat/widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];
  final _textController = TextEditingController();
  bool _showEmoji = false, _isUploading = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
        ),
        backgroundColor: Color.fromARGB(255, 197, 229, 255),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllMessages(widget.user),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    //if data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const SizedBox();
                    //if loaded
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data?.docs;
                      _list = data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                          [];
                      if (_list.isNotEmpty) {
                        return ListView.builder(
                            reverse: true,
                            itemCount: _list.length,
                            padding: EdgeInsets.only(top: mq.height * .01),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return MessageCard(message: _list[index]);
                            });
                      } else {
                        return const Center(
                          child:
                              Text('Say Hii!', style: TextStyle(fontSize: 20)),
                        );
                      }
                  }
                },
              ),
            ),
            if (_isUploading)
              const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: CircularProgressIndicator(strokeWidth: 2))),
            _chatInput()
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          IconButton(
              //back button
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black54,
              )),
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * 0.3),
            child: CachedNetworkImage(
              width: mq.height * .05,
              height: mq.height * .05,
              imageUrl: widget.user.image,
              //placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  const CircleAvatar(child: Icon(CupertinoIcons.person)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              const Text('Last seen not available',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                  )),
            ],
          )
        ],
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
        padding: EdgeInsets.symmetric(
            vertical: mq.height * .01, horizontal: mq.width * .025),
        child: Row(
          children: [
            Expanded(
              child: Card(
                //provide wide background
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    //emoji button
                    IconButton(
                        //back button
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.emoji_emotions,
                          color: Colors.blueAccent,
                        )),
                    Expanded(
                        child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                          hintText: 'Type Something',
                          hintStyle:
                              TextStyle(color: Colors.blueAccent, fontSize: 25),
                          border: InputBorder.none),
                    )),
                    IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();

                          // Picking multiple images
                          final List<XFile> images =
                              await picker.pickMultiImage(imageQuality: 70);

                          // uploading & sending image one by one
                          for (var i in images) {
                            log('Image Path: ${i.path}');
                            setState(() => _isUploading = true);
                            await APIs.sendChatImage(widget.user, File(i.path));
                            setState(() => _isUploading = false);
                          }
                        },
                        icon: const Icon(Icons.image,
                            color: Colors.blueAccent, size: 26)),
                    IconButton(
                        //back button
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();

                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            log('Image Path : ${image.path}');
                            setState(() => _isUploading = true);
                            await APIs.sendChatImage(
                                widget.user, File(image.path));
                            setState(() => _isUploading = false);
                          }
                        },
                        icon: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.blueAccent,
                          size: 26,
                        )),
                    SizedBox(width: mq.width * .02),
                  ],
                ),
              ),
            ),
            MaterialButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                  _textController.text = '';
                }
              },
              minWidth: 0,
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, right: 5, left: 10),
              shape: const CircleBorder(),
              color: Colors.green,
              child: const Icon(Icons.send, color: Colors.white, size: 28),
            ),
          ],
        ));
  }
}
