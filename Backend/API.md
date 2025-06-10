# API Routes

## POST

### `/create-event`

Creates a new event in a cove. User must be either the cove creator or an admin.

Takes Data Parameters:
* name: String (required)
* description: String (optional)
* date: ISO 8601 string (required)
* location: String (required)
* coverPhoto: String (optional, base64 encoded)
* coveId: String (required)

Returns:
* message: String
* event: { 
  * id: String
  * name: String
  * description: String
  * date: String
  * location: String
  * coveId: String
  * createdAt: DateTime
}

### `/create-cove`

Creates a new cove. User must be verified to create a cove.

Takes Data Parameters:
* name: String (required)
* description: String (optional)
* location: String (required)
* coverPhoto: String (optional, base64 encoded)

Returns:
* message: String
* cove: { 
  * id: String
  * name: String
  * description: String
  * location: String
  * createdAt: DateTime
}

### `/login`

Authenticates a user and returns their basic information.

Returns: 
* message: String
* user: { 
  * uid: String
  * onboarding: Bool
}

### `/onboard`

Completes user onboarding by setting up their profile.

Takes Data Parameters: 
* name: String
* birthdate: ISO 8601 string
* hobbies: Array(userHobbies)
* bio: String
* latitude: Double
* longitude: Double
* almaMater: String
* job: String
* workLocation: String
* relationStatus: String
* sexuality: String

Returns: 
* message: string

### `/userImage`

Uploads a user's image (profile picture or additional photo).

Takes Data Parameters:
* base64Image: String
* isProfilePic: Bool

Returns:
* message: String 

### `/contacts`

Retrieves information about contacts based on phone numbers.

Takes Data Parameters:
* phoneNumbers: String[]

Returns: 
* contacts: { 
  * id: String
  * name: String
  * phone: String
  * profilePhotoUrl: String
}

### `/send-friend-request`

Sends a friend request to another user. The recipient must be a registered user.

Takes Data Parameters:
* recipientId: String (required) - The user ID of the recipient

Returns:
* message: String
* request: {
  * id: String
  * senderId: String
  * recipientId: String
  * status: "PENDING"
  * createdAt: DateTime
}

### `/resolve-friend-request`

Accepts or rejects a friend request. Only the recipient can resolve their own friend requests.

Takes Data Parameters:
* requestId: String (required) - The ID of the friend request to resolve
* action: "ACCEPT" | "REJECT" (required) - The action to take on the request

Returns:
* message: String
* friendship: {
  * id: String
  * user1Id: String
  * user2Id: String
  * status: "ACCEPTED"
  * createdAt: DateTime
} (only returned if action is "ACCEPT")

### `/friend-request`

Sends friend requests to one or more users.

Takes Data Parameters:
* toUserIds: String[] (required) - Array of user IDs to send requests to

Returns:
* message: String
* requestIds: String[] - IDs of created friend requests

### `/friend-request/resolve`

Accepts or rejects a friend request.

Takes Data Parameters:
* requestId: String (required) - ID of the friend request to resolve
* accept: Boolean (required) - true to accept, false to reject

Returns:
* message: String

### `/edit-profile`

Edits the current user's profile information. The user must already have a profile instance.

Takes Data Parameters:
* name: String (optional) - User's display name
* bio: String (optional) - User's biography
* interests: String[] (optional) - Array of user's interests
* birthdate: ISO 8601 string (optional) - User's birthdate
* latitude: Number (optional) - User's location latitude
* longitude: Number (optional) - User's location longitude
* almaMater: String (optional) - User's alma mater
* job: String (optional) - User's job title
* workLocation: String (optional) - User's work location
* relationStatus: String (optional) - User's relationship status
* sexuality: String (optional) - User's sexuality
* gender: String (optional) - User's gender

Returns:
* message: String

### `/delete-user`

Deletes the current user and all their associated data, including:
* User profile and photos
* Friendships and friend requests
* Cove memberships
* Event RSVPs
* User-created events
* User-created coves

Returns:
* message: String

### `/delete-event`

Deletes an event and its associated data. Only the event host can delete the event.

Takes Data Parameters:
* eventId: String (required) - ID of the event to delete

Returns:
* message: String

### `/update-event-rsvp`

Updates a user's RSVP status for an event. User must be a member of the event's cove.

Takes Data Parameters:
* eventId: String (required) - ID of the event to RSVP to
* status: String (required) - One of: "GOING", "MAYBE", "NOT_GOING"

Returns:
* message: String
* rsvp: {
  * id: String
  * status: String
  * eventId: String
  * userId: String
  * createdAt: DateTime
}

## GET

### `/profile`

Retrieves a user's profile information.

Takes Query String Parameters: 
* userId: String

Returns: 
* message: String
* profile: {
  * name: String
  * phone: String
  * age: Int
  * birthday: Date
  * interests: String[]
  * latitude: Float
  * longitude: Float
  * almaMater: String
  * job: String
  * workLocation: String
  * relationStatus: String
  * sexuality: String
  * onboarding: Bool
  * photos: photoUrls { 
    * id: String
    * url: String
    * isProfilePic: Bool
  }
  * stats: {
    * friendCount: Number - Total number of friends
    * requestCount: Number - Number of pending friend requests
    * coveCount: Number - Number of coves the user is a member of
  }
}

### `/cove-events`

Retrieves events for a specific cove with pagination. User must be a member of the cove.

Takes Query String Parameters:
* coveId: String (required)
* cursor: String (optional, for pagination)
* limit: Number (optional, defaults to 10, max 50)

Returns:
* events: Array<{
  * id: String
  * name: String
  * description: String | null
  * date: String
  * location: String
  * coveId: String
  * hostId: String
  * hostName: String
  * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
  * createdAt: DateTime
  * coverPhoto: {
    * id: String
    * url: String
  } | null
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/calendar-events`

Retrieves all events from coves the user is a member of, with pagination.

Takes Query String Parameters:
* cursor: String (optional, for pagination)
* limit: Number (optional, defaults to 10, max 50)

Returns:
* events: Array<{
  * id: String
  * name: String
  * description: String | null
  * date: String
  * location: String
  * coveId: String
  * coveName: String
  * hostId: String
  * hostName: String
  * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
  * createdAt: DateTime
  * coverPhoto: {
    * id: String
    * url: String
  } | null
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/friends`

Retrieves a paginated list of the user's friends.

Takes Query String Parameters:
* cursor: String (optional) - ID of the last friendship from previous request
* limit: Number (optional, defaults to 10, max 50)

Returns:
* friends: Array<{
  * id: String
  * name: String
  * profilePhotoUrl: String | null
  * friendshipId: String
  * createdAt: DateTime
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/friend-requests`

Retrieves a paginated list of pending friend requests received by the user

Takes Query String Parameters:
* cursor: String (optional) - ID of the last request from previous request
* limit: Number (optional) - Number of requests to return (default: 10, max: 50)

Returns:
* requests: Array<{
  * id: String
  * sender: {
    * id: String
    * name: String
    * profilePhotoUrl: String | null
  }
  * createdAt: DateTime
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/cove`

Retrieves information about a specific cove. User must be a member of the cove.

Takes Query String Parameters:
* coveId: String (required)

Returns:
* cove: {
  * id: String
  * name: String
  * description: String | null
  * location: String
  * createdAt: DateTime
  * creator: {
    * id: String
    * name: String
  }
  * coverPhoto: {
    * id: String
    * url: String
  } | null
  * stats: {
    * memberCount: Number
    * eventCount: Number
  }
}

### `/cove-members`

Retrieves a paginated list of members in a cove. User must be a member of the cove.

Takes Query String Parameters:
* coveId: String (required)
* cursor: String (optional) - ID of the last member from previous request
* limit: Number (optional, defaults to 10, max 50)

Returns:
* members: Array<{
  * id: String
  * name: String
  * profilePhotoUrl: String | null
  * role: "MEMBER" | "ADMIN"
  * joinedAt: DateTime
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/user-coves`

Retrieves a list of all coves that the authenticated user is a member of.

Returns:
* coves: Array<{
  * id: String
  * name: String
  * coverPhoto: {
    * id: String
    * url: String
  } | null
}>

### `/event`

Retrieves detailed information about a specific event. User must be a member of the event's cove.

Takes Query String Parameters:
* eventId: String (required) - ID of the event to retrieve

Returns:
* event: {
  * id: String
  * name: String
  * description: String | null
  * date: String
  * location: String
  * coveId: String
  * host: {
    * id: String
    * name: String
  }
  * cove: {
    * id: String
    * name: String
  }
  * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
  * coverPhoto: {
    * id: String
    * url: String
  } | null
  * isHost: Boolean - Indicates whether the current user is the host of this event
} 