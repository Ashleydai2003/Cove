import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

// Geocoding utility function to convert city names to coordinates
async function geocodeCity(city: string): Promise<{latitude: number, longitude: number} | null> {
  try {
    // Use Nominatim (OpenStreetMap) geocoding service - free and no API key required
    const encodedCity = encodeURIComponent(city);
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodedCity}&limit=1&countrycodes=us`;
    
    // Add timeout to prevent hanging requests
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000); // 5 second timeout
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'CoveApp/1.0'  // Required by Nominatim
      },
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      console.error('Geocoding request failed:', response.status, response.statusText);
      return null;
    }
    
    const data = await response.json();
    
    if (Array.isArray(data) && data.length > 0) {
      const result = data[0];
      const lat = parseFloat(result.lat);
      const lon = parseFloat(result.lon);
      
      // Validate parsed coordinates
      if (isNaN(lat) || isNaN(lon)) {
        console.error('Invalid coordinates in geocoding response:', result);
        return null;
      }
      
      return {
        latitude: lat,
        longitude: lon
      };
    }
    
    console.log('No geocoding results found for city:', city);
    return null;
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      console.error('Geocoding request timed out for city:', city);
    } else {
      console.error('Error geocoding city:', city, error);
    }
    return null;
  }
}

// TODO: there should be a default user profile photo that is used if the user does not have a profile photo
export const handleOnboard = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for onboarding.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    // Step 2: Check if auth failed (returns 401 response)
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    // make sure authenticated user is the one that is onboarding
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 5: Check if user is in onboarding state
    const existingUser = await prisma.user.findUnique({
      where: {
        id: user.uid
      },
      select: {
        onboarding: true
      }
    });

    if (!existingUser) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    if (!existingUser.onboarding) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'User has already completed onboarding'
        })
      };
    }

    // Step 6: Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const {
      name,
      birthdate,
      hobbies = [], // Optional: defaults to empty array (archived from iOS onboarding)
      bio,
      latitude,
      longitude,
      city,  // Add city field
      almaMater,
      gradYear,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    } = JSON.parse(event.body);

    // Step 6.5: Validate required fields
    const requiredFields = [];
    if (!name || name.trim() === '') requiredFields.push('name');
    if (!birthdate) requiredFields.push('birthdate');
    if (!almaMater || almaMater.trim() === '') requiredFields.push('almaMater');
    if (!gradYear || gradYear.trim() === '') requiredFields.push('gradYear');

    if (requiredFields.length > 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: `Missing required fields: ${requiredFields.join(', ')}`,
          requiredFields: requiredFields
        })
      };
    }

    // Validate birthdate format
    if (birthdate) {
      const birthdateDate = new Date(birthdate);
      if (isNaN(birthdateDate.getTime())) {
        return {
          statusCode: 400,
          body: JSON.stringify({
            message: 'Invalid birthdate format. Please provide a valid date.'
          })
        };
      }
    }

    // Step 6.5: Handle location data - either direct coordinates or city name
    let finalLatitude = latitude;
    let finalLongitude = longitude;
    let locationProcessingMessage = '';

    // If no direct coordinates provided but city is available, geocode it
    if ((!latitude || !longitude) && city && typeof city === 'string') {
      // Basic validation for city name
      const trimmedCity = city.trim();
      if (trimmedCity.length < 2) {
        console.log('City name too short, skipping geocoding:', city);
        locationProcessingMessage = 'City name too short for geocoding';
      } else if (trimmedCity.length > 100) {
        console.log('City name too long, skipping geocoding:', city);
        locationProcessingMessage = 'City name too long for geocoding';
      } else {
        console.log('Geocoding city:', trimmedCity);
        try {
          const geocodeResult = await geocodeCity(trimmedCity);
          
          if (geocodeResult) {
            // Validate that coordinates are reasonable (not null island, etc.)
            const { latitude: lat, longitude: lon } = geocodeResult;
            
            if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
              finalLatitude = lat;
              finalLongitude = lon;
              console.log('Successfully geocoded coordinates:', { city: trimmedCity, latitude: finalLatitude, longitude: finalLongitude });
              locationProcessingMessage = `Successfully geocoded ${trimmedCity}`;
            } else {
              console.log('Invalid coordinates returned from geocoding:', geocodeResult);
              locationProcessingMessage = 'Invalid coordinates returned from geocoding service';
            }
          } else {
            console.log('No results found for city:', trimmedCity);
            locationProcessingMessage = `No location found for "${trimmedCity}"`;
          }
        } catch (error) {
          console.error('Error during geocoding process:', error);
          locationProcessingMessage = 'Geocoding service temporarily unavailable';
        }
      }
    }

    // Log location processing result
    if (locationProcessingMessage) {
      console.log('Location processing result:', locationProcessingMessage);
    }

    // Validate numeric fields
    if (finalLatitude && typeof finalLatitude !== 'number') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Latitude must be a number' })
      };
    }

    if (finalLongitude && typeof finalLongitude !== 'number') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Longitude must be a number' })
      };
    }

    console.log('Received onboarding data:', {
      name,
      birthdate,
      hobbies,
      bio,
      city,
      latitude: finalLatitude,
      longitude: finalLongitude,
      almaMater,
      gradYear,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    });

    // Step 7: Check if user is an admin based on phone number
    const currentUser = await prisma.user.findUnique({
      where: {
        id: user.uid
      },
      select: {
        phone: true
      }
    });

    if (!currentUser) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    // Check if user's phone number is in admin allowlist
    const adminEntry = await prisma.adminPhoneAllowlist.findUnique({
      where: {
        phoneNumber: currentUser.phone
      }
    });

    const isAdmin = !!adminEntry;

    // Step 8: Update user information
    await prisma.user.update({
      where: {
        id: user.uid
      },
      data: {
        name: name || null,
        onboarding: false, // Mark onboarding as complete
        verified: isAdmin, // Set verified to true if user is an admin
        profile: {
          create: {
            birthdate: birthdate ? new Date(birthdate) : null,
            interests: hobbies, // Already defaults to [] in destructuring
            latitude: finalLatitude || null,
            longitude: finalLongitude || null,
            almaMater: almaMater || null,
            gradYear: gradYear || null,
            job: job || null,
            workLocation: workLocation || null,
            relationStatus: relationStatus || null,
            sexuality: sexuality || null,
            gender: gender || null,
            bio: bio || null
          }
        }
      }
    });

    // Step 9: If user is an admin, update the admin allowlist to mark them as active
    if (isAdmin && adminEntry) {
      await prisma.adminPhoneAllowlist.update({
        where: {
          phoneNumber: currentUser.phone
        },
        data: {
          isActive: true
        }
      });
      console.log('Admin user activated in allowlist:', currentUser.phone);
    }

    console.log('Onboarding complete for user:', user.uid);

    // Step 10: Return success message
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User onboarding completed successfully'
      })
    };
    console.log('Onboarding response:', response);
    return response;
  } catch (error) {
    console.error('Onboarding route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing onboarding request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Onboarding error response:', errorResponse);
    return errorResponse;
  }
};
