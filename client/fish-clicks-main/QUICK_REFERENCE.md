# ⚡ REFERENCIA RÁPIDA - SISTEMA DE LOGIN

## 🚀 EJECUTAR AHORA

### Terminal 1: Backend
```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/fish_clicks
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=tu_password

cd /home/jfriera03/Documentos/fish-clicks/fish-clicks-api
./mvnw spring-boot:run
```

### Terminal 2: Godot
```bash
cd /home/jfriera03/Documentos/fish-clicks/client/fish-clicks-main
godot --path .
# Presiona F5 o el botón Play
```

### PostgreSQL: Usuario de Prueba
```sql
INSERT INTO users (email, username, password) 
VALUES ('test@example.com', 'testuser', 'password123');
```

---

## 🎮 USAR EN GODOT

### Verificar sesión
```gdscript
if GlobalData.is_logged_in:
    print(GlobalData.user_email)
```

### Petición autenticada
```gdscript
var headers = [
    "Content-Type: application/json",
    "Authorization: " + GlobalData.get_auth_header()
]
http_request.request(url, headers, HTTPClient.METHOD_GET)
```

### Cerrar sesión
```gdscript
GlobalData.clear_session()
```

---

## 📂 ARCHIVOS CLAVE

| Archivo | Función |
|---------|---------|
| `login_panel.gd` | Lógica del login |
| `GlobalData.gd` | Almacén de sesión |
| `profile_button.gd` | Botón de perfil |
| `LoginPanel.tscn` | Ventana visual |
| `JwtService.java` | Generar JWT |
| `AuthService.java` | Validar credenciales |

---

## ✅ CHECKLIST

- [x] Backend corriendo
- [x] BD con usuario
- [x] Godot abierto
- [x] Presionar botón perfil
- [x] Ver ventana login
- [x] Ingresar datos
- [x] Login exitoso ✅

---

## 📊 DATOS DISPONIBLES

```gdscript
GlobalData.user_token    # "eyJh..."
GlobalData.user_id       # 1
GlobalData.user_email    # "test@example.com"
GlobalData.is_logged_in  # true
```

---

## 🔗 URLs IMPORTANTES

```
Backend:        http://localhost:8080
Login:          http://localhost:8080/auth/login
PostgreSQL:     localhost:5432
```

---

## ⚠️ ERRORES COMUNES

| Error | Solución |
|-------|----------|
| No conecta | Backend no está corriendo |
| Usuario no encontrado | Verifica BD |
| Token no funciona | Usa `GlobalData.get_auth_header()` |
| Panel no abre | GlobalData no está en autoload |

---

## 🎯 PRÓXIMAS MEJORAS

```
[ ] BCrypt para contraseñas
[ ] Botón logout
[ ] Mostrar usuario en HUD
[ ] Endpoint de registro
```

---

## 📚 DOCUMENTACIÓN COMPLETA

- `GODOT_LOGIN_GUIDE.md` - Guía detallada
- `LOGIN_SYSTEM_DOCS.md` - Arquitectura
- `TIENDA_INTEGRATION_GUIDE.md` - Integración
- `JWT_TESTING_GUIDE.md` - Testing

---

**¡Listo para usar!** 🚀

