# HabitosApp

App de hábitos en Flutter con una base de datos SQLite local.

## Cómo empezar

1. Ejecutar `flutter pub get`.
2. Abrir un emulador Android o conectar un móvil y ejecutar `flutter run`.
3. También se puede ejecutar en Windows con `flutter run -d windows`.
4. Crear una cuenta. La primera será administradora; las siguientes serán usuarios normales.

En Windows hay que activar el **Modo de desarrollador** en Configuración para que Flutter pueda usar los complementos. Hace falta tener instaladas las herramientas de escritorio de Flutter para compilar en Windows.

Esta versión usa SQLite en Android y escritorio. No está preparada para ejecutarse en Chrome o Edge.

## Qué puede hacer cada cuenta

- Usuario: crear, ver, editar y borrar sus hábitos, marcar el día y consultar sus estadísticas.
- Administrador: gestionar los usuarios, los hábitos de cualquier cuenta y las estadísticas. Puede cambiar roles y asignar hábitos a otro usuario.
- Debe quedar al menos un administrador. La aplicación no deja borrar o quitar el rol al último.
- Los ajustes permiten cambiar el tema, el tamaño de letra, el objetivo diario y ocultar hábitos completados.
- El administrador puede restablecer toda la instalación desde Ajustes, con confirmación.

Se pide iniciar sesión al abrir la app. No se guarda la contraseña en las preferencias. En la base de datos se guarda su hash con bcrypt.

## Organización

- `lib/models/`: clases Usuario, Habito y Estadistica.
- `lib/services/base_datos_service.dart`: creación de tablas, consultas y comprobación de permisos.
- `lib/services/preferencias_service.dart`: ajustes, objetivos y aperturas.
- `lib/screens/`: pantallas de la app.
- `lib/widgets/`: formulario de usuario y diálogos compartidos.
- `test/`: pruebas de datos, permisos, rachas y formularios.

## Base de datos

Las tablas se llaman `usuarios`, `habitos` y `estadisticas` (sin tildes en SQL).

Cada hábito tiene un `usuario_id`. Cada estadística tiene un `habito_id`, que no se repite. Si se borra un usuario, se borran sus hábitos y estadísticas; si se borra un hábito, se borra su estadística.

Las fechas completadas se guardan como una lista en texto JSON, con formato `AAAA-MM-DD`. El administrador puede corregirlas en la edición del hábito. Al marcar o desmarcar hoy se actualizan las fechas y las estadísticas en la misma operación.

La racha cuenta los días seguidos hasta hoy, o hasta ayer si hoy todavía no se ha completado. Una fecha repetida cuenta una sola vez.

El administrador también puede corregir manualmente la racha y el total. Estas correcciones duran hasta volver a marcar el hábito o cambiar su historial. Al borrar una estadística se conservan el hábito y sus fechas; se puede crear otra desde Estadísticas, o se vuelve a crear al marcar el hábito.

SQLite guarda usuarios, hábitos y estadísticas. `shared_preferences` guarda los ajustes, el objetivo de cada usuario, el contador de aperturas, la última apertura y las últimas 20 aperturas. Así se usan los cinco tipos de preferencias sin guardar los hábitos dos veces.

La base de datos se crea en la carpeta de datos de la aplicación, fuera del repositorio. No había datos persistidos en la versión inicial de este proyecto, por lo que no hay una migración de hábitos antiguos.

## Comprobaciones

```text
flutter analyze
flutter test
```

Las pruebas de SQLite usan datos temporales, sin tocar las cuentas de la app.

Documentación consultada: [sqflite](https://pub.dev/packages/sqflite), [shared_preferences](https://pub.dev/packages/shared_preferences), [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) y [bcrypt](https://pub.dev/packages/bcrypt).
