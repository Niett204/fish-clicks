# 🎮 Guía de Implementación del Sistema de Login en Godot

## ✅ Qué se implementó

Se ha creado un **sistema completo de login** integrado en tu proyecto Godot que se conecta con el backend JWT.

---

## 📁 Archivos Creados

### 1. **LoginPanel.tscn** - Escena de la ventana de login
   - Panel visual tipo pergamino
   - Campos de entrada para email y contraseña
   - Botones "Iniciar Sesión" y "Cancelar"
   - Mostrador de estado (éxito/error)

### 2. **login_panel.gd** - Script del panel de login
   - Gestiona las peticiones HTTP al backend
   - Valida los campos
   - Muestra mensajes de estado
   - Guarda los datos de sesión

### 3. **profile_button.gd** - Script del botón de perfil
   - Abre el panel de login cuando se presiona
   - Carga automáticamente la escena LoginPanel

### 4. **autoload/GlobalData.gd** - Gestor global de sesión
   - Guarda el token JWT
   - Guarda el ID del usuario
   - Guarda el email del usuario
   - Persiste la sesión en disco
   - Proporciona métodos para acceder a la sesión

---

## 🔧 Cambios en Archivos Existentes

### **main.tscn**
- Agregadas referencias a `profile_button.gd` y `LoginPanel.tscn`
- El botón `BtnProfile` ahora tiene el script y está conectado

### **project.godot**
- Agregado `GlobalData` como autoload

---

## 🚀 Cómo Funciona

### Flujo del Login:

1. **Usuario hace clic** en el botón de perfil (icono de perfil)
2. **Se abre una ventana** con dos campos: email y contraseña
3. **Usuario ingresa datos** y presiona "Iniciar Sesión"
4. **Se envía petición HTTP** al backend: `POST http://localhost:8080/auth/login`
5. **Backend valida** y retorna el token JWT
6. **Godot guarda** el token en `GlobalData.user_token`
7. **Ventana se cierra** automáticamente
8. **Token guardado** está disponible para futuras peticiones

---

## 💾 Cómo Usar en tu Código

### Acceder a los datos del usuario:

```gdscript
# En cualquier script:

# Verificar si el usuario está logueado
if GlobalData.is_logged_in:
    print("Usuario logueado: ", GlobalData.user_email)

# Obtener el token
var token = GlobalData.user_token
print("Token: ", token)

# Obtener el ID del usuario
var user_id = GlobalData.user_id
print("ID Usuario: ", user_id)

# Obtener el header de autorización (para futuras peticiones)
var auth_header = GlobalData.get_auth_header()
# Resultado: "Bearer eyJhbGciOiJIUzUxMiJ9..."

# Cerrar sesión
GlobalData.clear_session()
```

---

## 📡 Ejemplo: Usar el Token en Otras Peticiones

```gdscript
extends Node

@onready var http_request: HTTPRequest = HTTPRequest.new()

func _ready():
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func get_user_profile():
    if not GlobalData.is_logged_in:
        print("No hay sesión activa")
        return
    
    var url = "http://localhost:8080/api/user"
    var headers = [
        "Content-Type: application/json",
        "Authorization: " + GlobalData.get_auth_header()
    ]
    
    http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var data = JSON.parse_string(body.get_string_from_utf8())
        print("Datos del usuario: ", data)
    elif response_code == 401:
        print("Token expirado, necesita login de nuevo")
        GlobalData.clear_session()
    else:
        print("Error: ", response_code)
```

---

## 🎯 Configuración

### URL del Backend

En **login_panel.gd**, línea:
```gdscript
const BACKEND_URL = "http://localhost:8080/auth/login"
```

**Cambiar según tu configuración:**
- Desarrollo local: `http://localhost:8080/auth/login`
- Servidor remoto: `http://tu-servidor.com:8080/auth/login`
- HTTPS: `https://tu-servidor.com:8080/auth/login`

---

## ⌨️ Controles del Login

- **ESC** - Cierra la ventana de login
- **ENTER** - Envía el login (si los campos están llenos)
- **TAB** - Navega entre campos

---

## 🎨 Personalización del Diseño

### Cambiar la imagen del pergamino:

En **LoginPanel.tscn**, busca:
```
[ext_resource type="Texture2D" uid="uid://c5ht6q767emx5" path="res://assets/ui/botella_mensaje.png" id="2_lhgjh"]
```

Reemplaza la ruta por tu imagen de pergamino.

### Cambiar colores y tamaños:

En **login_panel.gd**, puedes ajustar:
- `theme_override_font_sizes/font_size` - Tamaño de texto
- `theme_override_colors/font_color` - Color de texto

---

## 🔒 Seguridad

### ✅ Implementado:
- Token JWT con HMAC-SHA512
- Token guardado en memoria (mientras juega)
- Sesión persistente en disco (opcional)

### ⚠️ Recomendaciones:
1. **HTTPS en producción** - Usa HTTPS para proteger el token
2. **No guardes en sesión persistente** - Comentar `_save_session()` para mayor seguridad
3. **Validar token en cliente** - Antes de enviar peticiones al backend
4. **Logout** - Implementar botón de logout para limpiar sesión

---

## 🧪 Prueba Local

1. **Asegúrate de que el backend está corriendo:**
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
   export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/fish_clicks
   export SPRING_DATASOURCE_USERNAME=postgres
   export SPRING_DATASOURCE_PASSWORD=tu_password
   
   cd /home/jfriera03/Documentos/fish-clicks/fish-clicks-api
   ./mvnw spring-boot:run
   ```

2. **Asegúrate de que hay un usuario en la BD:**
   ```sql
   INSERT INTO users (email, username, password) 
   VALUES ('test@example.com', 'testuser', 'password123');
   ```

3. **Abre Godot y presiona Play**

4. **Haz clic en el botón de perfil** (icono en la esquina superior izquierda)

5. **Ingresa los datos:**
   - Email: `test@example.com`
   - Contraseña: `password123`

6. **Presiona "Iniciar Sesión"**

---

## 📝 Notas Importantes

- El token se guarda automáticamente en `GlobalData`
- La sesión persiste entre reinicios (si está habilitado)
- El token tiene expiración de 24 horas por defecto
- Después de login, puedes acceder a `GlobalData.user_token` desde cualquier script
- Los campos se limpian automáticamente después de un login exitoso

---

## 🚀 Próximos Pasos

1. **Agregar botón de logout** - Para cerrar la sesión
2. **Mostrar el email del usuario** - En la HUD después del login
3. **Endpoint de registro** - Permitir crear nuevas cuentas
4. **Validaciones mejoradas** - Email format, password strength
5. **Password recovery** - Recuperación de contraseña

---

## 📞 Troubleshooting

### Error: "No se pudo conectar con el servidor"
- Verificar que el backend está corriendo
- Verificar la URL en `login_panel.gd`
- Verificar que CORS está habilitado en el backend

### Error: "Usuario no encontrado o contraseña incorrecta"
- Verificar que el usuario existe en la base de datos
- Verificar que la contraseña es exacta (case-sensitive)
- Verificar que el email es exacto

### El login no guarda la sesión
- Verificar que `GlobalData` está registrado como autoload
- Revisar la consola para errores

### El token no funciona en otras peticiones
- Verificar que usas `GlobalData.get_auth_header()` correctamente
- Verificar que el backend está validando correctamente el JWT

