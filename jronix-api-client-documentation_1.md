

# Jronix API Client — Internal Postman Clone
## Full Step-by-Step Development Documentation

**Stack:** Flutter (Desktop) + GetX (state management) + Node.js + Express + MongoDB

**Purpose:** Internal API testing tool for ~100 company users. Supports HTTP methods (GET, POST, PUT, PATCH, DELETE), headers, body types, token/auth management, WebSocket, and Socket.IO — with collections that persist permanently on a company server.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Database Schema (MongoDB)](#4-database-schema-mongodb)
5. [Local Storage Schema (Hive)](#5-local-storage-schema-hive)
6. [Backend — Step by Step (Node.js + Express + MongoDB)](#6-backend--step-by-step-nodejs--express--mongodb)
7. [Frontend — Step by Step (Flutter + GetX)](#7-frontend--step-by-step-flutter--getx)
8. [Core Feature Implementation](#8-core-feature-implementation)
9. [Sync Engine (Local ⇄ Server)](#9-sync-engine-local--server)
10. [Security](#10-security)
11. [Deployment](#11-deployment)
12. [Phased Roadmap](#12-phased-roadmap)
13. [Folder Structure Reference](#13-folder-structure-reference)

---

## 1. System Overview

### 1.1 Required features (Phase 1)

- HTTP request builder: GET, POST, PUT, PATCH, DELETE
- Headers, Query Params, Path Params
- Body types: raw JSON, form-data, x-www-form-urlencoded, file upload
- Auth: Bearer Token, API Key, Basic Auth
- Response viewer: JSON pretty-print, headers, status, time, size
- Request History
- Collections & Folders
- Environments & Variables (Dev / Staging / Production)
- WebSocket client (connect, send, receive, log)
- Socket.IO client (connect, emit, listen, log)
- Company login (JWT) so collections are tied to accounts, not devices
- Server-side permanent storage (MongoDB) — this is what fixes the "expires after 1 month" problem
- Role-based access: Admin / Manager / Developer / Viewer

### 1.2 Skip in V1

- Pre-request / test scripts (JS sandbox)
- Mock servers
- Proxy & custom SSL/TLS certs
- GraphQL (Phase 2 if needed)

---

## 2. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Desktop UI | **Flutter Desktop** (Windows/macOS/Linux) | Single codebase |
| State management | **GetX** | Reactive `.obs`, built-in routing + dependency injection, less boilerplate |
| HTTP client | **Dio** | Interceptors, multipart/file upload, full header control |
| WebSocket | `web_socket_channel` | Official Dart package |
| Socket.IO client | `socket_io_client` | Matches Socket.IO protocol |
| Local DB | **Hive** | JSON-shaped local cache, fits MongoDB's document model naturally |
| Secure storage | `flutter_secure_storage` | JWT tokens in OS keychain |
| Backend | **Node.js + Express** | You already know this from MERN |
| Backend DB | **MongoDB** (Mongoose ODM) | Flexible schema — headers/body/params map naturally to JSON documents |
| Auth | JWT (access + refresh token) | Standard for ~100 internal users |
| Realtime (optional) | Socket.IO on backend | Live team sync of collection updates |
| Validation | `express-validator` | Request body validation |

---

## 3. Architecture

```
                    ┌───────────────────────────┐
                    │      Flutter Desktop        │
                    │   (GetX state management)   │
                    └──────────────┬───────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
   HTTP Client               WebSocket Client           Socket.IO Client
     (Dio)                 (web_socket_channel)          (socket_io_client)
        │                          │                          │
        └──────────────────────────┼──────────────────────────┘
                                   │
                                   ▼
                            Local Hive Cache
                                   │
                              Sync Engine
                                   │
                                   ▼
                       Jronix Backend (Express + JWT)
                                   │
                                   ▼
                              MongoDB
              (Users, Workspaces, Collections, Requests,
               Environments, Variables, History)
```

**Why local + server, not server-only:**
- Local cache → instant UI, works offline, no network lag on every click.
- MongoDB server → permanent source of truth. This is what solves the "collection disappears" problem — new laptop, reinstalled app, wiped OS, doesn't matter, login and it's all there.

---

## 4. Database Schema (MongoDB)

Mongoose schemas. MongoDB's document model fits this app well — headers, params, and body are naturally nested JSON, no need to normalize into separate relational tables.

### 4.1 User

```javascript
// models/User.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['admin', 'manager', 'developer', 'viewer'], default: 'developer' },
  refreshTokenHash: { type: String }, // for revocation
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
```

### 4.2 Workspace

```javascript
// models/Workspace.js
const workspaceSchema = new mongoose.Schema({
  name: { type: String, required: true },
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  members: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    role: { type: String, enum: ['admin', 'manager', 'developer', 'viewer'], default: 'developer' },
  }],
}, { timestamps: true });

module.exports = mongoose.model('Workspace', workspaceSchema);
```

### 4.3 Collection (folder tree)

```javascript
// models/Collection.js
const collectionSchema = new mongoose.Schema({
  name: { type: String, required: true },
  workspace: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },
  parentFolder: { type: mongoose.Schema.Types.ObjectId, ref: 'Collection', default: null },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('Collection', collectionSchema);
```

### 4.4 Request

```javascript
// models/Request.js
const requestSchema = new mongoose.Schema({
  name: { type: String, required: true },
  collection: { type: mongoose.Schema.Types.ObjectId, ref: 'Collection', required: true },

  requestKind: { type: String, enum: ['http', 'websocket', 'socketio'], default: 'http' },
  method: { type: String, enum: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }, // only for http

  url: { type: String, required: true },

  headers: [{ key: String, value: String, enabled: { type: Boolean, default: true } }],
  queryParams: [{ key: String, value: String, enabled: { type: Boolean, default: true } }],

  bodyType: { type: String, enum: ['none', 'raw-json', 'form-data', 'urlencoded', 'file'], default: 'none' },
  body: { type: mongoose.Schema.Types.Mixed, default: {} }, // flexible — raw JSON, form fields, etc.

  authType: { type: String, enum: ['none', 'bearer', 'api-key', 'basic'], default: 'none' },
  authConfig: { type: mongoose.Schema.Types.Mixed, default: {} },

  // For WebSocket / Socket.IO requests
  socketConfig: {
    namespace: String,
    events: [String],      // list of event names to listen for (Socket.IO)
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('Request', requestSchema);
```

### 4.5 Environment & Variables

```javascript
// models/Environment.js
const environmentSchema = new mongoose.Schema({
  name: { type: String, required: true }, // Development, Staging, Production
  workspace: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace', required: true },
  variables: [{
    key: { type: String, required: true },
    value: { type: String },
    isSecret: { type: Boolean, default: false }, // encrypted at rest, masked in UI
  }],
}, { timestamps: true });

module.exports = mongoose.model('Environment', environmentSchema);
```

### 4.6 Request History

```javascript
// models/History.js
const historySchema = new mongoose.Schema({
  request: { type: mongoose.Schema.Types.ObjectId, ref: 'Request' },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  statusCode: Number,
  responseTimeMs: Number,
  responseSizeBytes: Number,
  executedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('History', historySchema);
```

**Why `Mixed` type for body/authConfig:** different requests have very different body shapes (JSON object, form fields, file refs), so forcing a rigid sub-schema fights against Mongo's strengths. `Mixed` keeps it flexible — validate shape at the Express layer with `express-validator` before saving.

---

## 5. Local Storage Schema (Hive)

Mirror structure with a `syncStatus` field:

```dart
// models/local_request_model.dart
@HiveType(typeId: 1)
class LocalRequestModel {
  @HiveField(0) String id;
  @HiveField(1) String collectionId;
  @HiveField(2) String name;
  @HiveField(3) String method;
  @HiveField(4) String url;
  @HiveField(5) List<Map<String, dynamic>> headers;
  @HiveField(6) Map<String, dynamic> body;
  @HiveField(7) String authType;
  @HiveField(8) Map<String, dynamic> authConfig;
  @HiveField(9) String requestKind;
  @HiveField(10) DateTime updatedAt;
  @HiveField(11) String syncStatus; // synced, pending, conflict

  LocalRequestModel({
    required this.id, required this.collectionId, required this.name,
    required this.method, required this.url, required this.headers,
    required this.body, required this.authType, required this.authConfig,
    required this.requestKind, required this.updatedAt, this.syncStatus = 'pending',
  });
}
```

Hive is a good fit here since MongoDB documents map almost 1:1 to Hive objects (both are JSON-like) — less friction than mapping to relational tables.

---

## 6. Backend — Step by Step (Node.js + Express + MongoDB)

### Step 1: Project setup

```bash
mkdir jronix-backend && cd jronix-backend
npm init -y
npm install express mongoose dotenv cors helmet
npm install jsonwebtoken bcrypt
npm install express-validator
npm install socket.io          # for optional live team-sync gateway
npm install -D nodemon
```

### Step 2: Folder structure

```
jronix-backend/
├── src/
│   ├── config/
│   │   └── db.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Workspace.js
│   │   ├── Collection.js
│   │   ├── Request.js
│   │   ├── Environment.js
│   │   └── History.js
│   ├── middleware/
│   │   ├── auth.middleware.js       # verifies JWT
│   │   ├── role.middleware.js       # checks role permissions
│   │   └── error.middleware.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── workspace.controller.js
│   │   ├── collection.controller.js
│   │   ├── request.controller.js
│   │   ├── environment.controller.js
│   │   ├── history.controller.js
│   │   └── sync.controller.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── workspace.routes.js
│   │   ├── collection.routes.js
│   │   ├── request.routes.js
│   │   ├── environment.routes.js
│   │   ├── history.routes.js
│   │   └── sync.routes.js
│   ├── sockets/
│   │   └── syncGateway.js
│   └── app.js
├── server.js
└── .env
```

### Step 3: DB connection

```javascript
// src/config/db.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection failed:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
```

### Step 4: Auth middleware (JWT)

```javascript
// src/middleware/auth.middleware.js
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    req.user = decoded; // { id, role }
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

module.exports = authMiddleware;
```

### Step 5: Role middleware

```javascript
// src/middleware/role.middleware.js
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient permissions' });
    }
    next();
  };
}

module.exports = requireRole;
```

### Step 6: Auth controller (register/login/refresh)

```javascript
// src/controllers/auth.controller.js
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.register = async (req, res) => {
  const { name, email, password } = req.body;
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ name, email, passwordHash });
  res.status(201).json({ id: user._id, email: user.email });
};

exports.login = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const accessToken = jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '15m' }
  );
  const refreshToken = jwt.sign(
    { id: user._id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '30d' }
  );

  user.refreshTokenHash = await bcrypt.hash(refreshToken, 10);
  await user.save();

  res.json({ accessToken, refreshToken, user: { id: user._id, name: user.name, role: user.role } });
};

exports.refresh = async (req, res) => {
  const { refreshToken } = req.body;
  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = await User.findById(decoded.id);
    const isValid = user && await bcrypt.compare(refreshToken, user.refreshTokenHash);
    if (!isValid) return res.status(401).json({ message: 'Invalid refresh token' });

    const accessToken = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: '15m' }
    );
    res.json({ accessToken });
  } catch {
    res.status(401).json({ message: 'Invalid or expired refresh token' });
  }
};
```

### Step 7: Request controller (CRUD example)

```javascript
// src/controllers/request.controller.js
const RequestModel = require('../models/Request');

exports.createRequest = async (req, res) => {
  const request = await RequestModel.create({ ...req.body, createdBy: req.user.id });
  res.status(201).json(request);
};

exports.getRequestsByCollection = async (req, res) => {
  const requests = await RequestModel.find({ collection: req.params.collectionId });
  res.json(requests);
};

exports.updateRequest = async (req, res) => {
  const updated = await RequestModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(updated);
};

exports.deleteRequest = async (req, res) => {
  await RequestModel.findByIdAndDelete(req.params.id);
  res.status(204).send();
};
```

### Step 8: Routes

```javascript
// src/routes/request.routes.js
const router = require('express').Router();
const auth = require('../middleware/auth.middleware');
const requireRole = require('../middleware/role.middleware');
const ctrl = require('../controllers/request.controller');

router.use(auth);
router.get('/collection/:collectionId', ctrl.getRequestsByCollection);
router.post('/', ctrl.createRequest);
router.patch('/:id', ctrl.updateRequest);
router.delete('/:id', requireRole('admin', 'manager'), ctrl.deleteRequest);

module.exports = router;
```

### Step 9: Sync endpoint

```javascript
// src/controllers/sync.controller.js
const RequestModel = require('../models/Request');
const Collection = require('../models/Collection');

exports.sync = async (req, res) => {
  const { lastSyncedAt, pendingChanges } = req.body;

  // 1. Apply incoming local changes (last-write-wins by updatedAt)
  for (const change of pendingChanges) {
    const { entityType, id, data, updatedAt } = change;
    const Model = entityType === 'request' ? RequestModel : Collection;
    const existing = await Model.findById(id);

    if (!existing || new Date(updatedAt) >= existing.updatedAt) {
      await Model.findByIdAndUpdate(id, data, { upsert: true });
    }
  }

  // 2. Return everything server-side that changed since lastSyncedAt
  const serverRequests = await RequestModel.find({ updatedAt: { $gt: new Date(lastSyncedAt) } });
  const serverCollections = await Collection.find({ updatedAt: { $gt: new Date(lastSyncedAt) } });

  res.json({
    serverChanges: { requests: serverRequests, collections: serverCollections },
    syncedAt: new Date(),
  });
};
```

### Step 10: app.js wiring

```javascript
// src/app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

app.use('/auth', require('./routes/auth.routes'));
app.use('/workspaces', require('./routes/workspace.routes'));
app.use('/collections', require('./routes/collection.routes'));
app.use('/requests', require('./routes/request.routes'));
app.use('/environments', require('./routes/environment.routes'));
app.use('/history', require('./routes/history.routes'));
app.use('/sync', require('./routes/sync.routes'));

module.exports = app;
```

```javascript
// server.js
require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');

connectDB().then(() => {
  app.listen(process.env.PORT || 4000, () => {
    console.log(`Jronix backend running on port ${process.env.PORT || 4000}`);
  });
});
```

### Step 11: Optional Socket.IO gateway (live team updates)

```javascript
// src/sockets/syncGateway.js
const { Server } = require('socket.io');

function initSyncGateway(httpServer) {
  const io = new Server(httpServer, { cors: { origin: '*' } });

  io.on('connection', (socket) => {
    socket.on('join-workspace', (workspaceId) => socket.join(workspaceId));
    socket.on('collection:update', (data) => {
      socket.to(data.workspaceId).emit('collection:updated', data);
    });
  });

  return io;
}

module.exports = initSyncGateway;
```

Note: this backend Socket.IO gateway is for **team live-sync**, completely separate from the app's own **Socket.IO testing client** feature (Section 8.8), which talks to whatever external server the developer is testing against.

---

## 7. Frontend — Step by Step (Flutter + GetX)

### Step 1: Project setup

```bash
flutter create jronix_client
cd jronix_client
flutter config --enable-windows-desktop --enable-macos-desktop --enable-linux-desktop
```

### Step 2: Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                       # GetX: state management + routing + DI
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  socket_io_client: ^2.0.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  uuid: ^4.2.1
  intl: ^0.19.0
```

### Step 3: Folder structure (GetX pattern: Bindings / Controllers / Views)

```
lib/
├── main.dart
├── app/
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── core/
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── websocket_client.dart
│   │   │   └── socketio_client.dart
│   │   ├── storage/
│   │   │   ├── local_db.dart
│   │   │   └── secure_storage.dart
│   │   └── sync/
│   │       └── sync_engine.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── request_model.dart
│   │   │   ├── collection_model.dart
│   │   │   ├── environment_model.dart
│   │   │   └── history_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── request_repository.dart
│   │       └── collection_repository.dart
│   └── modules/
│       ├── auth/
│       │   ├── login_controller.dart
│       │   ├── login_binding.dart
│       │   └── login_view.dart
│       ├── home/
│       │   ├── home_controller.dart
│       │   ├── home_binding.dart
│       │   └── home_view.dart
│       ├── request_builder/
│       │   ├── request_builder_controller.dart
│       │   ├── request_builder_binding.dart
│       │   └── request_builder_view.dart
│       ├── websocket/
│       │   ├── websocket_controller.dart
│       │   └── websocket_view.dart
│       ├── socketio/
│       │   ├── socketio_controller.dart
│       │   └── socketio_view.dart
│       └── environment/
│           ├── environment_controller.dart
│           └── environment_view.dart
└── widgets/
    ├── method_selector.dart
    ├── headers_editor.dart
    ├── body_editor.dart
    ├── response_viewer.dart
    └── sidebar_collections.dart
```

### Step 4: GetX routing setup

```dart
// app/routes/app_routes.dart
abstract class Routes {
  static const LOGIN = '/login';
  static const HOME = '/home';
  static const REQUEST_BUILDER = '/request-builder';
  static const WEBSOCKET = '/websocket';
  static const SOCKETIO = '/socketio';
  static const ENVIRONMENT = '/environment';
}
```

```dart
// app/routes/app_pages.dart
class AppPages {
  static final pages = [
    GetPage(name: Routes.LOGIN, page: () => LoginView(), binding: LoginBinding()),
    GetPage(name: Routes.HOME, page: () => HomeView(), binding: HomeBinding()),
    GetPage(name: Routes.REQUEST_BUILDER, page: () => RequestBuilderView(), binding: RequestBuilderBinding()),
    GetPage(name: Routes.WEBSOCKET, page: () => WebSocketView(), binding: WebSocketBinding()),
    GetPage(name: Routes.SOCKETIO, page: () => SocketIOView(), binding: SocketIOBinding()),
  ];
}
```

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LocalRequestModelAdapter());
  await Hive.openBox('requests');
  await Hive.openBox('collections');

  runApp(GetMaterialApp(
    initialRoute: Routes.LOGIN,
    getPages: AppPages.pages,
  ));
}
```

### Step 5: Build order

1. **Login (module: auth)** → calls `POST /auth/login`, stores tokens via `flutter_secure_storage`
2. **Home (module: home)** → sidebar with collection tree, loaded from Hive first, synced in background
3. **Request builder (module: request_builder)** → method selector, URL bar, tabs for Headers/Params/Body/Auth
4. **Response viewer widget** → status/time/size + JSON tree
5. **Environment module** → manage variables per environment
6. **WebSocket module** → separate screen for WS testing
7. **Socket.IO module** → separate screen for Socket.IO testing
8. **History** → part of home module or its own tab, reload past requests

---

## 8. Core Feature Implementation

### 8.1 GetX Controller pattern (example: Request Builder)

```dart
// modules/request_builder/request_builder_controller.dart
class RequestBuilderController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final RequestRepository _repo = Get.find<RequestRepository>();

  var method = 'GET'.obs;
  var url = ''.obs;
  var headers = <Map<String, dynamic>>[].obs;
  var queryParams = <Map<String, dynamic>>[].obs;
  var bodyType = 'none'.obs;
  var body = {}.obs;
  var authType = 'none'.obs;
  var authConfig = {}.obs;

  var isLoading = false.obs;
  var response = Rxn<ResponseWrapper>();

  Future<void> sendRequest() async {
    isLoading.value = true;
    try {
      final resolvedUrl = resolveVariables(url.value);
      final resolvedHeaders = _buildHeaders();

      final result = await _dioClient.send(
        method: method.value,
        url: resolvedUrl,
        headers: resolvedHeaders,
        queryParams: _enabledMapOf(queryParams),
        body: body.value,
        bodyType: bodyType.value,
      );
      response.value = result;

      // save to history (local + queued for sync)
      await _repo.logHistory(result);
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, String> _buildHeaders() {
    final map = <String, String>{};
    for (final h in headers.where((e) => e['enabled'] == true)) {
      map[h['key']] = resolveVariables(h['value']);
    }
    _applyAuth(map);
    return map;
  }

  void _applyAuth(Map<String, String> headers) {
    switch (authType.value) {
      case 'bearer':
        headers['Authorization'] = 'Bearer ${resolveVariables(authConfig['token'] ?? '')}';
        break;
      case 'basic':
        final creds = base64Encode(utf8.encode('${authConfig['username']}:${authConfig['password']}'));
        headers['Authorization'] = 'Basic $creds';
        break;
      case 'api-key':
        headers[authConfig['keyName']] = authConfig['keyValue'];
        break;
    }
  }
}
```

GetX gives you `.obs` reactive variables — the UI (`Obx(() => ...)`) rebuilds automatically when `method`, `response`, etc. change, without needing `StatefulWidget`/`setState`.

### 8.2 Binding (dependency injection)

```dart
// modules/request_builder/request_builder_binding.dart
class RequestBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RequestBuilderController());
  }
}
```

### 8.3 Headers & Body Editor (UI pattern)

- Headers tab: `Obx(() => ListView.builder(...))` over `controller.headers`, each row has key/value `TextField`s + enabled `Checkbox`, "+" button calls `controller.headers.add({...})`.
- Body tab: `Obx` wrapping a segmented control bound to `controller.bodyType`, switching between raw JSON editor / form-data rows / file picker.

### 8.4 Dio HTTP Client

```dart
// core/network/dio_client.dart
class DioClient {
  final Dio _dio = Dio();
  Dio get raw => _dio;

  Future<ResponseWrapper> send({
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    String bodyType = 'raw-json',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.request(
        url,
        queryParameters: queryParams,
        options: Options(method: method, headers: headers),
        data: _buildBody(body, bodyType),
      );
      stopwatch.stop();
      return ResponseWrapper(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: response.headers.map,
        timeMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return ResponseWrapper.error(e, stopwatch.elapsedMilliseconds);
    }
  }

  dynamic _buildBody(dynamic body, String bodyType) {
    if (bodyType == 'form-data') return FormData.fromMap(body);
    return body; // raw-json / urlencoded handled by Dio automatically
  }
}
```

Register once as a permanent GetX service:

```dart
// main.dart (before runApp)
Get.put(DioClient(), permanent: true);
Get.put(AuthRepository(), permanent: true);
```

### 8.5 Token / Auth Management

| Type | Fields | Applied as |
|---|---|---|
| No Auth | — | — |
| Bearer Token | token (often `{{TOKEN}}` variable) | `Authorization: Bearer <token>` |
| Basic Auth | username, password | `Authorization: Basic base64(user:pass)` |
| API Key | key name, value, location | header or query param |

**Company-wide token workflow:**

1. Store long-lived tokens as environment variables with `isSecret: true`.
2. Reference as `{{AUTH_TOKEN}}` in the request's Auth tab instead of hardcoding.
3. Optional "auto-login" helper: mark a request as "refresh token via this login request," and before sending, the controller checks token expiry and re-runs the login request automatically, updating the variable. Gives most of the value of pre-request scripts without a JS sandbox.

```dart
String resolveVariables(String input) {
  final envController = Get.find<EnvironmentController>();
  return input.replaceAllMapped(
    RegExp(r'\{\{(.*?)\}\}'),
    (match) => envController.variables[match.group(1)] ?? match.group(0)!,
  );
}
```

### 8.6 Response Viewer

- Status code color-coded (2xx green / 4xx orange / 5xx red)
- Time (ms), size (KB)
- Tabs: Body (pretty JSON/raw), Headers, Cookies
- Recursive widget for JSON tree with collapse/expand

### 8.7 WebSocket Client + GetX Controller

```dart
// core/network/websocket_client.dart
class WebSocketClientWrapper {
  WebSocketChannel? _channel;

  Stream<dynamic>? connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    return _channel!.stream;
  }

  void send(String message) => _channel?.sink.add(message);
  void disconnect() => _channel?.sink.close();
}
```

```dart
// modules/websocket/websocket_controller.dart
class WebSocketController extends GetxController {
  final _client = WebSocketClientWrapper();
  var url = ''.obs;
  var isConnected = false.obs;
  var logs = <String>[].obs;

  void connect() {
    final stream = _client.connect(url.value);
    isConnected.value = true;
    stream?.listen(
      (data) => logs.add('RECV: $data'),
      onError: (e) => logs.add('ERROR: $e'),
      onDone: () => isConnected.value = false,
    );
  }

  void sendMessage(String msg) {
    _client.send(msg);
    logs.add('SENT: $msg');
  }

  void disconnect() {
    _client.disconnect();
    isConnected.value = false;
  }
}
```

**UI:** URL bar + Connect/Disconnect button, `Obx` list view of `logs` (color-code SENT vs RECV vs ERROR), message input at the bottom.

### 8.8 Socket.IO Client + GetX Controller

```dart
// core/network/socketio_client.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketIOClientWrapper {
  IO.Socket? _socket;

  IO.Socket connect(String url, {Map<String, dynamic>? auth}) {
    _socket = IO.io(url, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth(auth ?? {})
        .build());
    return _socket!;
  }

  void emit(String event, dynamic data) => _socket?.emit(event, data);
  void on(String event, Function(dynamic) cb) => _socket?.on(event, cb);
  void disconnect() => _socket?.disconnect();
}
```

```dart
// modules/socketio/socketio_controller.dart
class SocketIOController extends GetxController {
  final _client = SocketIOClientWrapper();
  var url = ''.obs;
  var isConnected = false.obs;
  var logs = <String>[].obs;
  var listenEvents = <String>[].obs; // user-defined event names to listen for

  void connect() {
    final socket = _client.connect(url.value);
    socket.onConnect((_) {
      isConnected.value = true;
      logs.add('Connected');
    });
    socket.onDisconnect((_) {
      isConnected.value = false;
      logs.add('Disconnected');
    });
    for (final event in listenEvents) {
      _client.on(event, (data) => logs.add('EVENT[$event]: $data'));
    }
  }

  void emitEvent(String event, dynamic payload) {
    _client.emit(event, payload);
    logs.add('EMIT[$event]: $payload');
  }
}
```

**UI:** URL + namespace + auth payload fields, "event to emit" + payload editor, list of event names to listen for (add/remove chips), live log view.

### 8.9 Request History

- Every executed request writes a `HistoryModel` entry to Hive (`syncStatus: pending`), synced to MongoDB via `/sync` or a direct `POST /history` call.
- History screen: reverse-chronological `Obx` list, tap an entry to reload it into the Request Builder controller (`Get.toNamed(Routes.REQUEST_BUILDER, arguments: historyEntry)`).

---

## 9. Sync Engine (Local ⇄ Server)

### 9.1 Flow

```
User creates/edits a request
        │
        ▼
Write immediately to local Hive box (syncStatus = 'pending')
        │
        ▼
UI updates instantly (reactive .obs — no network wait)
        │
        ▼
Background sync worker (Timer.periodic, every N seconds — or on save/app-foreground)
        │
        ▼
POST /sync  { lastSyncedAt, pendingChanges: [...] }
        │
        ▼
Server merges (last-write-wins by updatedAt) → returns { serverChanges, syncedAt }
        │
        ▼
Local Hive updates: syncStatus = 'synced', apply serverChanges
```

```dart
// core/sync/sync_engine.dart
class SyncEngine extends GetxService {
  final Dio _dio = Get.find<DioClient>().raw;
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
  }

  Future<void> syncNow() async {
    final pending = LocalDB.getPendingChanges();
    if (pending.isEmpty) return;

    final response = await _dio.post('/sync', data: {
      'lastSyncedAt': LocalDB.getLastSyncedAt(),
      'pendingChanges': pending,
    });

    LocalDB.markSynced(pending);
    LocalDB.applyServerChanges(response.data['serverChanges']);
    LocalDB.setLastSyncedAt(response.data['syncedAt']);
  }
}
```

Register as a permanent GetX service and start it after login:

```dart
Get.put(SyncEngine(), permanent: true).start();
```

### 9.2 Conflict handling (V1: keep it simple)

- `updatedAt` timestamp comparison, **last-write-wins**. Full CRDT/OT sync is unnecessary complexity for a 100-person internal tool.
- Optional: show a toast if a conflict was detected and resolved, so users aren't confused about a silently overwritten edit.

### 9.3 Login-triggered full sync

On login, pull all workspaces/collections/requests/environments for that user from MongoDB into Hive. This is what makes reinstalls / new laptops a non-issue — exactly the problem you started with.

---

## 10. Security

1. **Passwords:** bcrypt hash in MongoDB, never plain text.
2. **Tokens:** access token kept in memory (GetX controller state) + `flutter_secure_storage`; refresh token in `flutter_secure_storage` only.
3. **Secret variables:** encrypt `value` at rest (e.g., Node `crypto` module, AES-256-GCM, key from env var/secret manager) when `isSecret: true`; mask in Flutter UI with a reveal toggle.
4. **Transport:** HTTPS/WSS even for internal deployment — self-signed cert distributed to the team, or a real cert if you have a domain.
5. **Role-based access:** enforce with Express `requireRole` middleware, not just hidden UI — a Viewer hitting `DELETE /requests/:id` should get a 403 from the API itself.
6. **Audit trail:** `History` collection already logs who ran what, when.

---

## 11. Deployment

```
                 Jronix Server (VPS or internal server)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
   Express API          MongoDB              (optional)
   (PM2 / Docker)     (Docker volume /      Redis for
                        Atlas cluster)      rate-limiting
        │
        ▼
   Nginx (reverse proxy + HTTPS via Let's Encrypt/internal CA)
```

- Simplest path: **MongoDB Atlas** (managed, free tier is enough for 100 users initially) + Express API on a small VPS with PM2 or Docker — skips self-hosting Mongo and its backup headaches.
- If self-hosting Mongo instead: automated `mongodump` cron job → store on object storage/NAS as backup.
- Flutter desktop app: `flutter build windows` / `flutter build macos` / `flutter build linux`, distribute via shared drive or a simple in-app "check for update" screen.

---

## 12. Phased Roadmap

### Phase 1 — MVP (build this first)
- Auth (JWT login/register)
- Workspaces, Collections, Folders
- HTTP requests: GET/POST/PUT/PATCH/DELETE
- Headers, Query Params, raw JSON body, form-data, file upload
- Bearer / API Key / Basic auth
- Response viewer
- Environments & variables (incl. secret variables)
- Request history
- WebSocket client
- Socket.IO client
- Sync engine (Hive ⇄ MongoDB)

**Covers every feature you listed as required.**

### Phase 2 — Quality of life
- cURL import/export
- Collection import/export (Postman-compatible JSON format for easy migration)
- Cookie jar
- GraphQL support
- Full RBAC UI
- Live team updates via Socket.IO gateway

### Phase 3 — Advanced (only if truly needed)
- Pre-request / test scripts (sandboxed JS — most effort of anything on this list)
- Mock servers
- Proxy support
- CLI companion

---

## 13. Folder Structure Reference

```
jronix/
├── backend/                    # Node.js + Express + MongoDB
│   ├── src/
│   │   ├── config/
│   │   ├── models/
│   │   ├── middleware/
│   │   ├── controllers/
│   │   ├── routes/
│   │   └── sockets/
│   ├── server.js
│   ├── .env
│   └── package.json
│
└── client/                     # Flutter Desktop + GetX
    ├── lib/
    │   ├── app/
    │   │   ├── routes/
    │   │   ├── core/
    │   │   ├── data/
    │   │   └── modules/
    │   └── widgets/
    └── pubspec.yaml
```

---

## Summary

- **Stack fit:** MongoDB is a natural fit here — headers, params, body, and authConfig are all JSON-shaped, so `Mixed` fields in Mongoose avoid the friction of normalizing them into relational tables. Express keeps the backend close to what you already know from MERN. GetX keeps the Flutter side lightweight — `.obs` reactive state, built-in DI via `Get.put`/`Get.find`, and routing without extra packages.
- **Difficulty:** Medium overall for Phase 1. Every individual feature (HTTP methods, headers/body, token management, WebSocket, Socket.IO) is straightforward; the real work is wiring ~8-10 screens to a solid MongoDB schema and the sync engine.
- **The "collections disappearing" problem** is solved the moment MongoDB is the permanent source of truth with Hive as local cache — it's a storage design fix, not something that depends on which stack you pick.
- **Build Phase 1 first**, ship to your 100 users, then decide on Phase 2/3 based on real feedback.
