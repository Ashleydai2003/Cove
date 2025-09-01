// Import required modules
import { NextResponse } from 'next/server';
import { notion } from '@/lib/notion';

// This is our API route handler for form submissions
export async function POST(request: Request) {
  try {
    // Get the form data from the request body
    const body = await request.json();
    console.log('API Route - Received form data:', body);
    
    // Check if all required fields are present
    if (!body.firstName || !body.lastName || !body.phoneNumber || !body.city || !body.almaMater) {
      console.log('API Route - Missing required fields');
      return NextResponse.json({ 
        success: false, 
        error: 'Missing required fields' 
      }, { status: 400 });
    }

    // Validate environment variables
    if (!process.env.NOTION_DATABASE_ID) {
      console.error('API Route - NOTION_DATABASE_ID is not set');
      return NextResponse.json({ 
        success: false, 
        error: 'Server configuration error' 
      }, { status: 500 });
    }

    console.log('API Route - Attempting to create Notion page...');
    
    // Create a new page in the Notion database
    const response = await notion.pages.create({
      // Specify which database to add the page to
      parent: {
        database_id: process.env.NOTION_DATABASE_ID,
      },
      // Map form fields to Notion database columns
      properties: {
        // First name as title property
        First: {
          title: [
            {
              text: { content: body.firstName }
            }
          ]
        },
        // Last name as rich text (separate column)
        Last: {
          rich_text: [
            {
              text: { content: body.lastName }
            }
          ]
        },
        // Phone field (phone number type in Notion)
        Phone: {
          phone_number: body.phoneNumber
        },
        // City field (rich text type in Notion)
        City: {
          rich_text: [
            {
              text: {
                content: body.city
              }
            }
          ]
        },
        // Alma Mater field (rich text type in Notion)
        'Alma Mater': {
          rich_text: [
            {
              text: {
                content: body.almaMater
              }
            }
          ]
        },
        // Timestamp field (date type in Notion)
        Timestamp: {
          date: {
            start: new Date().toISOString()
          }
        }
      }
    });

    // Log success and return the response
    console.log('API Route - Notion API response:', response);
    return NextResponse.json({ success: true, data: response });
  } catch (error) {
    // Handle any errors that occur during the process
    console.error('API Route - Detailed Notion API error:', error);
    if (error instanceof Error) {
      console.error('API Route - Error message:', error.message);
      console.error('API Route - Error stack:', error.stack);
    }
    // Return error response to the client
    return NextResponse.json({ 
      success: false, 
      error: error instanceof Error ? error.message : 'Failed to create page',
      details: error instanceof Error ? error.stack : undefined
    }, { status: 500 });
  }
} 