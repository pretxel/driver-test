# Context: The platform will enable dispatchers to efficiently manage vehicle relocation requests, centralizing data through a web interface connected to a proprietary REST API.

# Goal: Create a driver mobile app

# Features

- Feature 1:
The user should be authenticated by Google integration
The system must display a "Sign in with Google" button on the landing page

- Feature 2:
Browse Available Relocations (Pending Requests),
Drivers can view and browse a centralized list of all relocation requests with a PENDING status


API endpoint: POST /api/v1/relocations 

- Feature 3:
One-Tap Booking with Confirmation, the driver can instantly assign a relocation request with a single action. Upon selection, the system will trigger a confirmation flow, the request status is updated from PENDING to IN_PROGRESS

API endpoint: PUT /api/v1/relocations/{id}

- Feature 4:
View your booked relocations, Drivers can access a dedicated view of all relocation requests with a IN_PROGRESS, COMPLETED or CANCELLED status

API endpoint: GET  /api/v1/relocations

The base API URL is: https://vfmtrozkajbwaxdgdmys.supabase.co/functions/v1/api 

Tech Stack:
- Flutter 3
- Supabase to authentication
