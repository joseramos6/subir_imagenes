# 🚗 AutoRamos Pro

[![Deploy Flutter Web to GitHub Pages](https://github.com/joseramos6/subir_imagenes/actions/workflows/deploy.yml/badge.svg)](https://github.com/joseramos6/subir_imagenes/actions/workflows/deploy.yml)

**AutoRamos Pro** es una aplicación web moderna de gestión de vehículos construida con Flutter, que permite administrar un inventario completo de automóviles con funcionalidades CRUD y almacenamiento en la nube.

## 🌟 Características Principales

### ✨ Gestión Completa de Vehículos
- **📋 Listado inteligente**: Vista de tarjetas con información detallada
- **➕ Agregar vehículos**: Formulario intuitivo con validaciones
- **✏️ Editar información**: Actualización en tiempo real
- **🗑️ Eliminar registros**: Confirmación de seguridad

### 🔍 Búsqueda Avanzada
- **🔎 Búsqueda en tiempo real**: Filtra por marca, modelo o color
- **🎯 Texto resaltado**: Términos de búsqueda destacados
- **📊 Contador de resultados**: Información contextual
- **🧹 Limpieza rápida**: Botón para limpiar filtros

### 📸 Gestión de Imágenes
- **📱 Compatible multiplataforma**: Web y móvil
- **☁️ Almacenamiento en la nube**: Supabase Storage
- **🖼️ Vista previa**: Visualización inmediata
- **🔄 Actualización de fotos**: Cambio dinámico de imágenes

### 🎨 Diseño Profesional
- **🎯 Tema comercial**: Colores corporativos azul índigo y naranja
- **📱 Responsive**: Adaptable a diferentes pantallas
- **⚡ Animaciones suaves**: Transiciones fluidas
- **🌟 UI moderna**: Material Design 3

## 🛠️ Tecnologías Utilizadas

- **Framework**: Flutter 3.24+
- **Estado**: GetX
- **Backend**: Supabase (REST API)
- **Almacenamiento**: Supabase Storage
- **HTTP**: Dart HTTP package
- **Imágenes**: image_picker, file_picker
- **Deployment**: GitHub Pages

## 🚀 Demo en Vivo

Visita la aplicación: **[AutoRamos Pro](https://joseramos6.github.io/subir_imagenes/)**

## 🔧 Configuración de Desarrollo

### Prerrequisitos
- Flutter SDK 3.24+
- Dart SDK
- Cuenta de Supabase

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/joseramos6/subir_imagenes.git
   cd subir_imagenes
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Supabase**
   - Actualiza la URL y API Key en `lib/main.dart`
   - Configura la tabla `carros` con campos: `id_vehiculo`, `marca`, `modelo`, `color`, `foto`
   - Crea el bucket de almacenamiento `autos`

4. **Ejecutar la aplicación**
   ```bash
   # Para web
   flutter run -d chrome
   
   # Para desarrollo
   flutter run
   ```

## 📦 Estructura del Proyecto

```
subir_imagenes/
├── lib/
│   └── main.dart                 # Aplicación principal
├── web/
│   ├── index.html               # Configuración web
│   └── manifest.json            # PWA manifest
├── .github/workflows/
│   └── deploy.yml               # CI/CD GitHub Actions
└── pubspec.yaml                 # Dependencias
```

## 🗃️ Base de Datos

### Tabla `carros`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id_vehiculo` | INTEGER | ID único (PK, autoincrement) |
| `marca` | TEXT | Marca del vehículo |
| `modelo` | TEXT | Modelo del vehículo |
| `color` | TEXT | Color del vehículo |
| `foto` | TEXT | URL de la imagen |

## 🚀 Deployment

El proyecto se despliega automáticamente en GitHub Pages usando GitHub Actions cuando se hace push a la rama `main`.

### Manual Build
```bash
flutter build web --base-href="/subir_imagenes/"
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👨‍💻 Autor

**José Ramos** - [@joseramos6](https://github.com/joseramos6)

---

⭐ ¡Dale una estrella si te gustó el proyecto!

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
