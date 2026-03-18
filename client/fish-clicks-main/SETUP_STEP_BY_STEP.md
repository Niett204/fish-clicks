# 📋 GUÍA PASO A PASO - EJECUTAR EL SISTEMA COMPLETO

## 🎯 Objetivo
Ejecutar el sistema de login localmente y probarlo end-to-end.

---

## ⏱️ Tiempo estimado: 10-15 minutos

---

## PASO 1: Preparar PostgreSQL

### 1.1 Conectarse a PostgreSQL
```bash
psql -U postgres -h localhost
```

### 1.2 Seleccionar o crear base de datos
```sql
-- Si la BD no existe, crearla
CREATE DATABASE fish_clicks;

-- Conectarse a la BD
\c fish_clicks
```

### 1.3 Crear tabla de usuarios (si no existe)
```sql
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255),
    password VARCHAR(255) NOT NULL
);
```

### 1.4 Insertar usuario de prueba
```sql
-- Limpiar usuarios previos (opcional)
DELETE FROM users WHERE email = 'test@example.com';

-- Insertar nuevo usuario
INSERT INTO users (email, username, password) 
VALUES ('test@example.com', 'testuser', 'password123');

-- Verificar que se insertó
SELECT * FROM users;
-- Debe mostrar: 1 | test@example.com | testuser | password123
```

### 1.5 Salir de PostgreSQL
```sql
\q
```

✅ **PostgreSQL está listo**

---

## PASO 2: Ejecutar Backend

### 2.1 Abrir Terminal 1
```bash
cd /home/jfriera03/Documentos/fish-clicks/fish-clicks-api
```

### 2.2 Establecer variables de entorno
```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/fish_clicks
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=tu_password_postgres
```

**Nota:** Reemplaza `tu_password_postgres` con tu contraseña real de PostgreSQL

### 2.3 Ejecutar la aplicación
```bash
./mvnw spring-boot:run
```

### 2.4 Esperar a ver esto:
```
...
Started FishClicksApiApplication in X.XXX seconds (JVM running for X.XXX)
```

✅ **Backend está corriendo en http://localhost:8080**

---

## PASO 3: Probar Backend (Opcional)

### 3.1 Abrir Terminal 2
```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 3.2 Ver respuesta exitosa
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": 1
}
```

✅ **Backend está respondiendo correctamente**

---

## PASO 4: Abrir Godot

### 4.1 Terminal 3 (nueva)
```bash
cd /home/jfriera03/Documentos/fish-clicks/client/fish-clicks-main
```

### 4.2 Ejecutar Godot
```bash
godot --path .
```

### 4.3 Esperar a que abra
- Espera a que la ventana de Godot se abra
- Espera a que cargue el proyecto

✅ **Godot está abierto con el proyecto cargado**

---

## PASO 5: Ejecutar en Godot

### 5.1 Asegúrate de que puedas ver
```
Pantalla de juego con:
- Fondo
- Botones en la esquina superior: ⚙️ 💰 📊 📚 🎒 🛍️
- Área de cofre en el centro
```

### 5.2 Presiona F5 o el botón Play
```
El juego debe iniciar
```

✅ **Juego está corriendo**

---

## PASO 6: Probar Login

### 6.1 Haz clic en el botón de perfil
```
Localización: Esquina superior izquierda
Icono: ⚙️ (el primero de la fila)
```

### 6.2 Se debe abrir una ventana
```
╔════════════════════════════╗
║    Iniciar Sesión         ║
║                            ║
║ Correo: [              ]  ║
║ Contraseña: [         ]   ║
║ [ Iniciar ] [ Cancelar]  ║
╚════════════════════════════╝
```

✅ **Panel de login abierto**

### 6.3 Ingresa los datos
- Email: `test@example.com`
- Contraseña: `password123`

### 6.4 Presiona "Iniciar Sesión"

### 6.5 Verifica el resultado
```
Esperado:
- Mensaje "¡Login exitoso!" en verde
- Panel se cierra automáticamente
- Sesión guardada en GlobalData
```

✅ **Login exitoso!**

---

## PASO 7: Verificar Sesión Guardada

### 7.1 Abre la consola de Godot
```
En Godot: Ver > Consola (o presiona Shift+Alt+C)
```

### 7.2 Crea un script temporal para verificar
```gdscript
extends Node

func _ready():
    if GlobalData.is_logged_in:
        print("✓ Usuario logueado: ", GlobalData.user_email)
        print("✓ ID: ", GlobalData.user_id)
        print("✓ Token: ", GlobalData.user_token)
    else:
        print("✗ No hay sesión")
```

### 7.3 Verifica en la consola
```
✓ Usuario logueado: test@example.com
✓ ID: 1
✓ Token: eyJhbGciOiJIUzUxMiJ9...
```

✅ **Sesión está correctamente almacenada**

---

## PASO 8: Probar Datos en Otra Petición

### 8.1 Crea un script de prueba
```gdscript
extends Node

func _ready():
    if GlobalData.is_logged_in:
        var headers = [
            "Content-Type: application/json",
            "Authorization: " + GlobalData.get_auth_header()
        ]
        
        print("Headers para petición:")
        print(headers[1])
        # Debe mostrar: "Authorization: Bearer eyJh..."
```

### 8.2 Verifica que el token está disponible

✅ **Token disponible para usar**

---

## TROUBLESHOOTING

### Problema: "No se conecta a PostgreSQL"
**Solución:**
1. Verifica que PostgreSQL está corriendo: `pg_isready`
2. Verifica la contraseña en SPRING_DATASOURCE_PASSWORD
3. Verifica el puerto: `5432`

### Problema: "Usuario no encontrado"
**Solución:**
1. Verifica que el usuario existe: `SELECT * FROM users;`
2. Verifica el email exacto
3. Reinserta el usuario

### Problema: "Backend no responde"
**Solución:**
1. Verifica que está corriendo: `curl http://localhost:8080`
2. Verifica JAVA_HOME: `echo $JAVA_HOME`
3. Mira el error en la terminal del backend

### Problema: "Panel no abre"
**Solución:**
1. Verifica que GlobalData está en project.godot autoload
2. Verifica que LoginPanel.tscn existe
3. Abre la consola y mira errores

### Problema: "Login exitoso pero no guarda"
**Solución:**
1. Verifica que GlobalData es autoload
2. Verifica que set_user_session() se está llamando
3. Abre la consola y mira errores

---

## VERIFICACIÓN FINAL

### Checklist de éxito
- [x] PostgreSQL corriendo
- [x] Usuario 'test@example.com' existe en BD
- [x] Backend corriendo en puerto 8080
- [x] Godot abierto y corriendo
- [x] Panel de login abre
- [x] Login es exitoso
- [x] Token se guarda en GlobalData
- [x] Token disponible para futuras peticiones

Si todo está marcado ✓, **¡el sistema está funcionando correctamente!**

---

## PRÓXIMOS PASOS

Una vez que funciona:

1. **Crear más usuarios de prueba**
   ```sql
   INSERT INTO users (email, username, password) 
   VALUES ('otro@example.com', 'otro', 'password');
   ```

2. **Hacer compras autenticadas** (cuando tengas ese endpoint)
   ```gdscript
   var headers = ["Authorization: " + GlobalData.get_auth_header()]
   ```

3. **Implementar logout**
   ```gdscript
   GlobalData.clear_session()
   ```

4. **Mostrar usuario en HUD**
   ```gdscript
   if GlobalData.is_logged_in:
       user_label.text = "Hola " + GlobalData.user_email
   ```

---

## 📞 REFERENCIAS RÁPIDAS

| Necesito... | Buscar en... |
|-------------|------------|
| Ayuda general | QUICK_REFERENCE.md |
| Cómo usar en Godot | GODOT_LOGIN_GUIDE.md |
| Entender arquitectura | LOGIN_SYSTEM_DOCS.md |
| Ver cómo se ve | VISUAL_GUIDE.md |
| Integrar con tienda | TIENDA_INTEGRATION_GUIDE.md |
| Probar backend | JWT_TESTING_GUIDE.md |

---

## ✅ COMPLETADO

Si completaste todos los pasos hasta aquí, **¡tu sistema de login está funcionando correctamente!**

🎉 **¡Listo para desarrollar más features!**

