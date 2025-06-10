// create webook
// get response from typeform
// use webhook to get a response (may need to pay)
// setup notion API to create a new database page

import { NextApiRequest, NextApiResponse } from "next";
import { Client } from "@notionhq/client";

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
    // Comment out PUT request for now
    /*
    if (req.method === "PUT") {
        console.log('Environment variables:', {
            formId: process.env.TYPEFORM_FORM_ID,
            webhookUrl: process.env.TYPEFORM_WEBHOOK_URL,
            apiKey: process.env.TYPEFORM_API ? 'exists' : 'missing'
        });

        const { TYPEFORM_FORM_ID, TYPEFORM_WEBHOOK_URL, TYPEFORM_API } = process.env;

        if (!TYPEFORM_FORM_ID || !TYPEFORM_WEBHOOK_URL || !TYPEFORM_API) {
            return res.status(500).json({ message: 'Missing environment variables' });
        }

        try {
            const response = await fetch(
                `https://api.typeform.com/forms/${TYPEFORM_FORM_ID}/webhooks/webhook`,
                {
                    method: "PUT",
                    headers: {
                        "Authorization": `Bearer ${TYPEFORM_API}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({ url: TYPEFORM_WEBHOOK_URL, enabled: true })
                }
            );

            if (!response.ok) {
                throw new Error(`Typeform API error: ${await response.text()}`);
            }
            return res.status(200).json(await response.json());
        } catch (error) {
            console.error('Error creating webhook:', error);
            return res.status(500).json({ 
                message: 'Error creating webhook',
                error: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    */

    // Handle GET request to fetch all form responses
    if (req.method === "GET") {
        const { TYPEFORM_FORM_ID, TYPEFORM_API } = process.env;

        if (!TYPEFORM_FORM_ID || !TYPEFORM_API) {
            return res.status(500).json({ message: 'Missing environment variables' });
        }

        try {
            // Fetch all responses from Typeform
            const response = await fetch(
                `https://api.typeform.com/forms/${TYPEFORM_FORM_ID}/responses?page_size=1000`,
                {
                    headers: {
                        "Authorization": `Bearer ${TYPEFORM_API}`,
                        "Content-Type": "application/json",
                    }
                }
            );

            if (!response.ok) {
                throw new Error(`Typeform API error: ${await response.text()}`);
            }

            const data = await response.json();
            console.log(`Found ${data.items.length} responses`);

            // Process each response
            const processedResponses = data.items.map((item: any) => {
                try {
                    const formSubmission = getFormSubmission({ form_response: item });
                    return {
                        response_id: item.response_id,
                        submitted_at: item.submitted_at,
                        ...formSubmission
                    };
                } catch (error) {
                    console.error(`Error processing response ${item.response_id}:`, error);
                    return {
                        response_id: item.response_id,
                        error: error instanceof Error ? error.message : 'Unknown error'
                    };
                }
            });

            return res.status(200).json({
                message: 'Successfully fetched and processed responses',
                total_responses: data.items.length,
                responses: processedResponses
            });
        } catch (error) {
            console.error('Error fetching Typeform responses:', error);
            return res.status(500).json({ 
                message: 'Error fetching Typeform responses',
                error: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }
    
    // Handle POST request for form submissions
    if (req.method === "POST") {
        try {
            const formSubmission = getFormSubmission(req.body);
            await processFormSubmission(formSubmission);
            return res.status(200).json({ message: 'Form submission processed successfully' });
        } catch (error) {
            console.error('Error processing form submission:', error);
            return res.status(500).json({ 
                message: 'Error processing form submission',
                error: error instanceof Error ? error.message : 'Unknown error'
            });
        }
    }

    // If method is neither GET nor POST
    return res.status(405).json({ message: "Method not allowed" });
}

export interface FormSubmission {
    firstName: string;
    lastName: string;
    currentAffiliation: string;
    phoneNumber: string;
    city: string;
    otherCity: string | null;
    duration: string;
    roommates: boolean;
    waitlistInterest: boolean;
    friendEmails: string[];
}

export function getFormSubmission(payload: any): FormSubmission {
    // Validate that this is a legitimate Typeform submission
    if (!payload.form_response || !payload.form_response.answers) {
        throw new Error('Invalid form submission format');
    }

    const answers = payload.form_response.answers;
    const formData: any = {};

    // Validate that we have the expected number of answers
    if (answers.length < 5) { // Minimum required fields
        throw new Error('Incomplete form submission');
    }

    answers.forEach((answer: any) => {
        const fieldId = answer.field.id;
        let value;

        switch (answer.type) {
            case 'text': value = answer.text; break;
            case 'phone_number': value = answer.phone_number; break;
            case 'choice': value = answer.choice.label; break;
            case 'choices': value = answer.choices.labels; break;
            case 'boolean': value = answer.boolean; break;
            default: throw new Error(`Invalid answer type: ${answer.type}`);
        }

        formData[fieldId] = value;
    });

    // Validate required fields
    const submission = {
        firstName: formData['MEGys69wiBhi'] || '',
        lastName: formData['GNCi1XAhRQvR'] || '',
        currentAffiliation: formData['GFw2tipEzc0O'] || '',
        phoneNumber: formData['5CE3giUnffMe'] || '',
        city: formData['9ScYiTXOawbz'] || '',
        otherCity: formData['ZJmOLPPNPQvN'] || null,
        duration: formData['UXRVjcbY6ftC'] || '',
        roommates: formData['MOY2eASoCeWu'] || false,
        waitlistInterest: formData['rbgCT6LAYaqB'] === 'Sign me up!',
        friendEmails: [
            formData['PPZzuEyddZNA'],
            formData['CdLVEnXQDx3I'],
            formData['wO0BJ0b1hkWJ'],
            formData['Yze1Owg2E2rM'],
            formData['AuHRv108LaXi']
        ].filter(Boolean)
    };

    // Validate required fields
    if (!submission.firstName || !submission.lastName || !submission.currentAffiliation || 
        !submission.phoneNumber || !submission.city || !submission.duration) {
        throw new Error('Missing required fields');
    }

    // Validate name lengths
    if (submission.firstName.length > 50 || submission.lastName.length > 50) {
        throw new Error('Name too long');
    }

    // Validate phone number format
    if (!isValidPhoneNumber(submission.phoneNumber)) {
        throw new Error('Invalid phone number format');
    }

    // Validate email formats if provided
    submission.friendEmails.forEach(email => {
        if (email && !isValidEmail(email)) {
            throw new Error('Invalid email format');
        }
    });

    return submission;
}

// Add email validation function
function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Initialize Notion client
const notion = new Client({
    auth: process.env.NOTION_API,
});

function capitalize(str: string) {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

function isValidPhoneNumber(phone: string): boolean {
    // Simple validation: must be digits, may start with +, and be 10-15 digits long
    return /^\+?\d{10,15}$/.test(phone);
}

function isValidUrl(url: string): boolean {
    try {
        new URL(url);
        return true;
    } catch {
        return false;
    }
}

async function processFormSubmission(submission: FormSubmission) {
    // Data processing
    const firstName = capitalize(submission.firstName.trim());
    const lastName = capitalize(submission.lastName.trim());
    let city = submission.city === "Other" ? (submission.otherCity || "") : submission.city;
    city = capitalize(city.trim());
    const phoneNumber = submission.phoneNumber.trim();
    if (!isValidPhoneNumber(phoneNumber)) {
        throw new Error("Invalid phone number format");
    }

    // Use Stanford logo as default cover photo
    const coverPhoto = {
        type: "external" as const,
        external: {
            url: "https://cdn.freebiesupply.com/images/large/2x/stanford-logo-transparent.png"
        }
    };

    try {
        // Create a new page in the Notion database
        const response = await notion.pages.create({
            parent: {
                database_id: process.env.NOTION_DATABASE!,
            },
            cover: coverPhoto,
            properties: {
                // Name (title)
                "Name": {
                    title: [
                        {
                            text: {
                                content: `${firstName} ${lastName}`,
                            },
                        },
                    ],
                },
                // Duration (select)
                "Duration": {
                    select: {
                        name: submission.duration,
                    },
                },
                // Class (Select)
                "Class": {
                    select: {
                        name: submission.currentAffiliation,
                    },
                },
                // Phone Number (phone number)
                "Phone Number": {
                    phone_number: phoneNumber,
                },
                // Looking for roommates (select)
                "Looking for roommates": {
                    select: {
                        name: submission.roommates ? "Yes" : "No",
                    },
                },
                // City (select)
                "City": {
                    select: {
                        name: city,
                    },
                },
            },
        });

        return response;
    } catch (error) {
        console.error('Error creating Notion page:', error);
        throw error;
    }
}