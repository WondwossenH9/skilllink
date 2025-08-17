# SkillLink Frontend

React/TypeScript frontend for the SkillLink skill swapping platform.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Update the `.env` file with your API configuration

4. Start the development server:
```bash
npm start
```

The app will be available at `http://localhost:3000`

## Features

- User authentication (login/register)
- Browse and search skills
- Create and manage skill offers/requests
- Match system for connecting users
- User profiles and ratings
- Responsive design with Tailwind CSS

## Environment Variables

Create a `.env` file with:

```
REACT_APP_API_URL=http://localhost:3001/api
```

## Deployment

The app is configured for deployment on AWS S3 with CloudFront for optimal performance and cost-effectiveness on the free tier.

Build for production:
```bash
npm run build
```

The build folder will contain the optimized production files ready for deployment.
