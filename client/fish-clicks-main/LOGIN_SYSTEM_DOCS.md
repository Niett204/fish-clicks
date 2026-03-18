# 🎮 Sistema de Login en Godot - Implementación Completa

## 📊 Diagrama del Flujo

```
┌─────────────────────────────────────────────────────────────────┐
│                         GODOT (Cliente)                         │
│                                                                 │
│  1. Usuario hace clic en botón de perfil (BtnProfile)          │
│     ↓                                                           │
│  2. Se abre LoginPanel (ventana del pergamino)                 │
│     ├─ Campo Email                                             │
│     ├─ Campo Contraseña                                        │
│     └─ Botón "Iniciar Sesión"                                 │
│     ↓                                                           │
│  3. Usuario ingresa datos y presiona "Iniciar Sesión"          │
│     ↓                                                           │
│  4. login_panel.gd valida campos                               │
│     ├─ Email no vacío                                          │
│     └─ Contraseña no vacía                                     │
│     ↓                                                           │
│  5. Envía petición HTTP POST                                   │
│     Headers: Content-Type: application/json                    │
│     Body: {"email": "...", "password": "..."}                 │
│                                                                 │
│     ↓                      HTTP      ↓                         │
│     └────────────────────────────────→                         │
│                                       │                        │
└───────────────────────────────────────┼────────────────────────┘
                                        │
┌───────────────────────────────────────┼────────────────────────┐
│                                       │                        │
│                   BACKEND (Java + JWT)                         │
│                                       │                        │
│                                       ↓                        │
│  6. AuthController recibe petición                             │
│     /auth/login                                                │
│     ↓                                                           │
│  7. AuthService valida en BD                                   │
│     ├─ ¿Usuario existe?                                        │
│     └─ ¿Contraseña correcta?                                  │
│     ↓                                                           │
│  8. JwtService genera token JWT                                │
│     Token = Header.Payload.Signature                           │
│     ├─ Sub: user_id                                            │
│     ├─ Email: user_email                                       │
│     ├─ Iat: issued_at_time                                     │
│     └─ Exp: expiration_time (24 horas)                         │
│     ↓                                                           │
│  9. Retorna LoginResponse                                       │
│     {"token": "eyJh...", "userId": 1}                         │
│                                                                 │
│     ↓                      HTTP      ↓                         │
│     ←────────────────────────────────                          │
│                                                                 │
└───────────────────────────────────────┬────────────────────────┘
                                        │
┌───────────────────────────────────────┼────────────────────────┐
│                                       │                        │
│                         GODOT (Cliente)                        │
│                                       │                        │
│                                       ↓                        │
│ 10. login_panel.gd recibe respuesta 200 OK                     │
│     Extrae: token y userId                                     │
│     ↓                                                           │
│ 11. GlobalData.set_user_session()                              │
│     ├─ Guarda token en memoria                                 │
│     ├─ Guarda user_id                                          │
│     ├─ Guarda email                                            │
│     ├─ Set is_logged_in = true                                 │
│     └─ Guarda sesión en disco (opcional)                       │
│     ↓                                                           │
│ 12. LoginPanel se cierra                                       │
│     ↓                                                           │
│ 13. GlobalData disponible en todo el juego                      │
│     Otros scripts pueden acceder:                              │
│     ├─ GlobalData.is_logged_in                                 │
│     ├─ GlobalData.user_token                                   │
│     ├─ GlobalData.user_id                                      │
│     ├─ GlobalData.user_email                                   │
│     └─ GlobalData.get_auth_header()                            │
│     ↓                                                           │
│ 14. Peticiones autenticadas                                     │
│     Cuando necesites auth, usa:                                │
│     Authorization: Bearer {token}                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura de Archivos

```
fish-clicks-main/
├── scenes/
│   ├── main.tscn                 (Modificado - agrega profile_button.gd)
│   ├── LoginPanel.tscn           ✨ NUEVO - Escena del panel de login
│   ├── login_panel.gd            ✨ NUEVO - Script del panel
│   ├── profile_button.gd         ✨ NUEVO - Script del botón de perfil
│   ├── tienda_panel.tscn
│   └── ...
│
├── autoload/
│   └── GlobalData.gd             ✨ NUEVO - Gestor de sesión global
│
├── scripts/
│   └── example_login_usage.gd    ✨ NUEVO - Ejemplos de uso
│
├── GODOT_LOGIN_GUIDE.md          ✨ NUEVO - Documentación completa
├── project.godot                 (Modificado - agrega autoload)
└── ...
```

---

## 🔑 Componentes Principales

### 1️⃣ **LoginPanel.tscn** - Interfaz Visual
```
LoginPanel (Control)
├── ColorRect (fondo oscuro semi-transparente)
└── PergaminoPanel (Panel principal)
    └── MarginContainer
        └── VBoxContainer
            ├── TitleLabel ("Iniciar Sesión")
            ├── EmailContainer
            │   ├── EmailLabel
            │   └── EmailInput (LineEdit)
            ├── PasswordContainer
            │   ├── PasswordLabel
            │   └── PasswordInput (LineEdit)
            ├── StatusLabel (para mensajes)
            └── ButtonContainer
                ├── BtnLogin
                └── BtnCancel
```

### 2️⃣ **login_panel.gd** - Lógica del Login
```gdscript
- Valida campos (email y contraseña no vacíos)
- Envía petición HTTP POST al backend
- Maneja respuestas del servidor
- Guarda sesión mediante GlobalData
- Cierra automáticamente al login exitoso
```

### 3️⃣ **profile_button.gd** - Botón de Perfil
```gdscript
- Abre LoginPanel cuando se presiona
- Instancia la escena LoginPanel.tscn
```

### 4️⃣ **GlobalData.gd** - Autoload Global
```gdscript
Variables públicas:
- user_token: String
- user_id: int
- user_email: String
- is_logged_in: bool

Métodos:
- set_user_session(token, user_id, email)
- clear_session()
- get_auth_header()
```

---

## 🔄 Flujo de Autenticación Detallado

### Paso 1: Usuario hace clic en botón
```
BtnProfile.pressed() 
→ profile_button._on_pressed()
→ Instancia LoginPanel.tscn
→ Añade a la escena
```

### Paso 2: Usuario ingresa datos
```
LoginPanel visible
├─ Usuario escribe email
├─ Usuario escribe contraseña
└─ Usuario presiona "Iniciar Sesión"
```

### Paso 3: Validación local
```
login_panel._on_btn_login_pressed()
├─ Valida email no vacío
├─ Valida contraseña no vacía
└─ Prepara JSON: {"email": "...", "password": "..."}
```

### Paso 4: Petición HTTP
```
HTTPRequest.request(
    "http://localhost:8080/auth/login",
    ["Content-Type: application/json"],
    HTTPClient.METHOD_POST,
    json_string
)
```

### Paso 5: Respuesta del backend
```
200 OK: {"token": "eyJh...", "userId": 1}
500 ERROR: "Usuario no encontrado o contraseña incorrecta"
```

### Paso 6: Guardar sesión
```
GlobalData.set_user_session(token, user_id, email)
├─ Guarda token en memoria
├─ Guarda user_id
├─ Guarda email
├─ Set is_logged_in = true
└─ Guarda en disco (user://fish_clicks_session.save)
```

### Paso 7: Usar en otras peticiones
```gdscript
var headers = [
    "Content-Type: application/json",
    "Authorization: " + GlobalData.get_auth_header()
]
# Resultado: "Authorization: Bearer eyJh..."
```

---

## 🎯 Casos de Uso

### ✅ Caso 1: Usuario hace login
```
1. Clic en botón de perfil
2. Ingresa email y contraseña
3. Presiona "Iniciar Sesión"
4. Credenciales válidas
5. Se guarda el token
6. Panel se cierra
7. Usuario logueado
```

### ✅ Caso 2: Usuario ingresa contraseña incorrecta
```
1. Clic en botón de perfil
2. Ingresa email correcto
3. Ingresa contraseña incorrecta
4. Presiona "Iniciar Sesión"
5. Backend retorna error 500
6. Se muestra "Usuario no encontrado o contraseña incorrecta"
7. Campo de contraseña se limpia
8. Usuario puede reintentar
```

### ✅ Caso 3: Servidor no responde
```
1. Clic en botón de perfil
2. Ingresa datos
3. Presiona "Iniciar Sesión"
4. Backend no responde (code 0)
5. Se muestra "No se pudo conectar con el servidor"
6. Usuario debe reintentar
```

### ✅ Caso 4: Usuario cancela login
```
1. Clic en botón de perfil
2. Presiona "Cancelar"
3. Panel se cierra sin hacer nada
```

### ✅ Caso 5: Usar token en petición autenticada
```gdscript
# En otro script:
var headers = [
    "Authorization: " + GlobalData.get_auth_header()
]
http_request.request(url, headers, HTTPClient.METHOD_GET)
# Backend verifica token, procesa petición y responde
```

---

## 🔒 Seguridad Implementada

| Aspecto | Implementado |
|--------|-------------|
| JWT Signing | ✅ HMAC-SHA512 |
| Token Expiration | ✅ 24 horas |
| HTTPS | ⚠️ No (configurar en prod) |
| Password Encryption | ⚠️ No (agregar BCrypt) |
| CORS | ✅ Configurado |
| Token en Header | ✅ Authorization: Bearer |
| Session Persistence | ✅ Archivo local |

---

## 🚀 Próximas Mejoras

| Prioridad | Tarea |
|-----------|-------|
| 🔴 CRÍTICO | Implementar BCrypt en backend |
| 🔴 CRÍTICO | HTTPS en producción |
| 🟡 ALTO | Botón de logout |
| 🟡 ALTO | Mostrar usuario logueado en HUD |
| 🟡 ALTO | Refresh tokens |
| 🟢 MEDIO | Endpoint de registro |
| 🟢 MEDIO | Recovery de contraseña |

---

## 📝 Notas Técnicas

- **Token TTL**: 24 horas (configurable en backend)
- **Storage**: RAM + Disco (persistencia)
- **Validación**: Cliente + Servidor
- **CORS**: Habilitado para Godot
- **Método HTTP**: POST para login
- **Content-Type**: application/json

---

## 🧪 Estado Actual

- ✅ Backend: JWT implementado y compilado
- ✅ Godot: Sistema completo funcional
- ✅ Integración: Funcionando
- ✅ Documentación: Completa
- ⚠️ Seguridad: Básica (mejorable)
- ⏳ Producción: Listo (con cambios menores)

**Status**: 🟢 LISTO PARA USAR LOCALMENTE

