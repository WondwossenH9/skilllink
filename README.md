# SkillLink

A three-tier web application for skill swapping - a mini marketplace where users can offer and request skills.

## Architecture

- **Frontend**: React application (deployed on S3 + CloudFront)
- **Backend**: Node.js/Express API (deployed on EC2 t2.micro)
- **Database**: PostgreSQL (AWS RDS free tier)

## Features

- User registration and authentication
- Post skill offers (e.g., "I can teach Excel basics")
- Post skill requests (e.g., "I want to learn Git")
- Browse and search available skills
- Match skill offers with requests
- User profiles and skill ratings

## AWS Free Tier Deployment

This application is optimized for AWS free tier deployment:
- EC2 t2.micro instance for the backend
- RDS PostgreSQL db.t3.micro with 20GB storage
- S3 bucket for frontend hosting and static assets
- CloudFront distribution (optional)

## Getting Started

See the setup instructions in each component's directory:
- [Frontend Setup](./frontend/README.md)
- [Backend Setup](./backend/README.md)
- [Deployment Guide](./docs/deployment.md)
