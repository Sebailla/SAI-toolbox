# Arquitectura Modular Vertical Slicing

**Autor:** Sebastián Illa  
**Fecha:** 2026-04-13  
**Última modificación:** 2026-04-14

---

## Concepto

Modular Vertical Slicing organiza el código por **features o módulos**. Cada módulo es auto-contenido y tiene todo lo que necesita para funcionar de forma independiente.

La idea es que si mañana tuvieras que eliminar un módulo, debería poder hacerse sin romper el resto de la aplicación.

---

## Estructura de un Módulo

```
src/modules/<nombre>/
├── components/      # Componentes React específicos del módulo
├── services/        # Lógica de negocio pura (sin dependencias de UI)
├── actions.ts       # Server Actions (validación + orquestación)
├── types.ts        # Tipos y tipos compartidos del módulo
└── index.ts        # API pública del módulo
```

### components/
Componentes React que solo pertenecen a este módulo. Pueden usar hooks y otras librerías de UI.

**Regla:** NO contienen lógica de negocio. Delegan todo a los services.

### services/
Lógica de negocio pura en funciones/classes TypeScript. **NO pueden:**
- Usar hooks de React
- Importar componentes
- Tener side effects (useEffect, fetch, etc.)

### actions.ts
Server Actions de Next.js que:
1. Validan input con Zod
2. Orquestan la lógica entre services
3. Retornan resultados serializables

### types.ts
Tipos TypeScript específicos del módulo:
- Tipos de datos del dominio
- Tipos de respuesta de API
- Interfaces para contracts internos

### index.ts
Exporta la API pública del módulo para que otros módulos lo consuman.

---

## Módulos Compartidos

### src/core/
Utilidades compartidas que no pertenecen a ningún módulo específico:

```
src/core/
├── lib/           # Funciones utilitarias (formatDate, debounce, etc.)
├── types/         # Tipos globales (User, Config, etc.)
└── hooks/         # Hooks compartidos (useAuth, useToast, etc.)
```

### src/components/ui/
Componentes UI genéricos reusables:

- Button, Input, Dialog, Card, etc.
- No tienen lógica de negocio
- Pueden recibir props de configuración

---

## Reglas de Dependencia

```
┌─────────────────────────────────────────────────────────┐
│  modules/<x>/components  →  modules/<x>/services         │
│  modules/<x>/actions    →  modules/<x>/services         │
│  modules/<x>/services   →  core/lib, core/types         │
│  modules/<x>/components →  components/ui               │
│  modules/<x>/components →  core/hooks                   │
└─────────────────────────────────────────────────────────┘

❌ UN MÓDULO NO PUEDE IMPORTAR DE OTRO MÓDULO DIRECTAMENTE
```

Para comunicar entre módulos, usar:
- Server Actions compartidas en `core/`
- Events o pub/sub
- Context providers en `core/`

---

## Ejemplo: Módulo de Autenticación

```
src/modules/auth/
├── components/
│   ├── LoginForm.tsx
│   ├── RegisterForm.tsx
│   └── ProfileCard.tsx
├── services/
│   ├── auth.service.ts      # Lógica de validación
│   └── token.service.ts     # Manejo de JWT
├── actions.ts               # Server Actions
├── types.ts                 # LoginInput, User, etc.
└── index.ts                 # Exports públicos
```

---

## Ventajas

1. **Auto-contenido:** Cada módulo tiene todo lo que necesita
2. **Eliminable:** Se puede quitar un módulo sin romper otros
3. **Escalable:** Agregar módulos nuevos no afecta los existentes
4. **Testeable:** Los services se testean sin React

## Desventajas

1. **Límites difusos:** A veces es difícil saber si algo va en un módulo o en core
2. **Rey de singleton:** Módulos compartidos pueden crear acoplamiento

---

## Cuándo usar Modular

✅ **Ideal para:**
- Apps con features claramente diferenciados
- Equipos que trabajan en features independientes
- MVPs y proyectos que van a crecer en features

❌ **Considerar Hexagonal si:**
- La lógica de negocio es muy compleja y compartida
- Necesitás cambiar de base de datos o framework sin tocar negocio
- Tenés múltiples canales de entrada (API REST, GraphQL, CLI)
