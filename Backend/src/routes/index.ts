// Export all the routes 
export { handleProfile, handleEditProfile } from './profile';
export { handleLogin } from './logIn';
export { handleTestDatabase } from './test-database';
export { handleTestS3 } from './test-s3';
export { handleOnboard } from './onboard';
export { handleUserImage } from './userImage';
export { handleContacts } from './contacts';
export { handleCreateEvent, handleGetCoveEvents, handleGetCalendarEvents } from './event';
export { handleCreateCove, handleGetCove, handleGetCoveMembers } from './cove';
export { handleSendFriendRequest, handleResolveFriendRequest, handleGetFriends, handleGetFriendRequests } from './friend';
export { handleDeleteUser, handleDeleteEvent } from './delete';