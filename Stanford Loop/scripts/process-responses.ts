const nodeFetch = require('node-fetch');
const dotenv = require('dotenv');

// Load environment variables from .env.local
dotenv.config({ path: '.env.local' });

const TYPEFORM_API = process.env.TYPEFORM_API;
const TYPEFORM_FORM_ID = process.env.TYPEFORM_FORM_ID;
const API_URL = process.env.API_URL || 'https://stanfordloop.vercel.app/api/submit';

async function getTypeformResponses() {
    try {
        const response = await nodeFetch(
            `https://api.typeform.com/forms/${TYPEFORM_FORM_ID}/responses?page_size=1000`,
            {
                headers: {
                    'Authorization': `Bearer ${TYPEFORM_API}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        if (!response.ok) {
            throw new Error(`Typeform API error: ${await response.text()}`);
        }

        const data = await response.json();
        console.log(`Found ${data.items.length} responses`);
        return data.items;
    } catch (error) {
        console.error('Error fetching Typeform responses:', error);
        throw error;
    }
}

async function processResponse(response: any) {
    try {
        const apiResponse = await nodeFetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ form_response: response })
        });

        if (!apiResponse.ok) {
            throw new Error(`API error: ${await apiResponse.text()}`);
        }

        console.log(`Successfully processed response ${response.response_id}`);
    } catch (error) {
        console.error(`Error processing response ${response.response_id}:`, error);
    }
}

async function main() {
    try {
        console.log('Fetching Typeform responses...');
        const responses = await getTypeformResponses();
        
        console.log('Processing responses...');
        for (const response of responses) {
            await processResponse(response);
            // Add a small delay to avoid rate limiting
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        console.log('All responses processed!');
    } catch (error) {
        console.error('Error in main process:', error);
    }
}

main(); 