// Export all the routes 
export { handleProfile, handleEditProfile } from './profile';
export { handleLogin } from './logIn';
export { handleAuthValidate } from './auth';
export { handleTestDatabase } from './test-database';
export { handleTestS3 } from './test-s3';
export { handleOnboard } from './onboard';
export { handleUserImage, handleUserImageUpdate } from './userImage';
export { handleContacts } from './contacts';
export { handleCreateEvent, handleGetCoveEvents, handleGetCalendarEvents, handleGetEvent, handleUpdateEventRSVP, handleRemoveEventRSVP, handleGetEventMembers, handleGetPendingMembers, handleApproveDeclineRSVP } from './event';
export { handleCreateCove, handleGetCove, handleGetCoveMembers, handleGetUserCoves, handleJoinCove } from './cove';
export { handleSendFriendRequest, handleResolveFriendRequest, handleGetFriends, handleGetFriendRequests, handleGetRecommendedFriends } from './friend';
export { handleDeleteUser, handleDeleteEvent, handleDeleteCove } from './delete';
export { handleSendInvite, handleGetInvites, handleOpenInvite, handleRejectInvite } from './invites';
export { handleCreateThread, handleSendMessage, handleGetThreads, handleGetThreadMessages, handleMarkMessageRead, handleUpdateFCMToken } from './messaging';
export { handleCreatePost, handleGetCovePosts, handleGetPost, handleTogglePostLike } from './post';
export { handleGetFeed } from './feed';
export { handleGetUniversities } from './universities';