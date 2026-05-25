# Fish Clicks

**Fish Clicks** es un proyecto híbrido que combina un **backend en Spring Boot** (`fish-clicks-api`) con un **cliente en Godot** (`fish-clicks-main`). Es un juego interactivo de acuario con minijuegos.

## Descripción general

La estructura del código está organizada siguiendo una separación por responsabilidades, lo que facilita el mantenimiento, la lectura y la evolución del proyecto.

## Tecnologías utilizadas

- **Java**
- **Spring Boot**
- **Maven**
- **SQL**
- **Docker**
- **Git**
- **GdScript** (Godot)

## Organización del proyecto

### Backend (`fish-clicks-api`)

API REST desarrollada en **Java + Spring Boot** que gestiona:

- `src/main/java`: código fuente principal
    - `controller`: expone los endpoints de la aplicación
    - `service`: incluye la lógica de negocio
    - `repository`: gestiona el acceso a datos
    - `model` o `entity`: define las entidades del dominio
    - `dto`: agrupa objetos de transferencia de datos
    - `config`: contiene configuraciones generales

- `src/main/resources`: recursos de configuración
    - `application.properties` o `application.yml`: configuración de Spring Boot
    - Scripts SQL y archivos estáticos

- `src/test/java`: pruebas automatizadas

- `Dockerfile`: configuración para contenedores

### Cliente (`fish-clicks-main`)

Aplicación de escritorio en **Godot (GdScript)** que proporciona:

- `scenes/`: escenas y componentes visuales del acuario
- `scripts/`: lógica de GdScript para interactividad
- `assets/`: recursos gráficos (peces, fondos, UI, minijuegos)
- `autoload/`: datos globales y paneles persistentes
- `project.godot`: configuración del proyecto Godot

## Flujo de funcionamiento

1. El **cliente Godot** renderiza la interfaz del acuario
2. Las **acciones del usuario** se envían al backend mediante peticiones HTTP
3. El **backend Spring Boot** procesa la lógica de negocio y persiste en la BD
4. La **API REST** devuelve los datos actualizados al cliente
5. El **cliente actualiza** la interfaz con la información recibida

## Compilación y ejecución

**Backend**:

```bash
mvn clean install
mvn spring-boot:run
```

**Cliente**:

El juego puede descargarse desde el siguiente enlace:

[Descargar Fish Clicks](https://drive.google.com/file/d/1hb8xi3c5i1HBAREEgz3oAXwgdtc4MEpL/view?usp=drive_link)

Una vez descargado, basta con ejecutar el `.exe` incluido.

## Configuración con Docker

Para ejecutar el backend en contenedores:

```bash
docker-compose up
````
