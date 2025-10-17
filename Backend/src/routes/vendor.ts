/**
 * Vendor Routes - All vendor-related endpoints
 * Includes authentication, onboarding, profile management, and event creation
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getAuth } from 'firebase-admin/auth';
import { s3Client } from '../config/s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { generateVendorCode, isValidVendorCodeFormat } from '../utils/vendorCode';

// MARK: - Helper Functions

/**
 * Geocode city to lat/long coordinates
 */
async function geocodeCity(city: string): Promise<{latitude: number, longitude: number} | null> {
  try {
    const apiKey = process.env.GEOCODING_API_KEY;
    if (!apiKey) {
      console.error('GEOCODING_API_KEY not set');
      return null;
    }

    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(city)}&key=${apiKey}`;
    const response = await fetch(url);
    const data = await response.json() as any;

    if (data.status === 'OK' && data.results && data.results.length > 0) {
      const location = data.results[0].geometry.location;
      return {
        latitude: location.lat,
        longitude: location.lng
      };
    }

    return null;
  } catch (error) {
    console.error('Geocoding error:', error);
    return null;
  }
}

/**
 * Verify vendor user exists and is authenticated
 */
async function verifyVendorUser(userId: string, prisma: any) {
  const vendorUser = await prisma.vendorUser.findUnique({
    where: { id: userId },
    select: {
      id: true,
      vendorId: true,
      role: true,
      verified: true,
      onboarding: true
    }
  });

  if (!vendorUser) {
    return { error: 'Vendor user not found', statusCode: 404 };
  }

  return { vendorUser };
}

/**
 * Verify vendor user has completed onboarding
 */
function requireOnboardingComplete(vendorUser: any) {
  if (vendorUser.onboarding) {
    return {
      statusCode: 403,
      body: JSON.stringify({ message: 'Please complete vendor onboarding first' })
    };
  }
  return null;
}

/**
 * Verify vendor user is verified
 */
function requireVerified(vendorUser: any) {
  if (!vendorUser.verified) {
    return {
      statusCode: 403,
      body: JSON.stringify({ message: 'Vendor user must be verified' })
    };
  }
  return null;
}

/**
 * Verify vendor user has admin role
 */
function requireAdmin(vendorUser: any) {
  if (vendorUser.role !== 'ADMIN') {
    return {
      statusCode: 403,
      body: JSON.stringify({ message: 'Admin role required' })
    };
  }
  return null;
}

// MARK: - Authentication

/**
 * Vendor Login - POST /vendor/login
 * Authenticates vendor user and creates account if doesn't exist
 */
export const handleVendorLogin = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({ message: 'Method not allowed' })
      };
    }

    // Authenticate with Firebase
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    const user = authResult.user;
    const firebaseUser = await getAuth().getUser(user.uid);
    const verifiedPhoneNumber = firebaseUser.phoneNumber;
    
    if (!verifiedPhoneNumber) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'No verified phone number found' })
      };
    }

    const prisma = await initializeDatabase();

    // Check if vendor user exists
    let dbVendorUser = await prisma.vendorUser.findUnique({
      where: { id: user.uid },
      include: { vendor: true }
    });

    // Create new vendor user if doesn't exist
    if (!dbVendorUser) {
      dbVendorUser = await prisma.vendorUser.create({
        data: {
          id: user.uid,
          phone: verifiedPhoneNumber,
          onboarding: true,
          verified: false,
          vendorId: null // Will be set during onboarding
        },
        include: { vendor: true }
      });

      // Create S3 prefix for vendor images
      try {
        const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
        await s3Client.send(new PutObjectCommand({
          Bucket: bucketName,
          Key: `vendors/${user.uid}/`,
          Body: ''
        }));
      } catch (s3Error) {
        console.error('Error creating S3 prefix:', s3Error);
      }
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Vendor user authenticated successfully',
        vendorUser: {
          uid: dbVendorUser.id,
          onboarding: dbVendorUser.onboarding,
          verified: dbVendorUser.verified,
          vendorId: dbVendorUser.vendorId,
          role: dbVendorUser.role
        }
      })
    };
  } catch (error) {
    console.error('Vendor login error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing vendor login',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// MARK: - Onboarding

/**
 * Validate Vendor Code - POST /vendor/validate-code
 * Check if a vendor code is valid
 */
export const handleValidateVendorCode = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const prisma = await initializeDatabase();

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body required' }) };
    }

    const { code } = JSON.parse(event.body);
    if (!code || typeof code !== 'string') {
      return { statusCode: 400, body: JSON.stringify({ message: 'Vendor code required' }) };
    }

    const normalizedCode = code.trim().toUpperCase();

    if (!isValidVendorCodeFormat(normalizedCode)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          valid: false,
          message: 'Invalid code format. Must be XXXX-XXXX'
        })
      };
    }

    const vendor = await prisma.vendor.findUnique({
      where: { currentCode: normalizedCode }
    });

    if (!vendor) {
      return {
        statusCode: 200,
        body: JSON.stringify({ valid: false, message: 'Invalid vendor code' })
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        valid: true,
        vendorId: vendor.id,
        organizationName: vendor.organizationName
      })
    };
  } catch (error) {
    console.error('Validate code error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error validating code' })
    };
  }
};

/**
 * Create Vendor Organization - POST /vendor/create-organization
 * Create new vendor organization (creator becomes admin)
 */
export const handleCreateVendorOrganization = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body required' }) };
    }

    const { organizationName, website, primaryContactEmail, city, coverPhoto } = JSON.parse(event.body);

    // Validate required fields
    if (!organizationName || !primaryContactEmail || !city) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Organization name, email, and city required' })
      };
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(primaryContactEmail)) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Invalid email format' }) };
    }

    // Geocode city
    let latitude: number | null = null;
    let longitude: number | null = null;
    const trimmedCity = city.trim();
    
    if (trimmedCity.length >= 2 && trimmedCity.length <= 100) {
      const geocodeResult = await geocodeCity(trimmedCity);
      if (geocodeResult) {
        latitude = geocodeResult.latitude;
        longitude = geocodeResult.longitude;
      }
    }

    // Generate unique code
    let vendorCode = generateVendorCode();
    let codeExists = await prisma.vendor.findUnique({ where: { currentCode: vendorCode } });
    while (codeExists) {
      vendorCode = generateVendorCode();
      codeExists = await prisma.vendor.findUnique({ where: { currentCode: vendorCode } });
    }

    // Create vendor organization
    const vendor = await prisma.vendor.create({
      data: {
        organizationName,
        website: website || null,
        primaryContactEmail,
        city: trimmedCity,
        latitude,
        longitude,
        currentCode: vendorCode,
        createdById: user.uid,
        codeRotatedAt: new Date()
      }
    });

    // Handle cover photo upload if provided
    if (coverPhoto) {
      // Create a record for the cover photo in the database
      const vendorImage = await prisma.vendorImage.create({
        data: {
          vendorId: vendor.id
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.VENDOR_COVER_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('VENDOR_COVER_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `vendor-cover/${vendor.id}/${vendorImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update vendor with the cover photo reference
      await prisma.vendor.update({
        where: { id: vendor.id },
        data: { coverPhotoID: vendorImage.id }
      });
    }

    // Link user to vendor as ADMIN
    await prisma.vendorUser.update({
      where: { id: user.uid },
      data: {
        vendorId: vendor.id,
        role: 'ADMIN',
        onboarding: true // Still needs personal info
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Vendor organization created',
        vendor: {
          id: vendor.id,
          organizationName: vendor.organizationName,
          code: vendorCode
        }
      })
    };
  } catch (error) {
    console.error('Create organization error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error creating organization' })
    };
  }
};

/**
 * Join Vendor Organization - POST /vendor/join-organization
 * Join existing organization with code (becomes member)
 */
export const handleJoinVendorOrganization = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body required' }) };
    }

    const { code } = JSON.parse(event.body);
    if (!code) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Code required' }) };
    }

    const normalizedCode = code.trim().toUpperCase();

    if (!isValidVendorCodeFormat(normalizedCode)) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Invalid code format' }) };
    }

    // Find vendor
    const vendor = await prisma.vendor.findUnique({
      where: { currentCode: normalizedCode }
    });

    if (!vendor) {
      return { statusCode: 404, body: JSON.stringify({ message: 'Invalid code' }) };
    }

    // Update user
    await prisma.vendorUser.update({
      where: { id: user.uid },
      data: {
        vendorId: vendor.id,
        role: 'MEMBER',
        onboarding: true
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Joined organization',
        vendor: {
          id: vendor.id,
          organizationName: vendor.organizationName
        }
      })
    };
  } catch (error) {
    console.error('Join organization error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error joining organization' })
    };
  }
};

/**
 * Complete Vendor Onboarding - POST /vendor/onboard
 * Complete onboarding with personal info
 */
export const handleVendorOnboard = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    // Verify user exists
    const existingVendorUser = await prisma.vendorUser.findUnique({
      where: { id: user.uid },
      select: { onboarding: true, vendorId: true }
    });

    if (!existingVendorUser) {
      return { statusCode: 404, body: JSON.stringify({ message: 'Vendor user not found' }) };
    }

    if (!existingVendorUser.onboarding) {
      return { statusCode: 403, body: JSON.stringify({ message: 'Already completed onboarding' }) };
    }

    if (existingVendorUser.vendorId === 'PENDING') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Must join or create organization first' })
      };
    }

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body required' }) };
    }

    const { name, profilePhoto } = JSON.parse(event.body);
    if (!name) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Name required' }) };
    }

    // Complete onboarding
    await prisma.vendorUser.update({
      where: { id: user.uid },
      data: {
        name: name.trim(),
        onboarding: false,
        verified: true
      }
    });

    // Handle profile photo upload if provided
    if (profilePhoto) {
      // Create a record for the profile photo in the database
      const vendorImage = await prisma.vendorImage.create({
        data: {
          vendorUserId: user.uid
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.VENDOR_USER_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('VENDOR_USER_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `vendor-profile/${user.uid}/${vendorImage.id}.jpg`;
      const imageBuffer = Buffer.from(profilePhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update vendor user with the profile photo reference
      await prisma.vendorUser.update({
        where: { id: user.uid },
        data: { profilePhotoID: vendorImage.id }
      });
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Onboarding completed' })
    };
  } catch (error) {
    console.error('Onboarding error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error completing onboarding' })
    };
  }
};

// MARK: - Profile Management

/**
 * Get Vendor Profile - GET /vendor/profile
 * Get current vendor user profile
 */
export const handleGetVendorProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'GET') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    const vendorUser = await prisma.vendorUser.findUnique({
      where: { id: user.uid },
      include: {
        vendor: true,
        profilePhoto: true
      }
    });

    if (!vendorUser) {
      return { statusCode: 404, body: JSON.stringify({ message: 'Vendor user not found' }) };
    }

    // Only show code to admins
    const showCode = vendorUser.role === 'ADMIN';

    return {
      statusCode: 200,
      body: JSON.stringify({
        vendorUser: {
          id: vendorUser.id,
          name: vendorUser.name,
          phone: vendorUser.phone,
          role: vendorUser.role,
          vendorId: vendorUser.vendorId,
          profilePhotoID: vendorUser.profilePhotoID,
          vendor: vendorUser.vendor ? {
            id: vendorUser.vendor.id,
            organizationName: vendorUser.vendor.organizationName,
            website: vendorUser.vendor.website,
            primaryContactEmail: vendorUser.vendor.primaryContactEmail,
            city: vendorUser.vendor.city,
            currentCode: showCode ? vendorUser.vendor.currentCode : undefined,
            codeRotatedAt: vendorUser.vendor.codeRotatedAt,
            coverPhotoID: vendorUser.vendor.coverPhotoID
          } : null
        }
      })
    };
  } catch (error) {
    console.error('Get profile error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error fetching profile' })
    };
  }
};

/**
 * Rotate Vendor Code - POST /vendor/rotate-code
 * Rotate organization code (ADMIN only)
 */
export const handleRotateVendorCode = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    // Verify user and require admin
    const verifyResult = await verifyVendorUser(user.uid, prisma);
    if (verifyResult.error) {
      return { statusCode: verifyResult.statusCode, body: JSON.stringify({ message: verifyResult.error }) };
    }

    const adminCheck = requireAdmin(verifyResult.vendorUser);
    if (adminCheck) return adminCheck;

    // Generate new code
    let newCode = generateVendorCode();
    let codeExists = await prisma.vendor.findUnique({ where: { currentCode: newCode } });
    while (codeExists) {
      newCode = generateVendorCode();
      codeExists = await prisma.vendor.findUnique({ where: { currentCode: newCode } });
    }

    // Update vendor
    const updatedVendor = await prisma.vendor.update({
      where: { id: verifyResult.vendorUser.vendorId },
      data: {
        currentCode: newCode,
        codeRotatedAt: new Date()
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Code rotated',
        newCode: updatedVendor.currentCode,
        codeRotatedAt: updatedVendor.codeRotatedAt
      })
    };
  } catch (error) {
    console.error('Rotate code error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error rotating code' })
    };
  }
};

/**
 * Get Vendor Members - GET /vendor/members
 * Get all organization members (ADMIN only)
 */
export const handleGetVendorMembers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'GET') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    // Verify user and require admin
    const verifyResult = await verifyVendorUser(user.uid, prisma);
    if (verifyResult.error) {
      return { statusCode: verifyResult.statusCode, body: JSON.stringify({ message: verifyResult.error }) };
    }

    const adminCheck = requireAdmin(verifyResult.vendorUser);
    if (adminCheck) return adminCheck;

    // Get members
    const members = await prisma.vendorUser.findMany({
      where: { vendorId: verifyResult.vendorUser.vendorId },
      include: { profilePhoto: true },
      orderBy: [
        { role: 'desc' },
        { createdAt: 'asc' }
      ]
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        members: members.map(m => ({
          id: m.id,
          name: m.name,
          phone: m.phone,
          role: m.role,
          profilePhotoID: m.profilePhotoID,
          createdAt: m.createdAt
        }))
      })
    };
  } catch (error) {
    console.error('Get members error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error fetching members' })
    };
  }
};

// MARK: - Event Creation

/**
 * Create Vendor Event - POST /vendor/create-event
 * Create event that appears in all user feeds
 */
export const handleCreateVendorEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    // Verify user
    const verifyResult = await verifyVendorUser(user.uid, prisma);
    if (verifyResult.error) {
      return { statusCode: verifyResult.statusCode, body: JSON.stringify({ message: verifyResult.error }) };
    }

    // Require onboarding complete and verified
    const onboardingCheck = requireOnboardingComplete(verifyResult.vendorUser);
    if (onboardingCheck) return onboardingCheck;

    const verifiedCheck = requireVerified(verifyResult.vendorUser);
    if (verifiedCheck) return verifiedCheck;

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body required' }) };
    }

    const {
      name, description, date, location, memberCap,
      ticketPrice, paymentHandle, coverPhoto,
      useTieredPricing, pricingTiers
    } = JSON.parse(event.body);

    // Validate required
    if (!name || !date || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Name, date, and location required' })
      };
    }

    // Create event - MUST have vendor, NOT have cove
    const newEvent = await prisma.$transaction(async (tx: any) => {
      // Validate: vendor events must NOT have coveId
      if (!verifyResult.vendorUser.vendorId) {
        throw new Error('Vendor ID required for vendor events');
      }

      const evt = await tx.event.create({
        data: {
          name,
          description: description || null,
          date: new Date(date),
          location,
          memberCap: memberCap || null,
          ticketPrice: ticketPrice || null,
          paymentHandle: paymentHandle || null,
          isPublic: true, // Always public
          useTieredPricing: useTieredPricing === true,
          vendorId: verifyResult.vendorUser.vendorId,
          hostId: null,
          coveId: null // Vendor events have no cove
        }
      });

      // Tiered pricing
      if (useTieredPricing && pricingTiers?.length > 0) {
        await tx.eventPricingTier.createMany({
          data: pricingTiers.map((tier: any, idx: number) => ({
            eventId: evt.id,
            tierType: tier.tierType,
            price: tier.price,
            maxSpots: tier.maxSpots || null,
            sortOrder: idx
          }))
        });
      }

      return evt;
    });

    // Upload cover photo if provided
    let uploadedImageId: string | null = null;
    if (coverPhoto && typeof coverPhoto === 'string') {
      try {
        const matches = coverPhoto.match(/^data:([A-Za-z-+/]+);base64,(.+)$/);
        if (matches && matches.length === 3) {
          const contentType = matches[1];
          const imageData = matches[2];
          const buffer = Buffer.from(imageData, 'base64');
          const imageId = `vendor-event-${newEvent.id}-${Date.now()}`;
          const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME || process.env.USER_IMAGE_BUCKET_NAME;

          await s3Client.send(new PutObjectCommand({
            Bucket: bucketName,
            Key: `vendor-events/${imageId}`,
            Body: buffer,
            ContentType: contentType
          }));

          const eventImage = await prisma.eventImage.create({
            data: { id: imageId, eventId: newEvent.id }
          });

          uploadedImageId = eventImage.id;

          await prisma.event.update({
            where: { id: newEvent.id },
            data: { coverPhotoID: uploadedImageId }
          });
        }
      } catch (uploadError) {
        console.error('Cover photo upload error:', uploadError);
      }
    }

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Event created',
        event: {
          id: newEvent.id,
          name: newEvent.name,
          date: newEvent.date,
          location: newEvent.location,
          isPublic: newEvent.isPublic,
          vendorId: newEvent.vendorId,
          coverPhotoID: uploadedImageId
        }
      })
    };
  } catch (error) {
    console.error('Create event error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error creating event' })
    };
  }
};

/**
 * Get vendor events
 * GET /vendor/events
 * Returns all events created by the vendor's organization
 */
export const handleGetVendorEvents = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'GET') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed' }) };
    }

    // Authenticate
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    const user = authResult.user;
    const prisma = await initializeDatabase();

    // Verify user
    const verifyResult = await verifyVendorUser(user.uid, prisma);
    if (verifyResult.error) {
      return { statusCode: verifyResult.statusCode, body: JSON.stringify({ message: verifyResult.error }) };
    }

    if (!verifyResult.vendorUser.vendorId) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Vendor ID required' }) };
    }

    // Fetch all events for this vendor
    const events = await prisma.event.findMany({
      where: {
        vendorId: verifyResult.vendorUser.vendorId
      },
      include: {
        coverPhoto: {
          select: {
            id: true
          }
        },
        vendor: {
          select: {
            id: true,
            organizationName: true
          }
        },
        pricingTiers: {
          orderBy: {
            sortOrder: 'asc'
          }
        },
        rsvps: {
          select: {
            id: true,
            status: true
          }
        }
      },
      orderBy: {
        date: 'asc'
      }
    });

    // Format events for response
    const bucketUrl = process.env.EVENT_IMAGE_BUCKET_URL;
    if (!bucketUrl) {
      throw new Error('EVENT_IMAGE_BUCKET_URL environment variable is not set');
    }

    const formattedEvents = events.map(ev => {
      const coverPhotoUrl = ev.coverPhoto
        ? `${bucketUrl}/vendor-events/${ev.coverPhoto.id}`
        : null;

      const rsvpCounts = {
        going: ev.rsvps.filter((r: any) => r.status === 'GOING').length,
        maybe: ev.rsvps.filter((r: any) => r.status === 'MAYBE').length,
        cantGo: ev.rsvps.filter((r: any) => r.status === 'CANT_GO').length
      };

      return {
        id: ev.id,
        name: ev.name,
        description: ev.description,
        date: ev.date,
        location: ev.location,
        memberCap: ev.memberCap,
        ticketPrice: ev.ticketPrice,
        paymentHandle: ev.paymentHandle,
        isPublic: ev.isPublic,
        vendorId: ev.vendorId,
        vendorName: ev.vendor?.organizationName || null,
        coverPhotoUrl,
        useTieredPricing: ev.useTieredPricing,
        pricingTiers: ev.pricingTiers?.map((tier: any) => ({
          tierType: tier.tierType,
          price: tier.price,
          maxSpots: tier.maxSpots,
          sortOrder: tier.sortOrder
        })) || [],
        rsvpCounts,
        createdAt: ev.createdAt
      };
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        events: formattedEvents
      })
    };
  } catch (error) {
    console.error('Get vendor events error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error fetching vendor events' })
    };
  }
};

// MARK: - Vendor Image Upload

/**
 * Upload a vendor profile image
 * POST /vendor/image
 * Body: { data: base64Image, isProfilePic: boolean }
 */
export const handleVendorImageUpload = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for image uploads.'
        })
      };
    }

    // Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    const userId = authResult.user.uid;
    console.log('Vendor image upload for user:', userId);

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { data: base64Image, isProfilePic } = JSON.parse(event.body);

    if (!base64Image) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Image data is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Verify this is a vendor user
    const vendorUser = await verifyVendorUser(userId, prisma);
    if (!vendorUser) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'User is not a vendor'
        })
      };
    }

    // Create VendorImage record first to get the auto-generated ID
    const vendorImage = await prisma.vendorImage.create({
      data: {
        vendorUserId: userId
      }
    });

    const bucketName = process.env.VENDOR_USER_IMAGE_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('VENDOR_USER_IMAGE_BUCKET_NAME environment variable is not set');
    }

    const s3Key = `vendor-profile/${userId}/${vendorImage.id}.jpg`;

    // Convert base64 to buffer
    const imageBuffer = Buffer.from(base64Image, 'base64');

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: s3Key,
      Body: imageBuffer,
      ContentType: 'image/jpeg'
    });
    await s3Client.send(command);

    // If this is a profile picture, update the vendor user's profilePhotoID
    if (isProfilePic) {
      await prisma.vendorUser.update({
        where: {
          id: userId
        },
        data: {
          profilePhotoID: vendorImage.id
        }
      });
    }

    console.log('Vendor image upload complete for user:', userId);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image uploaded successfully',
        imageId: vendorImage.id
      })
    };
  } catch (error) {
    console.error('Vendor image upload error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing image upload request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Update an existing vendor image
 * POST /vendor/image/update
 * Body: { data: base64Image, photoId: string }
 */
export const handleVendorImageUpdate = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for image updates.'
        })
      };
    }

    // Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    const userId = authResult.user.uid;
    console.log('Vendor image update for user:', userId);

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { data: base64Image, photoId } = JSON.parse(event.body);

    if (!base64Image) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Image data is required'
        })
      };
    }

    if (!photoId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Photo ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Verify this is a vendor user
    const vendorUser = await verifyVendorUser(userId, prisma);
    if (!vendorUser) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'User is not a vendor'
        })
      };
    }

    // Find the existing photo and verify ownership
    const existingPhoto = await prisma.vendorImage.findFirst({
      where: {
        id: photoId,
        vendorUserId: userId
      }
    });

    if (!existingPhoto) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Photo not found or you do not have permission to update it'
        })
      };
    }

    // Delete old image from S3
    const bucketName = process.env.VENDOR_USER_IMAGE_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('VENDOR_USER_IMAGE_BUCKET_NAME environment variable is not set');
    }

    const s3Key = `vendor-profile/${userId}/${photoId}.jpg`;
    const deleteCommand = new DeleteObjectCommand({
      Bucket: bucketName,
      Key: s3Key
    });
    
    try {
      await s3Client.send(deleteCommand);
      console.log('Old vendor image deleted from S3:', s3Key);
    } catch (error) {
      console.log('Old vendor image not found in S3, continuing with upload:', s3Key);
    }

    // Upload new image to S3
    const imageBuffer = Buffer.from(base64Image, 'base64');
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: s3Key,
      Body: imageBuffer,
      ContentType: 'image/jpeg'
    });
    await s3Client.send(command);

    console.log('Vendor image update complete for user:', userId, 'photoId:', photoId);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image updated successfully'
      })
    };
  } catch (error) {
    console.error('Vendor image update error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing image update request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

