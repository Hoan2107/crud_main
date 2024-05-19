import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_firebase_crud_app/screens/auth/auth_screen.dart';
import 'package:flutter_firebase_crud_app/screens/map_view/map_view_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings,
                color: Color.fromARGB(255, 2, 101, 28)),
            SizedBox(width: 5),
            Text(
              'Admin',
              style: TextStyle(color: Color.fromARGB(255, 145, 21, 21)),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: ConvexAppBar(
        initialActiveIndex: currentIndex,
        style: TabStyle.react,
        backgroundColor: Colors.green[300]!,
        activeColor: const Color.fromARGB(255, 25, 51, 249),
        color: const Color.fromARGB(255, 79, 22, 22),
        items: const [
          TabItem(icon: Icons.location_on, title: 'Bản đồ người dùng'),
          TabItem(icon: Icons.storage, title: 'Lưu trữ'),
          TabItem(icon: Icons.analytics, title: 'Thống kê'),
          TabItem(icon: Icons.notification_add, title: 'Thông báo'),
          TabItem(icon: Icons.note_add, title: 'Ghi chú'),
          TabItem(icon: Icons.account_circle, title: 'Quản lý tài khoản'),
        ],
        onTap: (int newIndex) {
          setState(() {
            currentIndex = newIndex;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _getBodyForIndex(currentIndex),
    );
  }

  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 0:
        return const MapViewScreen();
      case 1:
        return const StorageScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const NotificationScreen();
      case 4:
        return const LandfillLocationScreen();
      case 5:
        return _buildUserManagementScreen();
      default:
        return Container();
    }
  }

  Widget _buildUserManagementScreen() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản lý người dùng'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildListTile(
            title: 'Đăng xuất',
            leadingIcon: Icons.logout,
            onTap: () {
              _logout(context);
            },
          ),
          _buildListTile(
            title: 'Các người dùng',
            leadingIcon: Icons.account_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllUsersScreen()),
              );
            },
          ),
          _buildListTile(
            title: 'Danh sách các dữ liệu đã được xử lí',
            leadingIcon: Icons.done_all,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProcessedDataScreen()),
              );
            },
          ),
          _buildListTile(
            title: 'Tìm kiếm theo Quận/huyện',
            leadingIcon: Icons.location_city_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchLocation()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData leadingIcon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      leading: Icon(
        leadingIcon,
        size: 28,
      ),
      onTap: onTap,
      tileColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

Future<void> _deleteAuthAndRelatedUsers(
    String authId, void Function() onSuccess) async {
  try {
    await FirebaseFirestore.instance.collection('auths').doc(authId).delete();
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('createById', isEqualTo: authId)
        .get();
    List<Future<void>> deleteTasks = [];
    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;
      deleteTasks.add(_deleteImage(userId));
      deleteTasks.add(userDoc.reference.delete());
    }
    await Future.wait(deleteTasks);

    print('Xóa auth, các users tương ứng và ảnh thành công');
    onSuccess();
  } catch (e) {
    print('Lỗi xóa auth, các users tương ứng và ảnh: $e');
  }
}

Future<void> _deleteImage(String userId) async {
  try {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('$userId.jpg');

    await storageRef.delete();
    print('Xóa ảnh thành công cho người dùng có ID: $userId');
  } catch (e) {
    print('Lỗi xóa ảnh cho người dùng có ID: $userId, $e');
  }
}

class ProcessedDataScreen extends StatefulWidget {
  const ProcessedDataScreen({super.key});

  @override
  _ProcessedDataScreenState createState() => _ProcessedDataScreenState();
}

class _ProcessedDataScreenState extends State<ProcessedDataScreen> {
  late Future<List<Map<String, dynamic>>> _processedData;

  @override
  void initState() {
    super.initState();
    _processedData = _fetchProcessedData();
  }

  Future<List<Map<String, dynamic>>> _fetchProcessedData() async {
    QuerySnapshot processedDataSnapshot =
        await FirebaseFirestore.instance.collection('processed_data').get();
    List<Map<String, dynamic>> processedData = [];

    for (QueryDocumentSnapshot document in processedDataSnapshot.docs) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('auths')
          .doc(data['createById'])
          .get();
      String username = userSnapshot['username'];

      processedData.add({
        'id': data['id'],
        'Waste_Level': data['Waste_Level'],
        'Describe': data['Describe'],
        'Waste_Type': data['Waste_Type'],
        'username': username,
        'processedTimestamp': data['processedTimestamp'],
        'address': data['address'],
      });
    }

    return processedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dữ liệu đã được xử lí'),
        backgroundColor: const Color.fromARGB(255, 255, 207, 102),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _processedData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          } else {
            List<Map<String, dynamic>> processedData = snapshot.data!;
            return ListView.builder(
              itemCount: processedData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(5),
                  elevation: 6,
                  child: ListTile(
                    title: Text('ID: ${processedData[index]['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${processedData[index]['username']}'),
                        Text(
                            'Waste Level: ${processedData[index]['Waste_Level']}'),
                        Text('Describe: ${processedData[index]['Describe']}'),
                        Text(
                            'Waste Type: ${processedData[index]['Waste_Type']}'),
                        Text('Address: ${processedData[index]['address']}'),
                        Text(
                          'Processed Time: ${DateFormat('dd/MM/yyyy HH:mm').format((processedData[index]['processedTimestamp'] as Timestamp).toDate().toLocal())}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class SearchLocation extends StatefulWidget {
  const SearchLocation({super.key});

  @override
  _SearchLocationState createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
  String? selectedDistrict;
  List<Map<String, dynamic>> users = [];
  List<String> allDistricts = [];

  @override
  void initState() {
    super.initState();
    fetchAllDistricts();
  }

  void fetchAllDistricts() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      allDistricts = querySnapshot.docs
          .map((doc) => doc['address']['district'] as String)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quận/Huyện'),
        backgroundColor: const Color.fromARGB(255, 151, 205, 249),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Chọn Quận/Huyện'),
                    content: SingleChildScrollView(
                      child: Column(
                        children: allDistricts
                            .map(
                              (district) => ListTile(
                                title: Text(district),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    selectedDistrict = district;
                                    users = [];
                                  });
                                  filterUsersByDistrict(selectedDistrict!);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(
                  const Color.fromARGB(255, 124, 255, 114)),
            ),
            child: Text(selectedDistrict ?? 'Chọn Quận/Huyện'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 30,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('Người tải lên: ${users[index]['username']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Mức độ chất thải: ${users[index]['Waste_Level']}'),
                        Text('Loại chất thải: ${users[index]['Waste_Type']}'),
                        Text('Mô tả: ${users[index]['Describe']}'),
                        Text('Thời gian: ${users[index]['timestamp']}'),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Image.network(
                            users[index]['imageURL'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void filterUsersByDistrict(String district) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('address.district', isEqualTo: district)
        .get();

    List<Map<String, dynamic>> updatedUsers = [];
    for (var userDoc in querySnapshot.docs) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('auths')
          .doc(userDoc['createById'])
          .get();

      Map<String, dynamic> userData = {
        'username': userSnapshot['username'],
        'Waste_Level': userDoc['Waste_Level'],
        'Waste_Type': userDoc['Waste_Type'],
        'Describe': userDoc['Describe'],
        'timestamp': convertTimestampToVietnameseTime(userDoc['timestamp']),
        'imageURL': userDoc['imageURL'],
      };
      updatedUsers.add(userData);
    }

    setState(() {
      users = updatedUsers;
    });
  }

  String convertTimestampToVietnameseTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate().toLocal();
    return '${dateTime.hour}:${dateTime.minute}, ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class AllUsersScreen extends StatelessWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        title: const Text(
          'Tất cả người dùng',
          style: TextStyle(color: Color.fromARGB(255, 10, 10, 10)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('auths').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Không có người dùng nào'),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String authId = document.id;
              String username = data['username'];
              String role = data['role'];
              if (role == 'admin') {
                return Container();
              }

              return FutureBuilder<int>(
                future: _getDataCount(authId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Đã xảy ra lỗi khi lấy dữ liệu'),
                    );
                  }
                  int dataCount = snapshot.data ?? 0;

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 127, 157, 181),
                            Color.fromARGB(255, 93, 209, 236)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          'Username: $username',
                          style: const TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 14, 14, 14)),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role: $role',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 41, 31, 31)),
                            ),
                            Text(
                              'Số lượng thông tin tải lên: $dataCount',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 41, 31, 31)),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Color.fromARGB(255, 0, 0, 0)),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, authId);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<int> _getDataCount(String authId) async {
    try {
      QuerySnapshot userSnapshots = await FirebaseFirestore.instance
          .collection('users')
          .where('createById', isEqualTo: authId)
          .get();
      int dataCount = userSnapshots.docs.length;
      return dataCount;
    } catch (e) {
      print('Đã xảy ra lỗi khi lấy số lượng dữ liệu: $e');
      return 0;
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String authId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy bỏ'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteAuth(context, authId);
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuth(BuildContext context, String authId) async {
    try {
      await FirebaseFirestore.instance.collection('auths').doc(authId).delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa người dùng thành công'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi khi xóa người dùng'),
        ),
      );
    }
  }
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _selectedDay;
  List<Map<String, dynamic>> _userData = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _fetchData() {
    FirebaseFirestore.instance
        .collection('users')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDay),
            isLessThan:
                Timestamp.fromDate(_selectedDay.add(const Duration(days: 1))))
        .get()
        .then((querySnapshot) {
      if (!_isDisposed) {
        List<Map<String, dynamic>> usersData = [];
        for (var userDoc in querySnapshot.docs) {
          String createById = userDoc['createById'];
          String timestamp = DateFormat('dd/MM/yyyy HH:mm')
              .format((userDoc['timestamp'] as Timestamp).toDate().toLocal());

          bool found = false;
          for (int i = 0; i < usersData.length; i++) {
            if (usersData[i]['createById'] == createById) {
              usersData[i]['count']++;
              usersData[i]['userData'].add(userDoc);
              found = true;
              break;
            }
          }

          if (!found) {
            usersData.add({
              'createById': createById,
              'count': 1,
              'timestamp': timestamp,
              'userData': [userDoc],
            });
          }
        }
        List<Future> getUsernameFutures = [];
        for (var userData in usersData) {
          getUsernameFutures.add(
            FirebaseFirestore.instance
                .collection('auths')
                .doc(userData['createById'])
                .get()
                .then((authDoc) {
              if (!_isDisposed) {
                if (authDoc.exists) {
                  userData['username'] = authDoc['username'];
                  userData['createTimestamp'] = DateFormat('dd/MM/yyyy HH:mm')
                      .format((authDoc['timestamp'] as Timestamp)
                          .toDate()
                          .toLocal());
                }
              }
            }),
          );
        }
        Future.wait(getUsernameFutures).then((_) {
          if (!_isDisposed) {
            setState(() {
              _userData = usersData;
            });
          }
        });
      }
    }).catchError((error) {
      print("Error fetching data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              focusedDay: _selectedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2050),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _userData.clear();
                  _fetchData();
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.green[200],
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Dữ liệu tải lên ngày ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _userData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Không có dữ liệu nào được tải lên trong ngày',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _userData.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            'Username: ${_userData[index]['username']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          subtitle: GestureDetector(
                            onTap: () {
                              _showUserDataDialog(_userData[index]['userData']);
                            },
                            child: Text(
                                'Số lượng dữ liệu: ${_userData[index]['count']}'),
                          ),
                          trailing: Text(
                              'Thời gian tạo tài khoản: ${_userData[index]['createTimestamp']}'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showUserDataDialog(List<DocumentSnapshot> userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thông tin người dùng'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: userData.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text('Dữ liệu ${index + 1}'),
                  subtitle: Text(
                      'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format((userData[index]['timestamp'] as Timestamp).toDate().toLocal())}'),
                  onTap: () {
                    _showUserDataDetailDialog(userData[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showUserDataDetailDialog(DocumentSnapshot userData) {
    bool processed = false;
    FirebaseFirestore.instance
        .collection('processed_data')
        .doc(userData.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          processed = true;
        });
      }
      _showProcessedDataDialog(userData, processed);
    }).catchError((error) {
      print("Error getting processed data: $error");
    });
  }

  void _showProcessedDataDialog(DocumentSnapshot userData, bool processed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Thông tin chi tiết'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Waste_Level: ${userData['Waste_Level']}'),
                  Text('Describe: ${userData['Describe']}'),
                  Text('Waste Type: ${userData['Waste_Type']}'),
                  Text(
                      'Address: ${userData['address']['street']}, ${userData['address']['district']}, ${userData['address']['city']}, ${userData['address']['country']}'),
                  Text(
                      'Thời gian tải lên: ${DateFormat('dd/MM/yyyy HH:mm').format((userData['timestamp'] as Timestamp).toDate().toLocal())}'),
                  userData['imageURL'] != null
                      ? SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Image.network(userData['imageURL'] as String),
                        )
                      : Container(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('processed_data')
                                .doc(userData.id)
                                .set({
                              'processed': true,
                              'timestamp': Timestamp.now(),
                              'Waste_Level': userData['Waste_Level'],
                              'Describe': userData['Describe'],
                              'Waste_Type': userData['Waste_Type'],
                              'address': userData['address'],
                              'id': userData['id'],
                              'createById': userData['createById'],
                              'timestamp': userData['timestamp'],
                              'imageURL': userData['imageURL'],
                              'lat': userData['lat'],
                              'long': userData['long'],
                              'processedTimestamp': Timestamp.now(),
                            });

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userData.id)
                                .delete();

                            setState(() {
                              processed = true;
                            });
                          } catch (error) {
                            print("Error updating processed data: $error");
                          }
                        },
                        child: Row(
                          children: [
                            processed
                                ? const Icon(Icons.check_box)
                                : const Icon(Icons.check_box_outline_blank),
                            const Text('Đã xử lí'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('processed_data')
                                .doc(userData.id)
                                .delete();
                            setState(() {
                              processed = false;
                            });
                          } catch (error) {
                            print("Error deleting processed data: $error");
                          }
                        },
                        child: Row(
                          children: [
                            !processed
                                ? const Icon(Icons.check_box)
                                : const Icon(Icons.check_box_outline_blank),
                            const Text('Chưa xử lí'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  _StorageScreenState createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String _selectedFilter = 'Ít rác thải';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lưu trữ'),
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: <String>['Ít rác thải', 'Nhiều rác thải', 'Không rõ...']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Color.fromARGB(255, 79, 4, 4)),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
          ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(
            255, 255, 255, 255), // Nền trắng để tạo cảm giác sáng sủa
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('Waste_Level', isEqualTo: _selectedFilter)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Đã xảy ra lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                final data = document.data() as Map<String, dynamic>;
                final description = data['Describe'];
                final wasteType = data['Waste_Type'];
                final address = data['address'] as Map<String, dynamic>;
                final photoUrl = data['imageURL'];
                final createById = data['createById'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('auths')
                      .doc(createById)
                      .get(),
                  builder: (context, authSnapshot) {
                    if (authSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container();
                    }
                    if (!authSnapshot.hasData || !authSnapshot.data!.exists) {
                      return Container();
                    }
                    final authData =
                        authSnapshot.data!.data() as Map<String, dynamic>;
                    final username = authData['username'];
                    final timestamp = data['timestamp'] as Timestamp;
                    final uploadTime = timestamp.toDate();
                    final formattedTime = DateFormat('dd/MM/yyyy HH:mm')
                        .format(uploadTime.toLocal());

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: _buildUserAvatar(photoUrl),
                        title: Text(
                          'ID: ${data['id']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Mô tả: $description'),
                            Text('Loại rác thải: $wasteType'),
                            Text(
                              'Địa chỉ: ${address['street']}, ${address['district']}, ${address['city']}, ${address['country']}',
                            ),
                            Text('Thời gian tải lên: $formattedTime'),
                            Text('Người tải lên: $username'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            photoUrl,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          ),
        ),
      );
    } else {
      return const Icon(Icons.account_circle, size: 50);
    }
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _notificationController = TextEditingController();

  Future<void> addNotification(String notification) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'notification': notification,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Future<void> updateNotification(
      String notificationId, String newNotification) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'notification': newNotification,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Các thông báo'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notificationController,
                        decoration: const InputDecoration(
                          labelText: 'Nhập thông báo',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () {
                        addNotification(_notificationController.text);
                        _notificationController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi'));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Không có thông báo nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.green),
                      ),
                      child: ListTile(
                        title: Text(data['notification']),
                        subtitle: Text(
                            'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(data['timestamp'].toDate())}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Sửa thông báo'),
                                      content: TextField(
                                        controller: TextEditingController(
                                            text: data['notification']),
                                        onChanged: (value) {
                                          data['notification'] = value;
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Đóng'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            updateNotification(document.id,
                                                data['notification']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Lưu'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Xác nhận xóa'),
                                      content: const Text(
                                          'Bạn có chắc chắn muốn xóa thông báo này?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Đóng'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            deleteNotification(document.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Xóa'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LandfillLocationScreen extends StatefulWidget {
  const LandfillLocationScreen({Key? key}) : super(key: key);

  @override
  _LandfillLocationScreenState createState() => _LandfillLocationScreenState();
}

class _LandfillLocationScreenState extends State<LandfillLocationScreen> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _imageFile;
  String? _selectedDocumentId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm tập kết rác thải'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _longController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _imageFile != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ảnh',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Image.file(
                              _imageFile!,
                              height: 100,
                            ),
                          ],
                        )
                      : const SizedBox(height: 0),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _getImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Chọn ảnh'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedDocumentId != null
                        ? _updateLandfillLocation
                        : _uploadLandfillLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDocumentId != null
                          ? Colors.orange // Màu sắc khi chỉnh sửa
                          : const Color.fromARGB(
                              255, 78, 165, 81), // Màu sắc khi tải lên mới
                    ),
                    child: Text(
                      _selectedDocumentId != null
                          ? 'Cập nhật thông tin'
                          : 'Tải lên thông tin',
                      style: const TextStyle(
                        color: Colors.white, // Màu chữ
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Text(
                        'Các điểm tập kết rác thải',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0)
                              .withOpacity(1), // Màu chữ với độ mờ
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('landfill_locations')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Đã xảy ra lỗi'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text(
                                'Không tìm thấy điểm tập kết rác thải nào'));
                      }
                      return Column(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          List<dynamic> noteHistory =
                              data['noteHistory'] != null
                                  ? List<dynamic>.from(data['noteHistory'])
                                  : [];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(
                                      'Latitude: ${data['latitude']}, Longitude: ${data['longitude']}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Address: ${data['address']}'),
                                      Text('Note: ${data['note']}'),
                                      if (data['image_landfill'] != null)
                                        Image.network(data['image_landfill']),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          setState(() {
                                            _selectedDocumentId = document.id;
                                            _latController.text =
                                                data['latitude'];
                                            _longController.text =
                                                data['longitude'];
                                            _addressController.text =
                                                data['address'];
                                            _noteController.text = data['note'];
                                            _imageFile = null;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteLandfillLocation(document.id,
                                              data['image_landfill']);
                                        },
                                      ),
                                      if (noteHistory.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.history),
                                          onPressed: () {
                                            _showNoteHistoryDialog(noteHistory);
                                          },
                                        ),
                                    ],
                                  ),
                                  onTap: () {},
                                ),
                                if (noteHistory.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Không có lịch sử ghi chú',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _uploadLandfillLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_latController.text.isEmpty ||
          _longController.text.isEmpty ||
          _addressController.text.isEmpty ||
          _noteController.text.isEmpty ||
          _imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hãy điền đầy đủ thông tin')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String imageUrl = '';
      String imageExtension = _imageFile!.path.split('.').last.toLowerCase();
      if (imageExtension == 'jpg' ||
          imageExtension == 'jpeg' ||
          imageExtension == 'png') {
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('images_landfills/${DateTime.now()}.$imageExtension')
            .putFile(_imageFile!);
        imageUrl = await snapshot.ref.getDownloadURL();
      } else {
        print('Unsupported image format');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('landfill_locations').add({
        'latitude': _latController.text,
        'longitude': _longController.text,
        'address': _addressController.text,
        'note': _noteController.text,
        'image_landfill': imageUrl,
        'timestamp': DateTime.now(),
        'noteHistory': [],
      });

      _latController.clear();
      _longController.clear();
      _addressController.clear();
      _noteController.clear();
      setState(() {
        _imageFile = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải lên thành công vị trí bãi rác')),
      );
    } catch (e) {
      print('Error uploading landfill location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi tải lên vị trí bãi rác')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteLandfillLocation(String docId, String? imageUrl) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (imageUrl != null) {
        await _deleteOldImage(imageUrl);
      }

      await FirebaseFirestore.instance
          .collection('landfill_locations')
          .doc(docId)
          .delete();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa thành công vị trí bãi rác')),
      );
    } catch (e) {
      print('Error deleting landfill location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xóa vị trí bãi rác')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  void _updateLandfillLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_latController.text.isEmpty ||
          _longController.text.isEmpty ||
          _addressController.text.isEmpty ||
          _noteController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hãy điền đầy đủ thông tin')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('landfill_locations')
          .doc(_selectedDocumentId)
          .get();
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      if (_imageFile != null) {
        String imageUrl = '';
        String imageExtension = _imageFile!.path.split('.').last.toLowerCase();
        if (imageExtension == 'jpg' ||
            imageExtension == 'jpeg' ||
            imageExtension == 'png') {
          if (data['image_landfill'] != null) {
            await _deleteOldImage(data['image_landfill']);
          }
          TaskSnapshot snapshot = await FirebaseStorage.instance
              .ref('images_landfills/${DateTime.now()}.$imageExtension')
              .putFile(_imageFile!);
          imageUrl = await snapshot.ref.getDownloadURL();
          data['image_landfill'] = imageUrl;
        } else {
          print('Unsupported image format');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      await FirebaseFirestore.instance
          .collection('landfill_locations')
          .doc(_selectedDocumentId)
          .update({
        'latitude': _latController.text,
        'longitude': _longController.text,
        'address': _addressController.text,
        'note': _noteController.text,
        'image_landfill': data['image_landfill'],
        'timestamp': DateTime.now(),
      });

      _latController.clear();
      _longController.clear();
      _addressController.clear();
      _noteController.clear();
      setState(() {
        _imageFile = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Landfill location updated successfully')));
    } catch (e) {
      print('Error updating landfill location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating landfill location')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNoteHistoryDialog(List<dynamic> noteHistory) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Note History'),
          content: SizedBox(
            width: double.maxFinite,
            child: noteHistory.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: noteHistory.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> historyItem =
                          noteHistory[index] as Map<String, dynamic>;
                      DateTime editedTimestamp =
                          historyItem['editedTimestamp'].toDate();
                      String formattedTimestamp =
                          DateFormat('dd/MM/yyyy HH:mm:ss')
                              .format(editedTimestamp);
                      return ListTile(
                        title: Text('Edited by: ${historyItem['editedBy']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edited timestamp: $formattedTimestamp'),
                            Text('Note: ${historyItem['note']}'),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'Không có lịch sử ghi chú',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
