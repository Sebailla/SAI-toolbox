# Arquitectura Hexagonal (Clean Architecture)

**Autor:** Sebastián Illa  
**Fecha:** 2026-04-13  
**Última modificación:** 2026-04-15

---

## Concepto

Hexagonal Architecture (también llamada Ports & Adapters o Clean Architecture) busca **separar la lógica de negocio de todo lo externo**: frameworks, bases de datos, APIs, interfaces de usuario.

La idea es que tu lógica de negocio sea testeable, portable y no dependa de implementaciones concretas.

---

## Las Tres Capas

```
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN                                  │
│  (¿QUÉ es el negocio? Reglas, entidades, lógica pura)      │
│  NO depende de nada externo                                  │
├─────────────────────────────────────────────────────────────┤
│                      APPLICATION                             │
│  (¿QUÉ puede hacer el usuario? Casos de uso, servicios)    │
│  Depende SOLO de Domain                                       │
├─────────────────────────────────────────────────────────────┤
│                    INFRASTRUCTURE                            │
│  (¿CÓMO se hace? Adaptadores, implementaciones concretas)    │
│  Implementa las interfaces de Domain/Application              │
└─────────────────────────────────────────────────────────────┘
```

### Domain (Centro)
- **NO tiene dependencias externas** (no Prisma, no Express, no React)
- Entidades con reglas de negocio
- Value Objects (Email, Money, etc.)
- Eventos de dominio
- Interfaces (puertos) que Infrastructure va a implementar

### Application
- Casos de uso que orquestan el dominio
- Recibe y devuelve DTOs (no entidades)
- Define puertos de entrada (interfaces para controllers)
- No sabe cómo se persiste ni cómo se entregan los datos

### Infrastructure
- **Implementa las interfaces** definidas en Domain/Application
- Adaptadores concretos: PrismaRepository, ExpressController, etc.
- Acá van TODAS las dependencias de frameworks

---

## Estructura Completa

```
src/
├── domain/
│   ├── entities/              # Entidades del negocio
│   │   └── User.ts           # class User { id, email, name... }
│   ├── value-objects/         # Objetos que son valores inmutables
│   │   └── Email.ts          # class Email { value, equals()... }
│   ├── services/              # Servicios de dominio (lógica pura)
│   │   └── UserService.ts    # Lógica de negocio sin side effects
│   ├── events/                # Eventos que emite el dominio
│   │   └── UserCreated.ts
│   ├── exceptions/            # Excepciones específicas del dominio
│   │   └── UserNotFound.ts
│   └── interfaces/            # CONTRATOS (puertos de salida)
│       └── IUserRepository.ts # interface que Infrastructure implementa
│
├── application/
│   ├── use-cases/             # Casos de uso (orquestan dominio)
│   │   └── CreateUserUseCase.ts
│   ├── dto/                   # Data Transfer Objects
│   │   └── CreateUserDTO.ts
│   └── ports/                # Puertos de entrada (interfaces para controllers)
│       └── IUserController.ts
│
├── infrastructure/
│   ├── persistence/           # Adaptador de base de datos
│   │   └── repositories/
│   │       └── PrismaUserRepository.ts  # implements IUserRepository
│   ├── http/                  # Adaptador web
│   │   ├── controllers/
│   │   │   └── UserController.ts  # implements IUserController
│   │   └── middleware/
│   ├── queue/                  # Adaptador de colas
│   └── external/               # Servicios externos (APIs de terceros)
│
└── shared/                    # Utilidades compartidas
    ├── constants/
    ├── types/
    └── utils/
```

---

## Reglas de Dependencia (ABSOLUTAS)

```
Domain ──────────────────────► Application
    │                                 │
    │                                 ▼
    │                           Infrastructure
    │                                 ▲
    └─────────────────────────────────┘
         (SÓLO define interfaces)

❌ Domain NO puede importar de Application ni Infrastructure
❌ Application NO puede importar de Infrastructure
❌ Infrastructure SÍ implementa interfaces de Domain y Application
```

---

## Ejemplo: Crear un Usuario

### 1. Domain define el contrato

```typescript
// domain/interfaces/IUserRepository.ts
export interface IUserRepository {
  save(user: User): Promise<void>;
  findByEmail(email: string): Promise<User | null>;
}
```

### 2. Domain define la entidad

```typescript
// domain/entities/User.ts
export class User {
  constructor(private props: { id: string; email: string; name: string }) {}

  get email(): string { return this.props.email; }

  static create(email: string, name: string): User {
    if (!email.includes('@')) throw new InvalidEmailError();
    return new User({ id: crypto.randomUUID(), email, name });
  }
}
```

### 3. Application define el caso de uso

```typescript
// application/use-cases/CreateUserUseCase.ts
export class CreateUserUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(dto: CreateUserDTO): Promise<UserDTO> {
    // Validaciones de aplicación
    const existing = await this.userRepo.findByEmail(dto.email);
    if (existing) throw new UserAlreadyExistsError();

    // Crear entidad
    const user = User.create(dto.email, dto.name);
    await this.userRepo.save(user);

    // Retornar DTO, NO la entidad directamente
    return { id: user.id, email: user.email };
  }
}
```

### 4. Infrastructure implementa el contrato

```typescript
// infrastructure/persistence/PrismaUserRepository.ts
export class PrismaUserRepository implements IUserRepository {
  async save(user: User): Promise<void> {
    await prisma.user.create({ data: { id: user.id, email: user.email } });
  }

  async findByEmail(email: string): Promise<User | null> {
    const prismaUser = await prisma.user.findUnique({ where: { email } });
    if (!prismaUser) return null;
    return new User({ id: prismaUser.id, email: prismaUser.email, name: prismaUser.name });
  }
}
```

### 5. Infrastructure define el controller

```typescript
// infrastructure/http/UserController.ts
export class UserController implements IUserController {
  constructor(private createUserUseCase: CreateUserUseCase) {}

  async handle(req: Request, res: Response): Promise<void> {
    const dto = CreateUserDTO.parse(req.body);
    const result = await this.createUserUseCase.execute(dto);
    res.status(201).json(result);
  }
}
```

---

## Ventajas

1. **Testeable:** Domain y Application se testean sin base de datos ni frameworks
2. **Portable:** Podés cambiar de Prisma a Drizzle sin tocar el dominio
3. **清晰 Separación:** Cada cosa tiene su lugar y responsabilidad
4. **Escalable:** Agregar nuevos adaptadores (GraphQL, CLI) no afecta el dominio

## Desventajas

1. **Boilerplate:** Mucho código para cosas simples
2. **Curva de aprendizaje:** Dificil al principio
3. **Overhead:** overkill para proyectos pequeños

---

## Cuándo usar Hexagonal

✅ **Ideal para:**
- Lógica de negocio compleja y compartida
- Proyectos que van a escalar en código
- Necesitás cambiar implementaciones (base de datos, APIs)
- Múltiples canales de entrada (REST, GraphQL, CLI, etc.)

❌ **Considerar Modular si:**
- Projeto pequeño/mediano
- Features claramente separados
- Equipo nuevo en arquitectura

---

## Ports y Adapters

| Tipo | Nombre | Propósito |
|------|--------|-----------|
| **Port (in)** | IUserController | Contrato para recibir requests |
| **Port (out)** | IUserRepository | Contrato para persistir datos |
| **Adapter (in)** | UserController | Implementa cómo llegan los requests |
| **Adapter (out)** | PrismaUserRepository | Implementa cómo se persiste |
