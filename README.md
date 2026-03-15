# PlaniFy Finance — App iOS (Flutter)

Versión móvil iOS de PlaniFy Finance. Consume la misma API que el dashboard web.

**API:** `https://planifynance.up.railway.app/api`

## Setup inicial (solo primera vez)

Necesitás Flutter SDK instalado. Si no lo tenés:
```bash
brew install --cask flutter
flutter doctor  # verificar que todo esté ok
```

### 1. Generar el scaffold de iOS/Android
Desde la raíz del proyecto (`ControlDeGastos/`):
```bash
cd mobile
flutter create --platforms=ios,android --project-name planify_finance .
```
> Esto genera los directorios `ios/` y `android/` con todos los archivos nativos necesarios.
> No sobreescribe los archivos `.dart` existentes en `lib/`.

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar permisos de red en iOS

En `ios/Runner/Info.plist`, dentro del tag `<dict>` principal, agregar:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>planifynance.up.railway.app</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key>
      <false/>
      <key>NSIncludesSubdomains</key>
      <true/>
    </dict>
  </dict>
</dict>
```
> El backend usa HTTPS, esto solo asegura que iOS permita las conexiones a Railway.

### 4. Correr en simulador iOS
```bash
open -a Simulator  # abrir simulador iOS
flutter run        # detecta el simulador automáticamente
```

### 5. Correr en dispositivo físico
```bash
flutter devices           # listar dispositivos
flutter run -d <device_id>
```

---

## Estructura del proyecto

```
lib/
├── main.dart                        # Entrada + NavigationBar (3 tabs)
├── theme/
│   └── app_theme.dart               # AppColors + ThemeData dark
├── models/
│   ├── user.dart                    # User(id, name)
│   └── dashboard_data.dart          # DashboardData + CategoryData + Movimiento
├── services/
│   └── api_service.dart             # Singleton HTTP client
├── providers/
│   └── wallet_provider.dart         # ChangeNotifier: estado global
├── screens/
│   ├── dashboard/
│   │   └── dashboard_screen.dart    # Vista resumen + bar chart
│   └── my_wallet/
│       └── my_wallet_screen.dart    # Vista billetera + pie chart
└── widgets/
    ├── stat_card.dart               # Card reutilizable de estadística
    └── movement_tile.dart           # Tile de movimiento individual
```

## Pantallas

| Tab | Pantalla | Datos |
|-----|----------|-------|
| Dashboard | Resumen general + bar chart por categoría + movimientos recientes | `/api/dashboard/:id` |
| Mi Billetera | Salario, gastos fijos/tarjeta/variable, pie chart, últimos 5 movimientos | `/api/dashboard/:id` |
| Historial | Próximamente | — |

## Paleta de colores

| Nombre | Hex | Uso |
|--------|-----|-----|
| background | `#050816` | Fondo de pantallas |
| surface | `#0F172A` | Cards, navigation bar |
| accent | `#22D3EE` | Cyan — color principal, íconos activos |
| textPrimary | `#F1F5F9` | Texto principal |
| textSecondary | `#94A3B8` | Labels, subtítulos |
| rose | `#F43F5E` | Gastos, valores negativos |
| green | `#22C55E` | Margen positivo |
| amber | `#F59E0B` | Gastos variables |
| purple | `#A855F7` | Categoría pie chart |
