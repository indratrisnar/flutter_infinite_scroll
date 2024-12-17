import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum FetchStatus { init, loading, success, failed }

class NoteState {
  final List list;
  final int lastId;
  final int limit;
  final FetchStatus fetchStatus;
  final String message;
  final bool hasMore;

  NoteState({
    this.list = const [],
    this.lastId = 0,
    this.limit = 10,
    this.fetchStatus = FetchStatus.init,
    this.message = '',
    this.hasMore = true,
  });

  NoteState copyWith({
    List? list,
    int? lastId,
    int? limit,
    FetchStatus? fetchStatus,
    String? message,
    bool? hasMore,
  }) {
    return NoteState(
      list: list ?? this.list,
      lastId: lastId ?? this.lastId,
      limit: limit ?? this.limit,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      message: message ?? this.message,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  NoteState state = NoteState();
  final scrollController = ScrollController();

  void updateState(NoteState n) {
    state = n;
    setState(() {});
  }

  void refresh() {
    state = NoteState();
    fetchData();
  }

  void fetchData() async {
    if (!state.hasMore) return;
    if (state.fetchStatus == FetchStatus.loading) return;

    updateState(state.copyWith(
      fetchStatus: FetchStatus.loading,
    ));

    await Future.delayed(Duration(seconds: 1));

    final url = Uri.parse(
      'https://fdlux-template.globeapp.dev/api/notes?lastId=${state.lastId}&limit=${state.limit}',
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

        if (newList.isEmpty && state.lastId == 0) {
          updateState(state.copyWith(
            fetchStatus: FetchStatus.failed,
            message: 'No Notes Yet',
          ));
          return;
        }

        if (newList.isEmpty) {
          updateState(state.copyWith(
            fetchStatus: FetchStatus.failed,
            hasMore: false,
            message: 'No More Data',
          ));
          return;
        }

        final updatedList = [...state.list, ...newList];
        updateState(state.copyWith(
          fetchStatus: FetchStatus.success,
          message: 'Success Fetch',
          list: updatedList,
          lastId: updatedList.last['id'],
        ));
        return;
      }

      if (response.statusCode == 400) {
        updateState(state.copyWith(
          fetchStatus: FetchStatus.failed,
          message: 'Bad Request',
        ));
        return;
      }

      updateState(state.copyWith(
        fetchStatus: FetchStatus.failed,
        message: 'Fetch Failed',
      ));
    } catch (e) {
      updateState(state.copyWith(
        fetchStatus: FetchStatus.failed,
        message: 'Something went wrong',
      ));
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
        title: Text('Notes (${state.list.length})'),
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
    final list = state.list;
    return ListView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final item = list[index];
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
    if (state.fetchStatus == FetchStatus.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.fetchStatus == FetchStatus.failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Text(state.message)),
      );
    }
    return const SizedBox();
  }
}
