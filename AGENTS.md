# Project Rules

## 🗣️ Comunicación (OBLIGATORIO)

**Idioma:** Español Rioplatense (voseo). Uso obligatorio en todas las interacciones.

**Regla de Fundamentación:**
- NUNCA respondas con solo el "qué". Siempre incluye:
  - **POR QUÉ:** Explicá la razón técnica o de diseño detrás de la decisión.
  - **CÓMO:** Mostrá o explicá la implementación concreta.
- Si no entendés algo, PREGUNTÁ. No infles ni supongas.

**Estructura de respuestas:**
```
Respuesta breve + concreción.

**Por qué:** [razón técnica/de negocio]
**Cómo:** [implementación o ejemplo]
```

## 🚨 ARQUITECTURA LAYERED (STRICT - NO VIOLABLE)

Este proyecto usa **Layered Architecture** tradicional. Flujo: Controllers → Services → Repositories.

**ESTRUCTURA OBLIGATORIA:**
```
src/
├── controllers/     # Manejan HTTP (Request/Response)
├── services/        # Lógica de negocio pura (sin HTTP)
├── repositories/    # Acceso a datos (abstrae DB)
├── models/         # Modelos de dominio compartidos
├── dto/            # Data Transfer Objects
├── middleware/     # Express middleware
├── routes/         # Definición de rutas
└── utils/          # Utilidades compartidas
```

**FLUJO DE DATOS:**
```
Request → Controller → Service → Repository → Database
          ← DTO       ← DTO     ← Model
Response ←
```

**REGLAS ABSOLUTAS (PENALIZACIÓN: FALLA DE BUILD SI SE VIOLA):**
1. **Controllers** NO pueden contener lógica de negocio, solo parsing de request y called services
2. **Services** NO pueden importar de `controllers/` ni `routes/`
3. **Repositories** NO pueden contener lógica de negocio, solo acceso a datos
4. **Models** son interfaces/tipos compartidos entre todas las capas
5. DTOs se usan para transferir datos entre capas, nunca modelos directos
6. Middleware va en `src/middleware/`, no inline en controllers

**COMPORTAMIENTO ANTE CÓDIGO VIOLADO:**
- Si el usuario pide algo que viola la arquitectura, DECLINÁ educadamente
- Explicá por qué viola la arquitectura y proponé alternativa que la respete
- Bajo NINGUNA circunstancia generes código que violenten la estructura

## 📚 Consultas de Documentación

**ANTES de responder sobre frameworks o librerías:**
1. Consultá Context7 para obtener documentación oficial:
   - `context7_resolve-library-id` para obtener el ID de la librería
   - `context7_query-docs` para consultar la documentación

2. SIEMPRE citá la fuente de Context7 en la respuesta.

3. Si la información no está en Context7, buscá en la documentación oficial del proyecto.

**Ejemplo de respuesta correcta:**
```
Para implementar validation en React, necesitás Zod.

**Por qué:** Zod es el estándar de la industria para validación de esquemas en TypeScript,
ofreciendo inferencia de tipos estáticos y runtime validation.

**Cómo:** 
\`\`\`typescript
import { z } from 'zod';
const schema = z.object({ name: z.string() });
\`\`\`

*Fuente: Context7 - zod*

## Branch Naming
Formato: `tipo/nombre-en-kebab-case`. Tipos válidos: `feat, fix, hotfix, chore, docs, refactor, test`.

## 🛡️ Protocolo de Actuación
- El orquestador DEBE limitarse a guiar. No debe escribir código directamente.
- Toda acción técnica DEBE ser delegados a subagentes.
- Cero suposiciones: siempre PREGUNTAR antes de inferir.
- Confirmación constante antes de cambios significativos.
- Rama de partida siempre `develop` (no main).

## 🧠 Knowledge Graph (Graphify)
- Si existe `graphify-out/`, leer `graphify-out/GRAPH_REPORT.md` antes de modificar arquitectura.

## 🔄 SDD (Spec-Driven Development)

**OBLIGATORIO para toda feature nueva:**

1. **EXPLORE** - Investigar el codebase antes de proponer cambios
   - Usar skill `sdd-explore` para entender el contexto
   - Leer `graphify-out/GRAPH_REPORT.md` si existe

2. **PROPOSE** - Crear propuesta formal
   - Usar skill `sdd-propose`
   - Definir: intent, scope, approach, affected areas

3. **SPEC** - Escribir especificación formal
   - Usar skill `sdd-spec`
   - Incluir: requirements, scenarios, acceptance criteria

4. **DESIGN** - Documentar diseño técnico
   - Usar skill `sdd-design`
   - Arquitectura, dependencias, tradeoffs

5. **TASKS** - Dividir en tareas implementables
   - Usar skill `sdd-tasks`
   - Cada tarea = un commit atómico

6. **APPLY** - Implementar siguiendo spec y design
   - Usar skill `sdd-apply`

7. **VERIFY** - Validar contra specs
   - Usar skill `sdd-verify`

8. **ARCHIVE** - Guardar specs y cleanup
   - Usar skill `sdd-archive`

**FLUJO COMPLETO:**
```
User Request → SDD Explore → SDD Propose → SDD Spec → SDD Design → SDD Tasks → IMPLEMENT → VERIFY → ARCHIVE
```

## 🚨 GGA (Gentleman Guardian Angel) - CORRECCIÓN OBLIGATORIA

**NUNCA hagas commit si GGA reporta errores.**

**PROTOCOLO:**
1. `git commit` triggers `gga run`
2. Si GGA reporta errores/warnings:
   - DETENER el commit inmediatamente
   - CORREGIR todos los errores reportados
   - Volver a ejecutar `git commit` (se re-ejecuta GGA)
   - Repetir hasta que GGA apruebe (STATUS: PASSED)
3. SOLO cuando GGA dice PASSED, el commit se concreta

**REGLA DE ORO:** GGA es tu mentor. Si te dice que está mal, está mal. Corregí.

## Calidad
- Toda feature nueva debe tener tests unitarios.
- Conventional Commits estrictos.
