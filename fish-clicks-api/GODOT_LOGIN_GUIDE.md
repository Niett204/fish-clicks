# Guía de Login desde Godot con JWT

## ✅ Estado de la API

Tu API está **COMPLETA Y FUNCIONAL CON JWT** para recibir peticiones de login. Ahora puedes conectarte desde Godot.

---

## 📡 Endpoint de Login

**URL:** `http://[TU_SERVIDOR]:8080/auth/login`

**Método:** `POST`

**Content-Type:** `application/json`

---

## 📤 Qué enviar desde Godot

Debes enviar un JSON con la siguiente estructura:

```json
{
  "email": "usuario@ejemplo.com",
  "password": "tu_contraseña"
}
```

### Ejemplo en GDScript (Godot):

```gdscript
extends Node

var http_request: HTTPRequest

func _ready():
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func login(email: String, password: String):
    var url = "http://localhost:8080/auth/login"
    var headers = ["Content-Type: application/json"]
    
    var body = {
        "email": email,
        "password": password
    }
    
    var json_string = JSON.stringify(body)
    
    http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var json = JSON.new()
        var login_response = json.parse_string(body.get_string_from_utf8())
        
        print("Login exitoso!")
        print("Token: ", login_response.token)
        print("ID de usuario: ", login_response.userId)
        
        # Guardar el token para futuras peticiones
        var token = login_response.token
        # Usarlo en futuros requests: Authorization: Bearer {token}
    else:
        print("Error en login. Código: ", response_code)
        print("Respuesta: ", body.get_string_from_utf8())

# Llamar el login así:
# login("test@example.com", "password123")
```

---

## 📥 Qué recibirás como respuesta

Si el login es **exitoso (200)**, recibirás:

```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": 1
}
```

El **token** es un JWT que debes usar en futuras peticiones en el header:
```
Authorization: Bearer {token}
```

### Posibles errores:

| Código | Error | Causa |
|--------|-------|-------|
| 200 | OK | Login exitoso |
| 500 | RuntimeException | Usuario no encontrado o contraseña incorrecta |

---

## 🔐 Usar el Token en futuras peticiones

Una vez tengas el token, úsalo así para acceder a endpoints protegidos:

```gdscript
func get_user_data(token: String):
    var url = "http://localhost:8080/api/user"
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + token
    ]
    
    http_request.request(url, headers, HTTPClient.METHOD_GET)
```

---

## 🛢️ Base de datos

Tu API se conecta a **PostgreSQL**.

Asegúrate de que:
1. PostgreSQL esté ejecutándose
2. Las variables de entorno estén configuradas:
   - `SPRING_DATASOURCE_URL`: URL de conexión a BD (ej: `jdbc:postgresql://localhost:5432/fish_clicks`)
   - `SPRING_DATASOURCE_USERNAME`: Usuario (ej: `postgres`)
   - `SPRING_DATASOURCE_PASSWORD`: Contraseña
3. **Variables JWT (opcional)**:
   - `JWT_SECRET`: Clave secreta para firmar tokens (por defecto tiene un valor)
   - `JWT_EXPIRATION`: Tiempo de expiración en ms (86400000 = 24 horas)

Tabla de usuarios:
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255),
    password VARCHAR(255) NOT NULL
);
```

---

## ⚙️ Para ejecutar localmente:

```bash
# En la carpeta del proyecto
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
./mvnw spring-boot:run
```

La API estará disponible en: `http://localhost:8080`

---

## 🚨 Próximas mejoras recomendadas:

1. **Encriptar contraseñas** - Usar BCrypt o similar (🔴 CRÍTICO)
2. ✅ **Generar JWT Token** - Ya implementado
3. **Validaciones** - Email format, password strength
4. **Manejo de errores mejorado** - Respuestas más descriptivas
5. **Refresh Tokens** - Token refresh después de expiración
6. **CORS mejorado** - Configurar origenes específicos en producción

---

## 🔧 Cambios implementados:

- ✅ JWT Service creado para generar y validar tokens
- ✅ AuthService actualizado para retornar LoginResponse con token
- ✅ AuthController retorna token JWT
- ✅ JwtFilter para validar tokens en peticiones protegidas
- ✅ SecurityConfig con CORS y autorización
- ✅ Dependencias JJWT agregadas al pom.xml


