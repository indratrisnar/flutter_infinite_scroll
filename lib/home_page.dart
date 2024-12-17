import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum FetchStatus { init, loading, success, failed }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List notes = [];
  int lastId = 0;
  int limit = 10;
  FetchStatus fetchStatus = FetchStatus.init;
  String message = '';
  bool hasMore = true;
  final scrollController = ScrollController();

  void refresh() {
    notes = [];
    lastId = 0;
    fetchStatus = FetchStatus.init;
    message = '';
    hasMore = true;
    fetchData();
  }

  void fetchData() async {
    if (!hasMore) return;
    if (fetchStatus == FetchStatus.loading) return;

    fetchStatus = FetchStatus.loading;
    setState(() {});

    await Future.delayed(Duration(seconds: 1));

    final url = Uri.parse(
      'https://fdlux-template.globeapp.dev/api/notes?lastId=$lastId&limit=$limit',
    );
    final textToken = 'asaslidjiaosd';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $textToken',
    };
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        final newList = resBody['notes'] as List;

        if (newList.isEmpty && lastId == 0) {
          fetchStatus = FetchStatus.failed;
          message = 'No Notes Yet';
          setState(() {});
          return;
        }

        if (newList.isEmpty) {
          fetchStatus = FetchStatus.failed;
          message = 'No More Data';
          hasMore = false;
          setState(() {});
          return;
        }

        fetchStatus = FetchStatus.success;
        notes = [...notes, ...newList];
        lastId = notes.last['id'];
        setState(() {});
        return;
      }

      if (response.statusCode == 400) {
        fetchStatus = FetchStatus.failed;
        message = 'Bad Request';
        setState(() {});
        return;
      }

      fetchStatus = FetchStatus.failed;
      message = 'Fetch Field';
      setState(() {});
    } catch (e) {
      fetchStatus = FetchStatus.failed;
      message = 'Something went wrong';
      setState(() {});
    }
  }

  @override
  void initState() {
    fetchData();
    scrollController.addListener(() {
      double currentOffset = scrollController.offset;
      double maxScroll = scrollController.position.maxScrollExtent;
      if (currentOffset == maxScroll) {
        fetchData();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade300,
        title: Text('Notes (${notes.length})'),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => refresh(),
        child: ListView(
          controller: scrollController,
          children: [
            buildNotes(),
            buildNotesInfo(),
          ],
        ),
      ),
    );
  }

  ListView buildNotes() {
    return ListView.builder(
      itemCount: notes.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final item = notes[index];
        return buildNoteItem(item);
      },
    );
  }

  Widget buildNoteItem(Map item) {
    final id = item['id'];
    final title = item['title'];
    final description = item['description'];
    return ListTile(
      leading: CircleAvatar(
        foregroundColor: Theme.of(context).primaryColor,
        radius: 24,
        child: Text(
          '$id',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget buildNotesInfo() {
    if (fetchStatus == FetchStatus.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (fetchStatus == FetchStatus.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Text(message)),
      );
    }
    return const SizedBox();
  }
}
