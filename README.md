# AkaScoreboard

# Sistema de Scoreboard para FiveM ESX Legacy

## Descripción
Sistema completo de scoreboard para FiveM con ESX Legacy que incluye conteo de jugadores en línea, trabajos y sistema de disponibilidad de robos.

## Características

### ✅ Funcionalidades Implementadas
- **Conteo de jugadores en línea**: Muestra el número total de jugadores conectados
- **Conteo de trabajos**: Muestra cuántos jugadores tienen cada trabajo configurado
- **Sistema de robos**: Detecta automáticamente si los robos están disponibles según la cantidad de jugadores en trabajos específicos
- **Panel de administración**: Los administradores pueden cambiar de trabajo con un botón "+"
- **Diseño responsive**: Interfaz moderna basada en la imagen proporcionada
- **Actualización en tiempo real**: Los datos se actualizan automáticamente

### 🎮 Controles
- **F7**: Abrir/cerrar scoreboard
- **ESC**: Cerrar scoreboard

## Instalación

### 1. Estructura de archivos
```
scoreboard/
├── client.lua
├── server.lua
├── fxmanifest.lua
└── html/
    └── index.html
```

### 2. Configuración

En `client.lua` y `server.lua`, encontrarás la configuración en la variable `Config`:

```lua
local Config = {
    Jobs = {
        {name = "police", label = "Policía", icon = "👮", color = "#3b82f6"},
        {name = "ambulance", label = "Ambulancia", icon = "🚑", color = "#ef4444"},
        {name = "mechanic", label = "Mecánico", icon = "🔧", color = "#f59e0b"},
        {name = "taxi", label = "Taxi", icon = "🚕", color = "#eab308"}
    },
    Robberies = {
        {name = "bank", label = "Bank Robbery", requiredJob = "police", requiredCount = 2, icon = "🏦"},
        {name = "pacific", label = "Pacific Robbery", requiredJob = "police", requiredCount = 4, icon = "🏢"},
        {name = "lester", label = "Lester Robbery", requiredJob = "police", requiredCount = 3, icon = "💰"},
        {name = "shop", label = "Shop Robbery", requiredJob = "police", requiredCount = 1, icon = "🏪"}
    },
    AdminGroups = {"admin", "superadmin", "owner"}
}
```

### 3. Personalización

#### Agregar nuevos trabajos:
```lua
{name = "nombre_trabajo", label = "Etiqueta", icon = "🎯", color = "#hexcolor"}
```

#### Agregar nuevos robos:
```lua
{name = "nombre_robo", label = "Etiqueta del Robo", requiredJob = "trabajo_requerido", requiredCount = 2, icon = "🎯"}
```

#### Cambiar grupos de administrador:
```lua
AdminGroups = {"admin", "superadmin", "owner", "mod"}
```

### 4. Instalación en el servidor

1. Coloca la carpeta `scoreboard` en tu directorio `resources`
2. Agrega `start scoreboard` a tu `server.cfg`
3. Reinicia el servidor

## Uso

### Para jugadores:
- Presiona **F7** para abrir el scoreboard
- Visualiza jugadores en línea, trabajos y robos disponibles
- Presiona **ESC** o **F7** nuevamente para cerrar

### Para administradores:
- Aparecerá un botón "+" junto a cada trabajo
- Haz clic en el "+" para cambiar a ese trabajo
- Los cambios se reflejan# Sistema de Scoreboard para FiveM ESX Legacy
