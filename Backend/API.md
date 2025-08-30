# API Routes

## POST

### `/create-event`

Creates a new event in a cove. User must be either the cove creator or an admin.

Takes Data Parameters:
* name: String (required)
* description: String (optional)
* date: ISO 8601 string (required)
* location: String (required)
* memberCap: Integer (optional) - Maximum number of attendees
* ticketPrice: Float (optional) - Ticket price in dollars
* paymentHandle: String (optional) - Payment handle (Venmo username, etc.) - Available to all authenticated users
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
  * memberCap: Integer | null
  * ticketPrice: Float | null
  * paymentHandle: String | null (available to all authenticated users)
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

### `/create-thread`

Creates a new messaging thread between users. If a thread already exists between the specified participants, returns the existing thread.

Takes Data Parameters:
* participantIds: String[] (required) - Array of user IDs to include in the thread (excluding the current user)

Returns:
* message: String
* thread: {
  * id: String
  * createdAt: DateTime
  * updatedAt: DateTime
  * members: Array<{
    * id: String
    * userId: String
    * user: {
      * id: String
      * name: String
    }
  }>
}

### `/send-message`

Sends a message to a thread. User must be a member of the thread.

Takes Data Parameters:
* threadId: String (required) - ID of the thread to send message to
* content: String (required) - Message content

Returns:
* message: String
* messageData: {
  * id: String
  * threadId: String
  * senderId: String
  * content: String
  * createdAt: DateTime
  * sender: {
    * id: String
    * name: String
  }
}

### `/mark-message-read`

Marks a message as read by the current user. User must be a member of the thread containing the message.

Takes Data Parameters:
* messageId: String (required) - ID of the message to mark as read

Returns:
* message: String

### `/update-fcm-token`

Updates the user's Firebase Cloud Messaging token for push notifications.

Takes Data Parameters:
* fcmToken: String (required) - The FCM token from the client

Returns:
* message: String

### `/create-post`

Creates a new post in a cove. User must be a member of the cove.

Takes Data Parameters:
* content: String (required) - Post content (max 1000 characters)
* coveId: String (required) - ID of the cove to post in

Returns:
* message: String
* post: {
  * id: String
  * content: String
  * coveId: String
  * authorId: String
  * createdAt: DateTime
}

### `/toggle-post-like`

Toggles a user's like status for a post. If the user has already liked the post, it will unlike it. If they haven't liked it, it will like it.

Takes Data Parameters:
* postId: String (required) - ID of the post to like/unlike

Returns:
* message: String
* action: String - "liked" or "unliked"
* likeCount: Number - Updated like count for the post

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
* name: String (required)
* birthdate: ISO 8601 string (required)
* almaMater: String (required)
* gradYear: String (required)
* hobbies: Array(userHobbies) (optional)
* bio: String (optional)
* latitude: Double (optional - will be geocoded from city if not provided)
* longitude: Double (optional - will be geocoded from city if not provided)
* city: String (optional - will be converted to coordinates if provided)
* job: String (optional)
* workLocation: String (optional)
* relationStatus: String (optional)
* sexuality: String (optional)
* gender: String (optional)

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

Sends friend requests to one or more users. The recipients must be registered users.

Takes Data Parameters:
* toUserIds: String[] (required) - Array of user IDs to send requests to

Returns:
* message: String
* requestIds: String[] - IDs of created friend requests

### `/resolve-friend-request`

Accepts or rejects a friend request. Only the recipient can resolve their own friend requests.

Takes Data Parameters:
* requestId: String (required) - The ID of the friend request to resolve
* action: "ACCEPT" | "REJECT" (required) - The action to take on the request

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
* status: String (required) - One of: "PENDING", "NOT_GOING"

**Note**: When users RSVP, they are automatically set to "PENDING" status and must await host approval to become "GOING". **Exception**: Event hosts can automatically approve themselves and will receive "GOING" status immediately when they RSVP.

Behavior:
* When status = "NOT_GOING": the user's RSVP entry is deleted from the database
* When status = "PENDING": creates or updates user's RSVP to pending approval status
* **Host Auto-Approval**: If the user is the event host, their status is automatically set to "GOING" instead of "PENDING"

Returns:
* message: String - "RSVP removed successfully" when status is "NOT_GOING"; otherwise "RSVP status updated successfully"
* rsvp: {
  * id: String
  * status: String
  * eventId: String
  * userId: String
  * createdAt: DateTime
} | null - Will be null when status is "NOT_GOING"

### `/join-cove`

Joins a cove. User must not already be a member of the cove.

Takes Data Parameters:
* coveId: String (required) - ID of the cove to join

Returns:
* message: String
* member: {
  * id: String
  * coveId: String
  * userId: String
  * role: "MEMBER"
  * joinedAt: DateTime
}

### `/send-invite`

Sends cove invites to phone numbers. Only cove admins can send invites.

Takes Data Parameters:
* coveId: String (required) - ID of the cove to invite to
* phoneNumbers: String[] (required) - Array of phone numbers to invite
* message: String (optional) - Optional invitation message

Duplicate Handling:
* If an invite already exists for a phone number + cove combination, no duplicate is created
* The phone number is added to the errors array with message "Invite already exists for this phone number"
* Processing continues for remaining phone numbers
* If a user is already a member of the cove, they are also added to the errors array

Returns:
* message: String - Summary of operation (e.g., "Successfully sent 2 invites")
* invites: Array<{
  * id: String
  * phoneNumber: String
  * createdAt: DateTime
}> - Successfully created invites
* errors: Array<{
  * phoneNumber: String
  * error: String
}> (optional) - Any errors that occurred during invite creation

## PUT

### `/open-invite`

Marks a cove invite as opened. This endpoint is called when a user taps on an envelope to view the invite details. Only the recipient of the invite can mark it as opened.

Takes Data Parameters:
* inviteId: String (required) - ID of the invite to mark as opened

Returns:
* message: String - Confirmation message
* invite: {
  * id: String
  * message: String | null
  * createdAt: DateTime
  * isOpened: Boolean - Will be true after successful update
  * cove: {
    * id: String
    * name: String
    * description: String | null
    * location: String
    * coverPhotoId: String | null
  }
  * sentBy: {
    * id: String
    * name: String
    * profilePhotoId: String | null
  }
} - The updated invite object with full details

## DELETE

### `/reject-invite`

Rejects and deletes a cove invite. Only the recipient of the invite can reject it. This permanently removes the invite from the database.

Takes Data Parameters:
* inviteId: String (required) - ID of the invite to reject/delete

Returns:
* message: String - Confirmation message ("Invite rejected successfully")

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

### `/threads`

Retrieves all threads that the authenticated user is a member of, ordered by most recent activity.

Returns:
* threads: Array<{
  * id: String
  * createdAt: DateTime
  * updatedAt: DateTime
  * members: Array<{
    * id: String
    * userId: String
    * user: {
      * id: String
      * name: String
    }
  }>
  * lastMessage: {
    * id: String
    * content: String
    * createdAt: DateTime
    * sender: {
      * id: String
      * name: String
    }
  } | null
  * _count: {
    * messages: Number
  }
}>

### `/thread-messages`

Retrieves messages for a specific thread with pagination. User must be a member of the thread.

Takes Query String Parameters:
* threadId: String (required) - ID of the thread to get messages for
* limit: Number (optional, defaults to 50, max 100)
* cursor: String (optional, for pagination)

Returns:
* messages: Array<{
  * id: String
  * threadId: String
  * senderId: String
  * content: String
  * createdAt: DateTime
  * sender: {
    * id: String
    * name: String
  }
  * reads: Array<{
    * id: String
    * readAt: DateTime
    * user: {
      * id: String
      * name: String
    }
  }>
}>
* nextCursor: String | null - For pagination

### `/cove-events`

Retrieves events for a specific cove with pagination. Authentication is optional and each event item is returned in limited or enriched form depending on the caller's relationship to that event.

Takes Query String Parameters:
* coveId: String (required)
* cursor: String (optional, for pagination)
* limit: Number (optional, defaults to 10, max 50)

Behavior:
* If unauthenticated: returns only the first 5 limited events (no pagination object returned)

Returns:
* events: Array of items where each item is either:
  * Limited (unauthenticated or authenticated without RSVP/host for that event):
    * {
      * id: String
      * name: String
      * description: String | null
      * date: String
      * coveCoverPhoto: { id: String, url: String } | null
      * hostName: String
      * coverPhoto: { id: String, url: String } | null
      * rsvpStatus: null (included only when caller is authenticated)
    }
  * Enriched (authenticated and either host or has RSVP for that event):
    * {
      * id: String
      * name: String
      * description: String | null
      * date: String
      * location: String
      * memberCap: Integer | null
      * ticketPrice: Float | null
      * coveId: String
      * coveName: String
      * coveCoverPhoto: { id: String, url: String } | null
      * hostId: String
      * hostName: String
      * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING"
      * goingCount: Number
      * createdAt: DateTime
      * coverPhoto: { id: String, url: String } | null
    }
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
} (present only when authenticated; omitted when unauthenticated)

Caching:
* If any item is enriched: `Cache-Control: private, no-store`, `Vary: Authorization, Cookie`
* If all items are limited: `Cache-Control: public, max-age=60`

### `/upcoming-events`

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
  * memberCap: Integer | null
  * ticketPrice: Float | null
  * coveId: String
  * coveName: String
  * coveCoverPhoto: {
    * id: String
    * url: String
  } | null
  * hostId: String
  * hostName: String
  * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
  * goingCount: Number - Number of users who RSVP'd "GOING"
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

Retrieves events that the user has RSVP'd "GOING" to, with pagination. This endpoint is specifically for calendar view showing committed events.

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
  * memberCap: Integer | null
  * ticketPrice: Float | null
  * coveId: String
  * coveName: String
  * coveCoverPhoto: {
    * id: String
    * url: String
  } | null
  * hostId: String
  * hostName: String
  * rsvpStatus: "GOING" (always "GOING" for this endpoint)
  * goingCount: Number - Number of users who RSVP'd "GOING"
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

### `/recommended-friends`

Retrieves a paginated list of users who are in at least one cove with the current user. Excludes users who are already friends, have pending friend requests, or have received friend requests from the current user.

Takes Query String Parameters:
* cursor: String (optional) - ID of the last user from previous request
* limit: Number (optional, defaults to 10, max 50)

Returns:
* users: Array<{
  * id: String
  * name: String
  * profilePhotoUrl: String | null
  * sharedCoveCount: Number - Number of coves they share with the current user
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/event`

Retrieves detailed information about a specific event. Authentication is optional and the response varies based on the caller's relationship to the event.

Takes Query String Parameters:
* eventId: String (required) - ID of the event to retrieve

Returns:
* When unauthenticated (or authenticated but not host and no GOING RSVP), returns LIMITED details:
  * event: {
    * id: String
    * name: String
    * description: String | null
    * date: String
    * memberCap: Integer | null
    * ticketPrice: Float | null
    * host: {
      * name: String
    }
    * cove: {
      * name: String
      * coverPhoto: {
        * id: String
        * url: String
      } | null
    }
    * goingCount: Integer - Number of users who RSVP'd "GOING"
    * coverPhoto: {
      * id: String
      * url: String
    } | null
  }
  * Caching: `Cache-Control: private, no-store`
* When authenticated (but not host and has no GOING RSVP), the LIMITED response also includes:
  * isHost: Boolean (false)
  * rsvpStatus: "GOING" | "PENDING" | "NOT_GOING" | null (null when no RSVP)
  * Caching: `Cache-Control: private, no-store`
* When authenticated and either the user is the host OR has GOING RSVP status, FULL details are returned (unchanged shape but attendee list is truncated to first 5):
  * event: {
    * id: String
    * name: String
    * description: String | null
    * date: String
    * location: String
    * memberCap: Integer | null
    * ticketPrice: Float | null
    * coveId: String
    * host: {
      * id: String
      * name: String
    }
    * cove: {
      * id: String
      * name: String
      * coverPhoto: {
        * id: String
        * url: String
      } | null
    }
    * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
    * goingCount: Integer - Number of users who RSVP'd "GOING"
    * rsvps (first 10 only): Array<{
      * id: String
      * status: "GOING" | "MAYBE" | "NOT_GOING"
      * userId: String
      * userName: String
      * profilePhotoUrl: String | null
      * createdAt: DateTime
    }>
    * coverPhoto: {
      * id: String
      * url: String
    } | null
    * isHost: Boolean - Indicates whether the current user is the host of this event
  }
  * Caching: `Cache-Control: private, no-store`, `Vary: Authorization, Cookie`

Notes:
- Attendee list hygiene: attendee list is limited to the first 10 RSVPs by most recent.
- Over-fetch prevention: sensitive relations (full RSVP graph) are only fetched when the user is entitled to full details.
- Privacy: Location and guest list (rsvps) are only provided to event hosts or users who have GOING RSVP status.

### `/invites`

Retrieves all invites for the authenticated user based on their phone number.

Returns:
* invites: Array<{
  * id: String
  * message: String | null
  * createdAt: DateTime
  * isOpened: Boolean
  * cove: {
    * id: String
    * name: String
    * description: String | null
    * location: String
    * coverPhotoId: String | null
  }
  * sentBy: {
    * id: String
    * name: String
    * profilePhotoId: String | null
  }
}> 

### `/cove-posts`

Retrieves posts for a specific cove with pagination. User must be a member of the cove.

Takes Query String Parameters:
* coveId: String (required)
* cursor: String (optional, for pagination)
* limit: Number (optional, defaults to 10, max 50)

Returns:
* posts: Array<{
  * id: String
  * content: String
  * coveId: String
  * coveName: String
  * authorId: String
  * authorName: String
  * isLiked: Boolean
  * likeCount: Number
  * createdAt: DateTime
}>
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

### `/post`

Retrieves detailed information about a specific post. User must be a member of the post's cove.

Takes Query String Parameters:
* postId: String (required) - ID of the post to retrieve

Returns:
* post: {
  * id: String
  * content: String
  * coveId: String
  * author: {
    * id: String
    * name: String
  }
  * cove: {
    * id: String
    * name: String
  }
  * isLiked: Boolean
  * likes: Array<{
    * id: String
    * userId: String
    * userName: String
    * createdAt: DateTime
  }> - All likes for this post
  * createdAt: DateTime
  * isAuthor: Boolean - Indicates whether the current user is the author of this post
}

### `/feed`

Retrieves a flexible feed of events and/or posts from coves the user is a member of, with pagination and ranking.

**Ranking Algorithm:**
The feed uses a sophisticated server-side ranking algorithm that considers:
- **Freshness**: Newer content gets higher scores using exponential decay
- **Engagement**: Items with more likes/RSVPs rank higher (future enhancement)
- **Relevance**: Personalized based on user preferences (future enhancement)
- **Time Sensitivity**: Events are weighted by proximity to event date

**Architecture Benefits:**
- Consistent ranking across iOS, Android, and web
- Server-side ranking enables future ML integration
- Supports A/B testing of different ranking strategies
- Cursor pagination ensures stable ordering across requests

Takes Query String Parameters:
* types: String (optional, defaults to "event,post") - Comma-separated list of content types to include: "event", "post", or both
* cursor: String (optional, for pagination)
* limit: Number (optional, defaults to 10, max 50)

Returns:
* items: Array<{
  * kind: "event" | "post" - Discriminator for item type
  * id: String - Unique identifier for the item
  * rank: Number - Ranking score (0.0-1.0) for sorting
  * event: { (only present when kind="event")
    * id: String
    * name: String
    * description: String | null
    * date: String
    * location: String
    * memberCap: Integer | null
    * ticketPrice: Float | null
    * coveId: String
    * coveName: String
    * coveCoverPhoto: {
      * id: String
      * url: String
    } | null
    * hostId: String
    * hostName: String
    * rsvpStatus: "GOING" | "MAYBE" | "NOT_GOING" | null
    * goingCount: Number
    * createdAt: DateTime
    * coverPhoto: {
      * id: String
      * url: String
    } | null
  }
  * post: { (only present when kind="post")
    * id: String
    * content: String
    * coveId: String
    * coveName: String
    * authorId: String
    * authorName: String
    * authorProfilePhotoUrl: String | null
    * isLiked: Boolean
    * likeCount: Number
    * createdAt: DateTime
  }
}> - Discriminated union of feed items, sorted by rank
* pagination: {
  * hasMore: Boolean
  * nextCursor: String | null
}

Examples:
* `GET /feed?types=event` - Events only
* `GET /feed?types=post`

---

## Event Member Management

### `GET /event-members`

Retrieves paginated list of approved event members (GOING status). User must be authenticated and either be the event host or have GOING status to access this endpoint.

Query Parameters:
* eventId: String (required) - Event ID
* cursor: String (optional) - Pagination cursor
* limit: Integer (optional) - Max items per page (default: 20, max: 50)

Returns:
* members: Array of {
  * id: String - RSVP ID
  * userId: String - User ID
  * userName: String - User name
  * profilePhotoUrl: String | null - Profile photo URL
  * joinedAt: String - ISO 8601 timestamp when approved
}
* hasMore: Boolean - Whether there are more members
* nextCursor: String | null - Cursor for next page

Caching: `Cache-Control: private, no-store`

### `GET /pending-members`

Retrieves paginated list of pending event members (PENDING status) - **HOST ONLY**. User must be authenticated and be the event host.

Query Parameters:
* eventId: String (required) - Event ID
* cursor: String (optional) - Pagination cursor
* limit: Integer (optional) - Max items per page (default: 20, max: 50)

Returns:
* pendingMembers: Array of {
  * id: String - RSVP ID
  * userId: String - User ID
  * userName: String - User name
  * profilePhotoUrl: String | null - Profile photo URL
  * requestedAt: String - ISO 8601 timestamp when RSVP was submitted
}
* hasMore: Boolean - Whether there are more pending members
* nextCursor: String | null - Cursor for next page

Caching: `Cache-Control: private, no-store`

### `POST /approve-decline-rsvp`

Approve or decline a pending RSVP - **HOST ONLY**. User must be authenticated and be the event host.

Takes Data Parameters:
* rsvpId: String (required) - RSVP ID to approve/decline
* action: String (required) - Either "approve" or "decline"

Actions:
* "approve" - Changes RSVP status from PENDING to GOING
* "decline" - Deletes the RSVP record entirely

Returns:
* message: String - Success message
* action: String - The action performed
* rsvpId: String - The RSVP ID

Sends push notification to the user about the decision.

---

## RSVP Status System

The RSVP system uses an approval-based workflow:

### RSVP Statuses:
* **GOING** - User is approved to attend (has full access to event details)
* **PENDING** - User has requested to attend, awaiting host approval (limited access)

### RSVP Flow:
1. User clicks "RSVP" → Status becomes `PENDING`
2. Host sees pending request in special interface
3. Host can "approve" → Status becomes `GOING` (user gains full access)
4. Host can "decline" → RSVP deleted (user loses access)

### Privacy Model:
* **Limited Response** (unauthenticated or non-GOING status): No location, no guest list
* **Full Response** (host OR GOING status): Includes location, guest list, pending counts
* **Host Privileges**: Hosts always get full access to their events (location, guest list, management) regardless of their RSVP status

### Counts:
* `goingCount` - Number of approved attendees (GOING status)  
* `pendingCount` - Number of pending approvals (PENDING status)

### Host Behavior:
* **Event Management**: Hosts can always access `/pending-members`, `/event-members`, and `/approve-decline-rsvp` regardless of their RSVP status
* **Event Details**: Hosts always see location and guest list (full access regardless of RSVP status)
* **RSVP Auto-Approval**: When hosts RSVP to their own events, they are automatically approved to GOING status (no pending approval needed)
* **RSVP Flexibility**: Hosts can RSVP as NOT_GOING and still have full access to manage and view their event

Users with GOING status OR event hosts can see full event details including location and guest lists.