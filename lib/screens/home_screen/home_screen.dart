import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_firebase_crud_app/screens/auth/auth_screen.dart';
import 'package:flutter_firebase_crud_app/screens/map_view/map_view_screen.dart';
import 'package:flutter_firebase_crud_app/screens/send_or_update_data_screen/send_or_update_data_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        children: [
          const Spacer(),
          FloatingActionButton(
            heroTag: 'MapViewScreen',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MapViewScreen()),
              );
            },
            backgroundColor:
                const Color.fromARGB(255, 58, 248, 93), // Màu xanh dương
            child: const Icon(Icons.map), // Icon bản đồ
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            heroTag: 'SendOrUpdateData',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SendOrUpdateData(
                  userData: UserData(
                    timestamp: DateTime.now(),
                  ),
                ),
              ));
            },
            backgroundColor: const Color(0xFFC2185B),
            child: const Icon(Icons.add_box_sharp),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Đặt màu nền trong suốt để hiển thị gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF92E738),
                Color(0xFF48A147)
              ], // Thay đổi màu sắc tại đây
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Trang chủ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFECEFF1),
                  Color.fromARGB(255, 106, 106, 106)
                ], // Thay đổi màu sắc tại đây
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo từ Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                    if (streamSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!streamSnapshot.hasData ||
                        streamSnapshot.data!.docs.isEmpty) {
                      return const Text(
                        'Không có thông báo',
                        style: TextStyle(fontSize: 16),
                      );
                    }
                    return SizedBox(
                      height: 150, // Điều chỉnh chiều cao nếu cần thiết
                      child: PageView.builder(
                        itemCount: streamSnapshot.data!.docs.length,
                        itemBuilder: (BuildContext context, int index) {
                          final doc = streamSnapshot.data!.docs[index];
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          DateTime timestamp = data['timestamp'].toDate();
                          String formattedTime = DateFormat('dd/MM/yyyy HH:mm')
                              .format(timestamp.toLocal());
                          return SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thông báo: ${data['notification']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Thời gian: $formattedTime',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 255, 255, 255)
                  ], // Thay đổi màu sắc tại đây
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 13),
                      child: Text(
                        'Thông tin của bạn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('createById',
                              isEqualTo: userLogin.getRoleIdFilter())
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                        return streamSnapshot.hasData
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                itemCount:
                                    streamSnapshot.data?.docs.length ?? 0,
                                itemBuilder: ((context, index) {
                                  final item = UserData.fromFirestore(
                                      streamSnapshot.data?.docs[index]);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                            horizontal: 20)
                                        .copyWith(bottom: 20),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 118, 214, 255), // Màu xám nhạt
                                      boxShadow: const [
                                        BoxShadow(
                                          color:
                                              Color.fromARGB(255, 29, 73, 35),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(
                                          10), // Độ cong mép
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .delete_outline, // Icon rác thải
                                              size: 31,
                                              color: Color.fromARGB(
                                                  255, 14, 135, 26), // Màu xám
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.Waste_Type,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  item.Describe,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                                Text(
                                                  item.Waste_Level,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 20),
                                          child: Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SendOrUpdateData(
                                                        userData: item,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: Color.fromARGB(255,
                                                      255, 0, 0), // Màu vàng
                                                  size: 21,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  _deleteRow(context, item.id);
                                                },
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Color.fromARGB(255, 23,
                                                      23, 23), // Màu đỏ
                                                  size: 21,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              )
                            : const Center(
                                child: SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: CircularProgressIndicator(
                                    color: Colors.green, // Màu xanh
                                  ),
                                ),
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 255, 238, 213),
          child: AnimationLimiter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "Người dùng: ${userLogin.username}\nVai trò: ${userLogin.role}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.exit_to_app, color: Colors.deepPurple),
                    title: const Text('Đăng xuất'),
                    onTap: () {
                      _logout(context);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.location_on, color: Colors.deepPurple),
                    title: const Text(
                        'Thông báo về các địa điểm tập kết rác thải'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LandfillLocationsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.deepPurple),
                    title: const Text('Xóa Tài Khoản'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Xác nhận xóa tài khoản'),
                            content: const Text(
                                'Bạn có chắc chắn muốn xóa tài khoản?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteCurrentUserAndLogout(context);
                                },
                                child: const Text('Xóa'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.deepPurple),
                    title: const Text('Thông tin'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IntroductionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _deleteImage(String docID) async {
  try {
    final storageRef =
        FirebaseStorage.instance.ref().child('user_images').child('$docID.jpg');

    await storageRef.delete();
    print('Xóa ảnh thành công: $docID');
  } catch (e) {
    print('Lỗi xóa ảnh: $e');
  }
}

void _deleteAuthAndUsers(BuildContext context, String authId) async {
  try {
    await FirebaseFirestore.instance.collection('auths').doc(authId).delete();

    final usersQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('createById', isEqualTo: authId)
        .get();
    for (final doc in usersQuerySnapshot.docs) {
      await _deleteImage(doc.id);
      await doc.reference.delete();
    }
  } catch (e) {
    print('Error deleting auth and users: $e');
  }
}

class LandfillLocationsScreen extends StatelessWidget {
  const LandfillLocationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm tập kết rác thải'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('landfill_locations')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra sự cố'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy địa điểm tập kết rác '),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              final DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String timestamp = DateFormat('dd/MM/yyyy HH:mm')
                  .format(data['timestamp'].toDate());

              List<Map<String, dynamic>> noteHistory =
                  List<Map<String, dynamic>>.from(data['noteHistory'] ?? []);

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.containsKey('image_landfill'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          data['image_landfill'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Địa chỉ:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data['address'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.notes,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Ghi chú:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data['note'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Thời gian:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            timestamp,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          color: Colors.green[700],
                          onPressed: () {
                            _addNoteDialog(
                              context,
                              document.id,
                              data['note'],
                              noteHistory,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {
                            _deleteNoteDialog(
                              context,
                              document.id,
                              noteHistory,
                            );
                          },
                        ),
                      ],
                    ),
                    if (noteHistory.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: noteHistory.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> note = noteHistory[index];
                          String editedTimestamp =
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(note['editedTimestamp'].toDate());
                          return ListTile(
                            leading: const Icon(Icons.comment_outlined),
                            title: Text(
                              'Bình luận từ người dùng: ${note['editedBy']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nội dung: ${note['note']}'),
                                Text('Thời gian bình luận: $editedTimestamp'),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _addNoteDialog(
  BuildContext context,
  String docId,
  String currentNote,
  List<Map<String, dynamic>> noteHistory,
) async {
  TextEditingController noteController = TextEditingController(text: '');

  String initialNote = currentNote;
  String buttonText = 'Lưu';
  bool noteChanged = false;
  AuthModel? currentUser = AuthService().currentUser;
  if (currentUser != null) {
    String currentUserId = currentUser.id;
    int indexOfCurrentUserEdit =
        noteHistory.indexWhere((note) => note['editedById'] == currentUserId);
    if (indexOfCurrentUserEdit != -1) {
      noteChanged = true;
    }
  }
  if (noteChanged) {
    buttonText = 'Thay đổi';
    initialNote = noteHistory.last['note'];
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Thêm ghi chú của bạn về địa điểm'),
      content: TextField(
        controller: noteController,
        decoration: const InputDecoration(
          labelText: 'Note',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () async {
            String newNote = noteController.text.isNotEmpty
                ? noteController.text
                : initialNote;
            AuthModel? currentUser = AuthService().currentUser;
            if (currentUser != null) {
              String currentUserId = currentUser.id;
              String? currentUserUsername = currentUser.username;
              int indexOfCurrentUserEdit = noteHistory
                  .indexWhere((note) => note['editedById'] == currentUserId);
              if (indexOfCurrentUserEdit != -1) {
                noteHistory[indexOfCurrentUserEdit]['note'] = newNote;
                noteHistory[indexOfCurrentUserEdit]['editedTimestamp'] =
                    DateTime.now();
              } else {
                Map<String, dynamic> newNoteVersion = {
                  'note': newNote,
                  'editedBy': currentUserUsername,
                  'editedById': currentUserId,
                  'editedTimestamp': DateTime.now(),
                };
                noteHistory.add(newNoteVersion);
              }
              await FirebaseFirestore.instance
                  .collection('landfill_locations')
                  .doc(docId)
                  .update({
                'noteHistory': noteHistory,
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(noteChanged
                      ? 'Ghi chú của bạn đã được thay đổi.'
                      : 'Ghi chú của bạn đã được thêm vào (Bạn chỉ có thể thêm 1 Ghi chú).'),
                ),
              );
            } else {
              print('Error: User is not signed in');
            }
          },
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

void _deleteNoteDialog(BuildContext context, String docId,
    List<Map<String, dynamic>> noteHistory) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận xóa ghi chú'),
      content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () async {
            AuthModel? currentUser = AuthService().currentUser;
            if (currentUser != null) {
              String currentUserId = currentUser.id;
              int indexOfCurrentUserEdit = noteHistory
                  .indexWhere((note) => note['editedById'] == currentUserId);
              if (indexOfCurrentUserEdit != -1) {
                await FirebaseFirestore.instance
                    .collection('landfill_locations')
                    .doc(docId)
                    .update({
                  'noteHistory': FieldValue.arrayRemove(
                      [noteHistory[indexOfCurrentUserEdit]]),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ghi chú của bạn đã được xóa.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ghi chú của bạn không tồn tại.'),
                  ),
                );
              }
            } else {
              print('Error: User is not signed in');
            }
          },
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Có thể bạn chưa biết'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ExpansionTile(
                title: const Text(
                  'Cách phân loại rác thải',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildImageTile(
                          'assets/rachuuco.png',
                          'Rác hữu cơ',
                          'Rác hữu cơ bao gồm các vật liệu tự nhiên như thức ăn thừa, lá cây, vỏ trái cây và rau củ.',
                          context,
                        ),
                        _buildImageTile(
                          'assets/racvoco.png',
                          'Rác vô cơ',
                          'Rác không hữu cơ bao gồm các vật liệu như nhựa, kim loại, giấy và thủy tinh.',
                          context,
                        ),
                        _buildImageTile(
                          'assets/racnguyhai.png',
                          'Rác nguy hại',
                          'Rác nguy hại bao gồm các vật liệu như pin, ắc quy, hóa chất độc hại và thuốc trừ sâu.',
                          context,
                        ),
                        _buildImageTile(
                          'assets/ractaiche.png',
                          'Rác tái chế',
                          'Rác tái chế là các vật liệu có thể được tái chế và sử dụng lại để sản xuất các sản phẩm mới.',
                          context,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const ExpansionTile(
                title: Text(
                  'Cách tái chế rác thải',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Phần này không có ảnh
                        ListTile(
                          title: Text(
                            'Tái chế vật liệu:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Như tái chế giấy, nhựa, kim loại, và thủy tinh.',
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Tái chế sản phẩm:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sử dụng lại sản phẩm cũ để tạo ra sản phẩm mới, ví dụ như tái chế giày dép, đồ điện tử, hoặc đồ gia dụng.',
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Tái chế năng lượng:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sử dụng rác thải hữu cơ để tạo năng lượng, như biogas từ composting.',
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Tái chế nước:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Tái chế nước thải để sử dụng lại cho các mục đích khác, như tưới tiêu trong nông nghiệp hoặc làm nước tinh khiết.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(
      String imagePath, String title, String subtitle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.asset(imagePath),
            ),
          ),
        );
      },
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        leading: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

Future<void> _deleteCurrentUserAndLogout(BuildContext context) async {
  try {
    await _deleteImage(userLogin.id);
    await FirebaseFirestore.instance
        .collection('auths')
        .doc(userLogin.id)
        .delete();
    final usersQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('createById', isEqualTo: userLogin.id)
        .get();
    for (final doc in usersQuerySnapshot.docs) {
      await _deleteImage(doc['id']);
      await doc.reference.delete();
    }

    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tài khoản và những thông tin của bạn đã được xóa!'),
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  } catch (e) {
    print('Error deleting user: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Xảy ra lỗi khi xóa tài khoản'),
      ),
    );
  }
}

Future<void> _deleteRow(BuildContext context, String id) async {
  try {
    await _deleteImage(id);
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    await docRef.delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xóa thông tin thành công')),
    );
  } catch (e) {
    print('Lỗi: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lỗi xóa thông tin')),
    );
  }
}

void _logout(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      );
    },
  );
}
