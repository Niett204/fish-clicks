# 🎨 VISTA VISUAL DEL SISTEMA

## 🎮 CÓMO SE VE EN GODOT

### Pantalla Principal (Antes del Login)
```
┌─────────────────────────────────────────────┐
│                                             │
│  ⚙️ 💰 📊 📚 🎒 🛍️    Game Area      🞷    │
│  ─────────────────────────────────────────  │
│                                             │
│                                             │
│              [Fondo del juego]              │
│                                             │
│              Cofre aquí                     │
│                                             │
│                                             │
│                                             │
│  mil doblones                               │
│  por segundo: 0.0                           │
│                                             │
│                                             │
└─────────────────────────────────────────────┘

Nota: El botón ⚙️ (perfil) abre el login
```

### Ventana de Login (Popup)
```
            ╔════════════════════════════════╗
            ║          Iniciar Sesión        ║
            ║                                ║
            ║ Correo:                        ║
            ║ ┌────────────────────────────┐ ║
            ║ │ ejemplo@correo.com         │ ║
            ║ └────────────────────────────┘ ║
            ║                                ║
            ║ Contraseña:                    ║
            ║ ┌────────────────────────────┐ ║
            ║ │ ●●●●●●●●●                │ ║
            ║ └────────────────────────────┘ ║
            ║                                ║
            ║                                ║
            ║ [ Iniciar Sesión ] [ Cancelar] ║
            ║                                ║
            ╚════════════════════════════════╝
```

---

## 📊 DIAGRAMA TÉCNICO

### Arquitectura General
```
┌──────────────────────┐
│   GODOT CLIENT       │
│  (fish-clicks-main)  │
├──────────────────────┤
│ Main Scene           │
│ └─ UI/Root           │
│    └─ HUD            │
│       ├─ TopBar      │
│       │  └─ BtnProfile (profile_button.gd)
│       │     └─ Opens LoginPanel
│       │
│       ├─ LoginPanel (login_panel.gd)
│       │  ├─ EmailInput
│       │  ├─ PasswordInput
│       │  └─ HTTP Request
│       │
│       └─ TiendaPanel
│
└─────────────┬────────┘
              │ HTTP POST
              │ /auth/login
              │ {email, password}
              │
              ▼
┌──────────────────────┐
│  BACKEND (Java)      │
│  (fish-clicks-api)   │
├──────────────────────┤
│ Spring Boot App      │
│ ├─ AuthController    │
│ │  └─ @PostMapping   │
│ │     /auth/login    │
│ │                    │
│ ├─ AuthService       │
│ │  └─ login()        │
│ │     ├─ Find user   │
│ │     └─ Check pwd   │
│ │                    │
│ ├─ JwtService        │
│ │  └─ generateToken()│
│ │                    │
│ ├─ UserRepository    │
│ │  └─ Find by email  │
│ │                    │
│ └─ PostgreSQL        │
│    └─ users table    │
│                      │
└──────────────┬───────┘
               │ HTTP 200
               │ {token, userId}
               │
               ▼
┌──────────────────────┐
│   GODOT (Storage)    │
├──────────────────────┤
│ GlobalData.gd        │
│ (Autoload)           │
│                      │
│ .user_token          │
│ .user_id             │
│ .user_email          │
│ .is_logged_in        │
│                      │
└──────────────────────┘
```

---

## 🔄 FLUJO DETALLADO DE LOGIN

### Paso a Paso

```
1. Usuario ve el juego
   ┌─────────────────────────┐
   │ [⚙️] 💰 📊 📚 🎒 🛍️    │
   └─────────────────────────┘
        Hace clic ↓
        
2. Se abre LoginPanel
   ╔═══════════════════════╗
   ║  Iniciar Sesión       ║
   ║ Correo: [         ]   ║
   ║ Contra: [         ]   ║
   ║ [OK] [Cancel]         ║
   ╚═══════════════════════╝
   Usuario escribe ↓
   
3. Usuario presiona "Iniciar Sesión"
   Login_panel.gd ejecuta:
   - Valida campos
   - Crea JSON
   - Envía HTTP
   ↓
   
4. Backend recibe petición
   AuthController /auth/login
   AuthService busca usuario
   JwtService genera token
   ↓
   
5. Backend responde
   {
     "token": "eyJhbGciOi...",
     "userId": 1
   }
   ↓
   
6. Godot recibe respuesta
   login_panel.gd:
   - Extrae token y userId
   - Llama GlobalData.set_user_session()
   ↓
   
7. GlobalData guarda
   .user_token = "eyJhbGciOi..."
   .user_id = 1
   .user_email = "test@example.com"
   .is_logged_in = true
   ↓
   
8. Panel se cierra
   ╔═══════════════════════╗
   ║ ¡Login exitoso!       ║
   ║ (Se cierra)           ║
   ╚═══════════════════════╝
   ↓
   
9. Juego continúa
   ┌─────────────────────────┐
   │ [⚙️] 💰 📊 📚 🎒 🛍️    │
   │ Usuario logueado ✓      │
   │ Token disponible ✓      │
   └─────────────────────────┘
```

---

## 🗂️ ESTRUCTURA DE ARCHIVOS

```
Proyecto Godot:
fish-clicks-main/
│
├── scenes/
│   ├── LoginPanel.tscn .......................... Escena visual
│   ├── login_panel.gd ........................... Script principal
│   ├── profile_button.gd ........................ Botón de perfil
│   ├── main.tscn (MODIFICADO) .................. Conecta todo
│   └── [otras escenas...]
│
├── autoload/
│   └── GlobalData.gd ............................ Datos globales
│
├── scripts/
│   └── example_login_usage.gd .................. Ejemplos
│
├── project.godot (MODIFICADO) .................. Config autoload
│
├── QUICK_REFERENCE.md .......................... Referencia rápida
├── GODOT_LOGIN_GUIDE.md ........................ Documentación
├── LOGIN_SYSTEM_DOCS.md ........................ Arquitectura
└── TIENDA_INTEGRATION_GUIDE.md ................. Tienda

Proyecto Backend:
fish-clicks-api/
│
├── src/main/java/com/fishclicks/api/
│   │
│   ├── service/
│   │   ├── JwtService.java (NUEVO) ............ Generador JWT
│   │   ├── AuthService.java (MODIFICADO) .... Autenticación
│   │   └── [otros servicios...]
│   │
│   ├── controller/
│   │   ├── AuthController.java (MODIFICADO) . Endpoints
│   │   └── [otros controllers...]
│   │
│   ├── filter/
│   │   └── JwtFilter.java (NUEVO) ............ Validador JWT
│   │
│   ├── config/
│   │   └── SecurityConfig.java (NUEVO) ...... Seguridad
│   │
│   ├── dto/
│   │   ├── LoginResponse.java (MODIFICADO) .. Respuesta
│   │   └── [otros DTOs...]
│   │
│   └── [paquetes...]
│
├── pom.xml (MODIFICADO) ........................ Dependencias
├── src/main/resources/
│   └── application.properties (MODIFICADO) .. Config
│
├── GODOT_LOGIN_GUIDE.md ........................ Documentación
└── JWT_TESTING_GUIDE.md ........................ Testing
```

---

## 💾 BASE DE DATOS

### Tabla de Usuarios
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255),
    password VARCHAR(255) NOT NULL
);

-- Ejemplo de usuario
INSERT INTO users (email, username, password) 
VALUES ('test@example.com', 'testuser', 'password123');
```

---

## 🔐 FLUJO DE SEGURIDAD

```
Cliente (Godot)              Backend (Java)           BD (PostgreSQL)
        │                          │                         │
        ├──┐ POST /auth/login     │                         │
        │  ├─ email: "..."        │                         │
        │  ├─ password: "..."     │                         │
        │  └──────────────────────►                         │
        │                         ├──┐ AuthService         │
        │                         │  ├─ Find user          │
        │                         │  └──────────────────────►
        │                         │                         │
        │                         │◄────────────────────────┤
        │                         │   User found            │
        │                         │                         │
        │                         ├─ Verify password       │
        │                         ├─ Valid? Yes            │
        │                         │                         │
        │                         ├─ JwtService            │
        │                         ├─ Create JWT            │
        │                         ├─ Sign with HMAC-SHA512 │
        │                         │                         │
        │◄──────────────────────────────────────────────────┤
        │  HTTP 200                                          │
        │  {                                                 │
        │    "token": "eyJhbGciOiJIUzUxMiJ9...",           │
        │    "userId": 1                                     │
        │  }                                                 │
        │                                                    │
        ├─ GlobalData.set_user_session()                    │
        ├─ Save token in memory                             │
        ├─ Save token in file                               │
        └─ Mark as logged_in = true
```

---

## 🎯 ESTADOS DEL PANEL

### Estado 1: Inicial
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo:                    ║
║ [                         ]║
║                            ║
║ Contraseña:                ║
║ [                         ]║
║                            ║
║ [ Iniciar ] [ Cancelar]   ║
║                            ║
╚════════════════════════════╝
```

### Estado 2: Ingresando datos
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo:                    ║
║ [test@example.com|        ]║ ← Usuario escribe
║                            ║
║ Contraseña:                ║
║ [●●●●●●●●                ]║ ← Usuario escribe
║                            ║
║ [ Iniciar ] [ Cancelar]   ║
║                            ║
╚════════════════════════════╝
```

### Estado 3: Procesando
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo:                    ║
║ [test@example.com        ]║
║                            ║
║ Contraseña:                ║
║ [●●●●●●●●                ]║
║                            ║
║        Conectando...       ║  ← Amarillo
║                            ║
║ [ Iniciar ] [ Cancelar]   ║
║  (deshabilitado)           ║
╚════════════════════════════╝
```

### Estado 4: Éxito
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo:                    ║
║ [test@example.com        ]║
║                            ║
║ Contraseña:                ║
║ [●●●●●●●●                ]║
║                            ║
║   ¡Login exitoso!          ║  ← Verde
║                            ║
║ [ Iniciar ] [ Cancelar]   ║
║                            ║
╚════════════════════════════╝
(Se cierra automáticamente)
```

### Estado 5: Error
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo:                    ║
║ [wrong@email.com         ]║
║                            ║
║ Contraseña:                ║
║ [●●●●●●●●                ]║
║                            ║
║ Usuario no encontrado      ║  ← Rojo
║ o contraseña incorrecta    ║
║                            ║
║ [ Iniciar ] [ Cancelar]   ║
║                            ║
╚════════════════════════════╝
```

---

## 📱 COMPONENTES VISUALES

### Panel Principal
- **Fondo**: Color semi-transparente negro
- **Cuerpo**: Imagen de pergamino (botella_mensaje.png)
- **Tamaño**: 300x280 píxeles centrado

### Campos de Input
- **Tipo**: LineEdit
- **Tamaño**: 250x30
- **Email**: Placeholder "ejemplo@correo.com"
- **Password**: Masked (secret: true)

### Botones
- **Iniciar Sesión**: 100x30, verde
- **Cancelar**: 100x30, gris

### Labels
- **Título**: "Iniciar Sesión", 20pt, centrado
- **Status**: Dinámico, amarillo/verde/rojo

---

## 🎮 INTERACTIVIDAD

### Teclado
- **ENTER**: Envía login si campos llenos
- **ESC**: Cierra el panel
- **TAB**: Navega entre campos

### Mouse
- Click en botón: Acciona
- Click fuera: No hace nada

---

## 📊 PETICIONES HTTP

### Petición al Backend
```
POST http://localhost:8080/auth/login HTTP/1.1
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

### Respuesta Exitosa
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "token": "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiaWF0IjoxNzE2NzUxNjQ4LCJleHAiOjE3MTY4MzgwNDh9.xxx",
  "userId": 1
}
```

### Respuesta de Error
```
HTTP/1.1 500 Internal Server Error

"User not found"
```

---

## ✅ DIAGRAMA DE COMPONENTES

```
LoginPanel (Node2D)
├── ColorRect (overlay oscuro)
│   └─ Cubre toda la pantalla
│
└── PergaminoPanel (Panel)
    ├─ Texture: botella_mensaje.png
    │
    └─ MarginContainer
        └─ VBoxContainer
            ├─ TitleLabel ("Iniciar Sesión")
            │
            ├─ EmailContainer
            │  ├─ EmailLabel ("Correo:")
            │  └─ EmailInput (LineEdit)
            │
            ├─ PasswordContainer
            │  ├─ PasswordLabel ("Contraseña:")
            │  └─ PasswordInput (LineEdit)
            │
            ├─ StatusLabel ("" / "Conectando..." / etc)
            │
            ├─ ButtonContainer
            │  ├─ BtnLogin ("Iniciar Sesión")
            │  └─ BtnCancel ("Cancelar")
            │
            └─ HTTPRequest (para conexión)
```

---

**Visualización completa del sistema implementado** ✓

