import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_crud_app/screens/auth/auth_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

class AddressModel {
  String Name;
  String street;
  String city;
  String country;
  String district;

  AddressModel(
      {this.Name = "",
      this.street = "",
      this.district = "",
      this.city = "",
      this.country = ""});

  factory AddressModel.fromLocation(Placemark data) {
    return AddressModel(
        Name: data.name ?? "",
        street: data.street ?? "",
        city: data.administrativeArea ?? "",
        district: data.subAdministrativeArea ?? "",
        country: data.country ?? "");
  }
  AddressModel.fromJson(Map<String, dynamic> json)
      : Name = json['Name'] ?? "",
        street = json['street'] ?? "",
        district = json['district'] ?? "",
        city = json['city'] ?? "",
        country = json['country'] ?? "";

  Map<String, dynamic> toJson() => {
        'Name': Name,
        'street': street,
        'district': district,
        'city': city,
        'country': country,
      };
}

class UserData {
  String Waste_Type;
  String Describe;
  String Waste_Level;
  String id;
  String lat;
  String long;
  String imageURL;
  String createById;
  DateTime timestamp;
  AddressModel? address;

  UserData({
    this.Waste_Type = "",
    this.Describe = "",
    this.Waste_Level = "",
    this.id = "",
    this.lat = "",
    this.long = "",
    this.address,
    this.imageURL = "",
    this.createById = "",
    required this.timestamp,
  });

  factory UserData.fromFirestore(firebase.DocumentSnapshot? doc) {
    if (doc == null) return UserData(timestamp: DateTime.now());

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data?['timestamp'] != null) {
      return UserData(
        Waste_Type: data?['Waste_Type'] ?? '',
        Describe: data?['Describe'] ?? '',
        Waste_Level: data?['Waste_Level'] ?? '',
        id: doc.id ?? '',
        lat: data?['lat'] ?? '',
        long: data?['long'] ?? '',
        address: AddressModel.fromJson(data?['address'] ?? {}),
        imageURL: data?['imageURL'] ?? '',
        createById: data?["createById"] ?? '',
        timestamp: (data?['timestamp'] as firebase.Timestamp).toDate(),
      );
    } else {
      return UserData(
        Waste_Type: data?['Waste_Type'] ?? '',
        Describe: data?['Describe'] ?? '',
        Waste_Level: data?['Waste_Level'] ?? '',
        id: doc.id ?? '',
        lat: data?['lat'] ?? '',
        long: data?['long'] ?? '',
        address: AddressModel.fromJson(data?['address'] ?? {}),
        imageURL: data?['imageURL'] ?? '',
        createById: data?["createById"] ?? '',
        timestamp: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'Waste_Type': Waste_Type,
      'Describe': Describe,
      'Waste_Level': Waste_Level,
      'id': id,
      'lat': lat,
      'long': long,
      'imageURL': imageURL,
      'createById': createById,
      'address': address?.toJson(),
      'timestamp': firebase.Timestamp.fromDate(timestamp),
    };
  }
}

class SendOrUpdateData extends StatefulWidget {
  final UserData userData;

  const SendOrUpdateData({super.key, required this.userData});

  @override
  State<SendOrUpdateData> createState() => _SendOrUpdateDataState();
}

class _SendOrUpdateDataState extends State<SendOrUpdateData> {
  TextEditingController Waste_TypeController = TextEditingController();
  TextEditingController DescribeController = TextEditingController();
  TextEditingController Waste_LevelControleer = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  var isLoading = false;
  final gemini = Gemini.instance;
  String? result = "";
  loading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  MapController mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
    enableTracking: true,
    unFollowUser: true,
  ));
  void processImage(File? image) async {
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      gemini.textAndImage(
          text:
              "Hãy phân tích hình ảnh sau và cho tôi kết quả ngắn gọn gồm trong ảnh có nhiều rác hay ít rác và hãy phân loại liệt kê ra đó gồm những loại rác thải gì và nó thuộc nhóm rác thải nào: Rác hữu cơ, Rác nhựa, Rác kim loại, Rác thủy tinh, Rác vô cơ, Rác độc hại, Rác điện tử, Rác tổng hợp ? nếu không phải rác thải thì trả về kết quả là không phải rác thải kèm theo mô tả tại sao không phải là rác thải",
          images: [imageData]).then((value) {
        setState(() {
          result = value?.content?.parts?.last.text!.trim();
        });
      });
    }
  }

  @override
  void initState() {
    Waste_TypeController.text = widget.userData.Waste_Type;
    DescribeController.text = widget.userData.Describe;
    Waste_LevelControleer.text = widget.userData.Waste_Level;
    mapController.listenerMapSingleTapping.addListener(() {
      final point = mapController.listenerMapSingleTapping.value;
      if (point != null) {
        _selectPoint(point);
      }
    });
    initMapForEdit();
    super.initState();
  }

  initMapForEdit() async {
    if (widget.userData.lat.isNotEmpty && widget.userData.long.isNotEmpty) {
      final lat = double.parse(widget.userData.lat);
      final long = double.parse(widget.userData.long);
      locationLat = lat;
      locationLong = long;
      locationController.text = 'Vĩ độ: $lat Kinh độ:$long';
      Future.delayed(const Duration(milliseconds: 500), () async {
        await mapController
            .changeLocation(GeoPoint(latitude: lat, longitude: long));
      });
    }
  }

  _selectPoint(GeoPoint point) {
    mapController
        .removeMarker(GeoPoint(latitude: locationLat, longitude: locationLong));
    mapController.addMarker(point,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_history_rounded,
            color: Color.fromARGB(255, 222, 25, 25),
            size: 48,
          ),
        ));
    locationLat = point.latitude;
    locationLong = point.longitude;
    locationController.text =
        'Vĩ độ: ${point.latitude} Kinh độ:${point.longitude}';
  }

  @override
  void dispose() {
    Waste_TypeController.dispose();
    DescribeController.dispose();
    Waste_LevelControleer.dispose();
    locationController.dispose();
    mapController.dispose();
    super.dispose();
  }

  double locationLat = 0;
  double locationLong = 0;

  Future<void> getLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      try {
        geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );
        setState(() {
          locationLat = position.latitude;
          locationLong = position.longitude;
          locationController.text =
              'Vĩ độ: ${position.latitude} Kinh độ:${position.longitude}';
        });
        await mapController.changeLocation(GeoPoint(
            latitude: position.latitude, longitude: position.longitude));
      } catch (e) {
        print('Lỗi khi nhận vị trí: $e');
      }
    } else {}
  }

  Future<void> _getImage() async {
    result = null;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      processImage(_image);
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _deleteImage(String docID) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$docID.jpg');

      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa ảnh thành công')),
      );
    } catch (e) {
      print('Lỗi xóa hình ảnh khỏi bộ nhớ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi xóa hình ảnh')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 127, 166, 234),
        centerTitle: true,
        title: const Text(
          'Gửi dữ liệu',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: Container(
        child: Stack(
          children: [
            _renderContent(context),
            isLoading ? const ProgressIndicatorExample() : Container(),
          ],
        ),
      ),
    );
  }

  final TextEditingController wasteLevelController = TextEditingController();
  final List<String> options = ['Ít rác thải', 'Nhiều rác thải', 'Không rõ...'];
  final TextEditingController wasteTypeController = TextEditingController();
  final List<String> wasteTypes = [
    'Rác hữu cơ (Organic waste)',
    'Rác nhựa (Plastic waste)',
    'Rác gỗ (Wood waste)',
    'Rác kim loại (Metal waste)',
    'Rác thủy tinh (Glass waste)',
    'Rác vô cơ (Inorganic waste)',
    'Rác độc hại (Hazardous waste)',
    'Rác điện tử (E-waste)',
    'Rác tổng hợp (Mixed waste)',
    'Không rõ...'
  ];
  SingleChildScrollView _renderContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20)
          .copyWith(top: 60, bottom: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waste_type',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return wasteTypes.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                widget.userData.Waste_Type = selection;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: true,
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    controller.clear();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Chọn loại rác thải',
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Describe',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextField(
            controller: DescribeController,
            decoration: const InputDecoration(
                hintText: 'Mô tả về tình trạng rác thải và chú thích:'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Waste level',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return options.where((String option) {
                return option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                widget.userData.Waste_Level = selection;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: true,
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    controller.clear();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Chọn lượng rác thải tương ứng',
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (result == null && _image != null)
            const Text("Đang phân tích hình ảnh..."),
          if (result != null) Text(result!),
          _image != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    Image.file(_image!, height: 100),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _getImage,
                          child: const Text(
                              'Chọn ảnh mới'), // Label được thêm vào đây
                        ),
                      ],
                    ),
                  ],
                )
              : widget.userData.imageURL.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          widget.userData.imageURL,
                          height: 100,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _getImage,
                              icon: const Icon(Icons.edit),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _getImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn ảnh'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 1, 1, 1),
                      ),
                    ),
          ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(255, 5, 5, 5),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ElevatedButton.icon(
                onPressed: getLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('GET LOCATION'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 23, 132, 17),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: OSMFlutter(
                controller: mapController,
                onLocationChanged: (p0) {
                  print(p0);
                },
                onMapIsReady: (p0) {
                  print('map is readly$p0');
                },
                osmOption: OSMOption(
                  userTrackingOption: const UserTrackingOption(
                    enableTracking: true,
                    unFollowUser: false,
                  ),
                  zoomOption: const ZoomOption(
                    initZoom: 10,
                    minZoomLevel: 8,
                    maxZoomLevel: 19,
                    stepZoom: 5.0,
                  ),
                  userLocationMarker: UserLocationMaker(
                    personMarker: const MarkerIcon(
                      icon: Icon(
                        Icons.location_history_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                    directionArrowMarker: const MarkerIcon(
                      icon: Icon(
                        Icons.double_arrow,
                        size: 60,
                      ),
                    ),
                  ),
                  roadConfiguration: const RoadOption(
                    roadColor: Colors.yellowAccent,
                  ),
                  markerOption: MarkerOption(
                      defaultMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.person_pin_circle,
                      color: Color.fromARGB(255, 215, 4, 4),
                      size: 56,
                    ),
                  )),
                )),
          ),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              hintText: 'Location',
              enabled: false,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              await submitData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 220, 91, 91),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.cloud_upload,
              color: Colors.white,
            ),
            label: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Tải lên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      processImage(_image);
    }
  }

  Future<void> submitData(BuildContext context) async {
    loading(true);
    String selectedOption = widget.userData.Waste_Level;
    String selectedWasteType = widget.userData.Waste_Type;

    if (selectedOption.isEmpty || selectedWasteType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy điền đầy đủ thông tin')),
      );
      loading(false);
    } else {
      final dUser = firebase.FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userData.id.isNotEmpty ? widget.userData.id : null);
      String docID = '';
      if (widget.userData.id.isNotEmpty) {
        docID = widget.userData.id;
      } else {
        docID = dUser.id;
      }

      AddressModel? andress;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(locationLat, locationLong);

      if (placemarks.isNotEmpty) {
        andress = AddressModel.fromLocation(placemarks.first);
      }

      final jsonData = UserData(
        createById: userLogin.id,
        Waste_Type: selectedWasteType,
        Describe: DescribeController.text,
        Waste_Level: selectedOption,
        lat: locationLat.toString(),
        address: andress,
        long: locationLong.toString(),
        id: docID,
        timestamp: DateTime.now(),
      );

      if (widget.userData.id.isNotEmpty) {
        jsonData.createById = widget.userData.createById;
      }

      final newImageURL = await _updateImage(_image, docID);
      if (newImageURL != null) {
        jsonData.imageURL = newImageURL;
      }

      if (_image != null && newImageURL == null) {
        final newImageURL = await _updateImage(_image, docID);
        if (newImageURL != null) {
          jsonData.imageURL = newImageURL;
        }
      }

      if (widget.userData.id.isEmpty) {
        await dUser.set(jsonData.toJson()).then((value) {
          Waste_TypeController.text = '';
          DescribeController.text = '';
          Waste_LevelControleer.text = '';
          locationController.text = '';
          _image = null;
          setState(() {});
        });
      } else {
        await dUser.update(jsonData.toJson()).then((value) {
          Waste_TypeController.text = '';
          DescribeController.text = '';
          Waste_LevelControleer.text = '';
          locationController.text = '';
          setState(() {});
        });
      }
      loading(false);
    }
  }
}

Future<String?> _updateImage(File? newImage, String docID) async {
  if (newImage != null) {
    try {
      List<int> compressedImage = await FlutterImageCompress.compressWithList(
        newImage.readAsBytesSync(),
        minHeight: 1920,
        minWidth: 1080,
        quality: 90,
      );
      Uint8List compressedImageData = Uint8List.fromList(compressedImage);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$docID.jpg');

      await storageRef.putData(compressedImageData);

      final imageURL = await storageRef.getDownloadURL();
      return imageURL;
    } catch (e) {
      print('Lỗi khi cập nhật ảnh lên Storage: $e');
      return null;
    }
  }

  return null;
}
