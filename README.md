![Alt text](https://i.ibb.co/rG0Hh95h/Orderz-House-Logo-01.png)
# OrderzHouse

OrderzHouse is a comprehensive freelance platform that connects clients with freelancers for various projects. The platform includes features for user management, project posting, bidding, messaging, course management, and an admin panel for oversight.

## Project Structure

This repository contains the full-stack application divided into:

- **Frontend**: React-based user interface built with Vite, Redux for state management, and Tailwind CSS for styling.
- **Backend**: Node.js/Express API server with PostgreSQL database, Socket.io for real-time communication, and AdminJS for admin panel.
- **Database**: PostgreSQL database with schema defined in `backendEsModule/models/database_schema.sql`.

## Features

### User Management
- User registration and authentication (including Google OAuth)
- Profile management with portfolio and skills
- User verification system
- Role-based access control (Client, Freelancer, Admin)

### Project Management
- Clients can post projects with budgets and requirements
- Freelancers can browse and bid on projects
- Real-time messaging between clients and freelancers
- Project status tracking and completion

### Course Management
- Course creation and enrollment
- Progress tracking for enrolled courses
- Course materials and resources

### Admin Panel
- User and project oversight
- Analytics and reporting
- System management tools

### Additional Features
- Real-time chat system
- Feedback and review system
- Subscription plans
- News and announcements
- File upload capabilities

## Technology Stack

### Frontend
- React 19
- Vite (build tool)
- Redux Toolkit (state management)
- React Router (routing)
- Tailwind CSS (styling)
- Socket.io-client (real-time communication)
- Axios (HTTP client)

### Backend
- Node.js with ES modules
- Express.js (web framework)
- PostgreSQL (database)
- Socket.io (real-time communication)
- JWT (authentication)
- Multer (file uploads)
- AdminJS (admin panel)

## Getting Started

### Prerequisites
- Node.js (v16 or higher)
- PostgreSQL
- npm or yarn

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd OrderzHouse_fork
   ```

2. Set up the backend:
   ```bash
   cd backendEsModule
   npm install
   # Set up your .env file with database credentials and other configurations
   npm run dev
   ```

3. Set up the frontend:
   ```bash
   cd ../frontend
   npm install
   npm run dev
   ```

4. Set up the database:
   - Create a PostgreSQL database
   - Run the schema from `backendEsModule/models/database_schema.sql`
   - Optionally, use the provided `my_database_dump.sql` for sample data

### Environment Variables

Create a `.env` file in the `backendEsModule` directory with the following variables:
```
PORT=5050
DATABASE_URL=postgresql://username:password@localhost:5432/orderzhouse
JWT_SECRET=your-jwt-secret
GOOGLE_CLIENT_ID=your-google-oauth-client-id
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret

# Email Configuration (Resend)
RESEND_API_KEY=re_YOUR_RESEND_API_KEY
EMAIL_FROM=no-reply@orderzhouse.com
```

## API Documentation

The backend provides RESTful APIs for:
- User management (`/users`)
- Projects (`/projects`)
- Orders (`/orders`)
- Courses (`/courses`)
- Feedback (`/feedbacks`)
- Appointments (`/appointments`)
- Logs (`/logs`)
- News (`/news`)
- File uploads (`/upload`)

Real-time features are handled via Socket.io.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the ISC License.
