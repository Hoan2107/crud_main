import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllowFullscreen: true);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Open Street Map',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest:
              URLRequest(url: WebUri("https://inappwebview.dev/")),
          initialSettings: settings,
          onWebViewCreated: (controller) {
            webViewController = controller..loadData(data: _map);
          },
          onLoadStart: (controller, url) {},
          onConsoleMessage: (controller, consoleMessage) {
            if (kDebugMode) {
              print(consoleMessage);
            }
          },
        ),
      ),
    );
  }
}

String _map = """

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenStreetMap with Leaflet</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
    <style>
        html,
        body,
        #map {
            width: 100%;
            height: 80vh;
            margin: 0;
            padding: 0;
        }

        .filter-container {
            margin-top: 20px;
        }

        .custom-icon {
            border-radius: 50%;
            display: block;
        }
        
        .custom-icon-red {
            background-color: red;
            width: 10px;
            height: 10px; 
        }

        .custom-icon-green {
            background-color: #32a852;
            width: 16px; 
            height: 16px; 
        }

        #chartContainer {
            height: 400px;
            width: 80%;
            margin: auto;
        }
    </style>
</head>

<body>
    <div id="map"></div>
    <div class="filter-container">
        <h3>Lọc theo địa chỉ và khoảng thời gian</h3>
        <select id="districtFilter">
            <option value="">Tất cả</option>
        </select>
        <span id="districtCount"></span>
        <select id="timeFilter">
            <option value="">Tất cả</option>
            <option value="00-05">00:00 AM - 5:00 AM</option>
            <option value="05-10">5:00 AM - 10:00 AM</option>
            <option value="10-18">10:00 AM - 6:00 PM</option>
            <option value="18-24">6:00 PM - 11:59 PM</option>
        </select>
        <select id="chartType">
            <option value="bar">Biểu đồ cột</option>
            <option value="line">Biểu đồ đường</option>
            <option value="doughnut">Biểu đồ tròn</option>
        </select>
    </div>

    <div id="chartContainer">
        <canvas id="chartCanvas"></canvas>
    </div>

    <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script type="module">
        import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.0/firebase-app.js';
        import { getFirestore, collection, getDocs } from 'https://www.gstatic.com/firebasejs/9.6.0/firebase-firestore.js';

        // Initialize Firebase
        const firebaseConfig = {
            apiKey: "AIzaSyAQO2BmNaZcast3fRMTUUo7FzvuupdTE0w",
            authDomain: "compact-mystery-420806.firebaseapp.com",
            projectId: "compact-mystery-420806",
            storageBucket: "compact-mystery-420806.appspot.com",
            messagingSenderId: "1072971256470",
            appId: "1:1072971256470:web:530e9f8e8f88f0d29328b7",
            measurementId: "G-0P7FDWKHLJ"
        };
        const firebaseApp = initializeApp(firebaseConfig);
        const db = getFirestore(firebaseApp);

        const map = L.map('map').setView([21.0285, 105.8542], 10);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        const usersRef = collection(db, 'users');
        const landfillLocationsRef = collection(db, 'landfill_locations');

        const districtFilter = document.getElementById('districtFilter');
        const timeFilter = document.getElementById('timeFilter');
        const districtCount = document.getElementById('districtCount');
        const chartCanvas = document.getElementById('chartCanvas');
        const chartTypeSelector = document.getElementById('chartType');

        districtFilter.addEventListener('change', processDataAndDisplayOnMap);
        timeFilter.addEventListener('change', processDataAndDisplayOnMap);
        chartTypeSelector.addEventListener('change', updateChart);
        getDistrictsFromFirestore();

        let chart; 

        async function getDistrictsFromFirestore() {
            const districts = new Set();
            const querySnapshot = await getDocs(usersRef);
            querySnapshot.forEach((doc) => {
                const data = doc.data();
                const address = data.address;
                if (address && address.district) {
                    districts.add(address.district);
                }
            });
            districts.forEach((district) => {
                const option = document.createElement('option');
                option.value = district;
                option.textContent = district;
                districtFilter.appendChild(option);
            });
        }

        async function countAllRecords() {
            const querySnapshot = await getDocs(usersRef);
            return querySnapshot.size;
        }

        function processDataAndDisplayOnMap() {
            const selectedDistrict = districtFilter.value;
            const selectedTimeRange = timeFilter.value;
            map.eachLayer((layer) => {
                if (layer instanceof L.Marker && !layer.isLandfill) {
                    map.removeLayer(layer);
                }
            });

            if (selectedDistrict === '' && selectedTimeRange === '') {
                countAllRecords().then((totalRecords) => {
                    updateDistrictCount(totalRecords);
                    displayAllData();
                });
                map.setView([21.0285, 105.8542], 8);
            } else {
                displayFilteredData(selectedDistrict, selectedTimeRange);
            }
        }

        function displayAllData() {
            getDocs(usersRef).then((querySnapshot) => {
                let count = 0;
                querySnapshot.forEach((doc) => {
                    const data = doc.data();
                    displayUserDataOnMap(data);
                    count++;
                });
                updateDistrictCount(count);
            }).catch((error) => {
                console.log("Error getting documents: ", error);
            });
        }

        function displayFilteredData(selectedDistrict, selectedTime) {
            let startTime = 0;
            let endTime = Number.MAX_SAFE_INTEGER;

            if (selectedTime !== '') {
                const [startHour, endHour] = selectedTime.split('-').map(hourStr => parseInt(hourStr));
                startTime = startHour * 60 * 60 * 1000;
                endTime = endHour * 60 * 60 * 1000;
            }

            getDocs(usersRef).then((querySnapshot) => {
                let count = 0;
                const filteredLocations = [];
                querySnapshot.forEach((doc) => {
                    const data = doc.data();
                    const timestamp = data.timestamp.toMillis();
                    const timeOfDay = (new Date(timestamp)).getHours() * 60 * 60 * 1000;

                    if ((selectedDistrict === '' || data.address.district === selectedDistrict) && timeOfDay >= startTime && timeOfDay <= endTime) {
                        displayUserDataOnMap(data);
                        count++;
                        filteredLocations.push({ lat: parseFloat(data.lat), long: parseFloat(data.long) });
                    }
                });
                if (filteredLocations.length > 0) {
                    zoomToFilteredLocations(filteredLocations);
                }
                updateDistrictCount(count);
            }).catch((error) => {
                console.log("Error getting documents: ", error);
            });
        }

        function zoomToFilteredLocations(locations) {
            if (locations.length === 1) {
                const singleLocation = locations[0];
                map.setView([singleLocation.lat, singleLocation.long], 17); 
            } else if (locations.length > 1) {
                const bounds = L.latLngBounds(locations.map(location => [location.lat, location.long]));
                
                const center = bounds.getCenter();
                map.setView(center, 12);
            }
        }   


        async function displayLandfillLocationsOnMap() {
            getDocs(landfillLocationsRef).then((querySnapshot) => {
                querySnapshot.forEach((doc) => {
                    const data = doc.data();
                    const lat = parseFloat(data.latitude);
                    const long = parseFloat(data.longitude);
                    displayLandfillLocationOnMap(lat, long, data);
                });
            }).catch((error) => {
                console.log("Error getting documents: ", error);
            });
        }

        function displayUserDataOnMap(data) {
    const lat = parseFloat(data.lat);
    const long = parseFloat(data.long);
    const imageURL = data.imageURL;
    let popupContent = '<b>Thông tin người dùng: </b><br>';
    const timestamp = data.timestamp.toDate();
    const localTimestamp = new Date(timestamp.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" }));
    const formattedTime = localTimestamp.toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" });
    popupContent += `<b>Thời gian:</b> \${formattedTime}<br>`;
    popupContent += '<img src="' + imageURL + '" style="max-width: 100px; max-height: 100px; display: block; margin: auto;" />';
    popupContent += `<b>Lượng rác thải:</b> \${data.Waste_Level}<br>`;
    popupContent += `<b>Mô tả:</b> \${data.Describe}<br>`;
    for (const key in data) {
        if (data.hasOwnProperty(key) && key !== 'createById' && key !== 'Describe' && key !== 'Waste_Level' && key !== 'timestamp' && key !== 'Name' && key !== 'lat' && key !== 'long' && key !== 'imageURL' && key !== 'id') {
            const value = data[key];
            if (typeof value === 'object') {
                popupContent += '<b>Địa chỉ:</b><br>';
                for (const addressKey in value) {
                    if (value.hasOwnProperty(addressKey)) {
                        const addressValue = value[addressKey];
                        // Hiển thị các trường địa chỉ bằng tiếng Việt
                        if (addressKey === 'street') {
                            popupContent += `<b>Đường:</b> \${addressValue}<br>`;
                        } else if (addressKey === 'country') {
                            popupContent += `<b>Quốc gia:</b> \${addressValue}<br>`;
                        } else if (addressKey === 'city') {
                            popupContent += `<b>Thành phố:</b> \${addressValue}<br>`;
                        } else if (addressKey === 'district') {
                            popupContent += `<b>Quận:</b> \${addressValue}<br>`;
                        } 
                    }
                }
            } else {
                if (key === 'Waste_Type') {
                    popupContent += `<b>Loại rác:</b> \${value}<br>`;
                } else {
                    popupContent += `<b>\${key}:</b> \${value}<br>`;
                }
            }
        }
    }
    const marker = L.marker([lat, long], { icon: createRedIcon() }).addTo(map).bindPopup(popupContent);
}

    function displayLandfillLocationOnMap(lat, long, landfillData) {
    const marker = L.marker([lat, long], { icon: createGreenIcon() }).addTo(map);
    let popupContent = '<b>Điểm tập kết rác thải</b><br>';
    for (const key in landfillData) {
        if (landfillData.hasOwnProperty(key) && key !== 'latitude' && key !== 'note' && key !== 'longitude') {
            const value = landfillData[key];
            if (key === 'timestamp') {
                const timestamp = new Date(value.toMillis()).toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" });
                popupContent += `<b>Thời gian:</b> \${timestamp}<br>`;
            } else if (key === 'address') {
                popupContent += `<b>Địa chỉ:</b> \${value}<br>`;
            } else if (key === 'noteHistory') {
                popupContent += `<b>Lịch sử bình luận:</b><br>`;
                value.forEach((note, index) => {
                    popupContent += `<b>Bình luận thứ: \${index + 1}</b><br>`;
                    popupContent += `<b>Từ người dùng:</b> \${note.editedBy}<br>`;
                    const editedTimestamp = new Date(note.editedTimestamp.toMillis()).toLocaleString("en-US", { timeZone: "Asia/Ho_Chi_Minh" });
                    popupContent += `<b>Thời gian bình luận:</b> \${editedTimestamp}<br>`;
                    popupContent += `<b>Lời bình luận:</b> \${note.note}<br>`;
                });
            } else if (key === 'image_landfill') {
                  if (value) {
                      popupContent += `<b>Ảnh địa điểm tập kết rác thải:</b><br>`;
                      popupContent += `<img src="\${value}" style="max-width:100px; max-height:100px;"><br>`;
                  }
              } else {
                  popupContent += `<b> \${key}:</b>\${value}<br>`;
              }
          }
      }
    marker.bindPopup(popupContent).on('click', function (e) {
        this.openPopup();
    });
    marker.isLandfill = true;
}



    function createRedIcon() {
        return L.divIcon({
            className: 'custom-icon custom-icon-red',
            iconSize: [10, 10], 
            iconAnchor: [6, 6],
            popupAnchor: [0, -4]
        });
    }

   function createGreenIcon() {
    return L.icon({
        iconUrl: 'https://compact-mystery-420806.web.app/assets/assets/waste.png', //
        iconSize: [16, 16], 
        iconAnchor: [8, 8], 
        popupAnchor: [0, -8] 
    });
}


    function updateDistrictCount(count) {
        districtCount.textContent = ` (\${count} dữ liệu)`;
    }

        // Trích xuất dữ liệu từ bảng "users"
    async function getDataForCharts() {
        const querySnapshot = await getDocs(usersRef);
        const data = {
            oneDay: 0,
            sevenDays: 0,
            thirtyDays: 0,
            all: querySnapshot.size
        };

        const currentDate = new Date();
        const oneDayAgo = new Date(currentDate);
        oneDayAgo.setDate(oneDayAgo.getDate() - 1);
        const sevenDaysAgo = new Date(currentDate);
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const thirtyDaysAgo = new Date(currentDate);
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        querySnapshot.forEach((doc) => {
            const userData = doc.data();
            const timestamp = userData.timestamp.toDate();

            if (timestamp > oneDayAgo) {
                data.oneDay++;
            }

            if (timestamp > sevenDaysAgo) {
                data.sevenDays++;
            }

            if (timestamp > thirtyDaysAgo) {
                data.thirtyDays++;
            }
        });

        return data;
    }


    async function updateChart() {
    const selectedChartType = chartTypeSelector.value;
    if (chart) {
        chart.destroy(); 
    }

    const data = await getDataForCharts();

    chart = createChart(selectedChartType, data);
}   

function createChart(chartType, data) {
    const labels = ['1 ngày trước', '7 ngày trước', '30 ngày trước', 'Tất cả'];
    const datasetData = [data.oneDay, data.sevenDays, data.thirtyDays, data.all];
    const backgroundColors = [
        'rgba(255, 99, 132, 0.6)',
        'rgba(54, 162, 235, 0.6)',
        'rgba(255, 206, 86, 0.6)',
        'rgba(75, 192, 192, 0.6)'
    ];

    return new Chart(chartCanvas, {
        type: chartType,
        data: {
            labels: labels,
            datasets: [{
                label: 'Số lượng',
                data: datasetData,
                backgroundColor: backgroundColors,
                borderColor: backgroundColors.map(color => color.replace('0.6', '1')), // Set border colors
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: true
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Biểu đồ số lượng dữ liệu chưa được xử lí theo thời gian'
                },
                legend: {
                    display: true,
                    labels: {
                        font: {
                            size: 14
                        },
                        // Customize colors for legend labels
                        generateLabels: function(chart) {
                            const data = chart.data;
                            if (data.labels.length && data.datasets.length) {
                                return data.labels.map(function(label, i) {
                                    return {
                                        text: label,
                                        fillStyle: backgroundColors[i] // Use background colors for labels
                                    };
                                });
                            }
                            return [];
                        }
                    }
                }
            }
        }
    });
}



    chartTypeSelector.addEventListener('change', updateChart);



        displayLandfillLocationsOnMap();
        processDataAndDisplayOnMap();
        updateChart();

    </script>
</body>

</html>


""";
