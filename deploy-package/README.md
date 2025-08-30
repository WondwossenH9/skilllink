# SkillLink Backend API

RESTful API for the SkillLink skill swapping platform.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Update the `.env` file with your configuration

4. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:3001`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile (protected)
- `PUT /api/auth/profile` - Update user profile (protected)

### Skills
- `GET /api/skills` - Get all skills (with filters)
- `POST /api/skills` - Create new skill (protected)
- `GET /api/skills/:id` - Get skill by ID
- `PUT /api/skills/:id` - Update skill (protected)
- `DELETE /api/skills/:id` - Delete skill (protected)
- `GET /api/skills/my-skills` - Get user's skills (protected)

### Matches
- `GET /api/matches` - Get user's matches (protected)
- `POST /api/matches` - Create match request (protected)
- `PUT /api/matches/:id/status` - Update match status (protected)

### General
- `GET /api/health` - Health check

## Database

The application uses Sequelize ORM and supports both SQLite (development) and PostgreSQL (production).

Models:
- User
- Skill  
- Match
- Rating

## Environment Variables

See `.env.example` for required environment variables.
