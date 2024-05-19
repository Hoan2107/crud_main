// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getStorage } from "firebase/storage";
import { getFirestore } from "firebase/firestore";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyAQO2BmNaZcast3fRMTUUo7FzvuupdTE0w",
  authDomain: "compact-mystery-420806.firebaseapp.com",
  projectId: "compact-mystery-420806",
  storageBucket: "compact-mystery-420806.appspot.com",
  messagingSenderId: "1072971256470",
  appId: "1:1072971256470:web:1fd0e2d50054f48a9328b7",
  measurementId: "G-5MDD2BR4PL"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const storage = getStorage(app);
const firestore = getFirestore(app);