# Test Events Organization

This directory contains test files organized by feature/domain for the Cove API.

## Directory Structure

### `/posts/`
Test files for post-related endpoints:
- `create-post.json` - Tests for creating new posts
- `cove-posts.json` - Tests for retrieving posts from a specific cove
- `toggle-post-like.json` - Tests for liking/unliking posts
- `feed.json` - Tests for retrieving feed posts (all posts from user's coves)

### `/events/`
Test files for event-related endpoints:
- `create-event.json` - Tests for creating new events
- `get-event.json` - Tests for retrieving specific event details
- `get-cove-events.json` - Tests for retrieving events from a specific cove
- `get-cove-events-max-limit.json` - Tests for pagination limits
- `get-cove-events-pagination.json` - Tests for pagination functionality
- `get-upcoming-events.json` - Tests for retrieving upcoming events
- `get-upcoming-events-max-limit.json` - Tests for pagination limits
- `get-upcoming-events-pagination.json` - Tests for pagination functionality
- `get-calendar-events.json` - Tests for calendar view events
- `update-event-rsvp.json` - Tests for RSVP functionality
- `delete-event.json` - Tests for deleting events

### `/coves/`
Test files for cove-related endpoints:
- `create-cove.json` - Tests for creating new coves
- `get-cove.json` - Tests for retrieving cove details
- `get-cove-error.json` - Tests for error scenarios
- `get-cove-members.json` - Tests for retrieving cove members
- `get-cove-members-max-limit.json` - Tests for pagination limits
- `get-cove-members-error.json` - Tests for error scenarios
- `get-user-coves.json` - Tests for retrieving user's coves
- `join-cove.json` - Tests for joining coves

### `/users/`
Test files for user-related endpoints:
- `login.json` - Tests for user authentication
- `profile.json` - Tests for retrieving user profiles
- `edit-profile.json` - Tests for editing user profiles
- `edit-profile-partial.json` - Tests for partial profile updates
- `userImage.json` - Tests for user image uploads
- `delete-user.json` - Tests for user deletion
- `contacts.json` - Tests for contact functionality

### `/friends/`
Test files for friend-related endpoints:
- `send-friend-request.json` - Tests for sending friend requests
- `get-friends.json` - Tests for retrieving friends list
- `get-friends-max-limit.json` - Tests for pagination limits
- `get-friend-requests.json` - Tests for retrieving friend requests
- `get-friend-requests-max-limit.json` - Tests for pagination limits
- `reject-friend-request.json` - Tests for rejecting friend requests

### `/messaging/`
Test files for messaging endpoints:
- `create-thread.json` - Tests for creating message threads
- `send-message.json` - Tests for sending messages
- `get-threads.json` - Tests for retrieving threads
- `get-thread-messages.json` - Tests for retrieving thread messages
- `mark-message-read.json` - Tests for marking messages as read
- `update-fcm-token.json` - Tests for updating FCM tokens

### `/invites/`
Test files for invite-related endpoints:
- `send-invite.json` - Tests for sending cove invites
- `send-invite-errors.json` - Tests for invite error scenarios
- `get-invites.json` - Tests for retrieving invites
- `get-invites-scenarios.json` - Tests for various invite scenarios
- `invites-auth-errors.json` - Tests for authentication errors

### Root Directory
- `test-s3.json` - Tests for S3 functionality

## Usage

Each test file contains an array of test scenarios with:
- Test name and description
- HTTP method and path
- Headers (including authentication)
- Request body (for POST/PUT requests)
- Expected status code
- Expected response structure

## Running Tests

Tests can be run using the test runner script or manually by sending requests to the API endpoints with the test data. 