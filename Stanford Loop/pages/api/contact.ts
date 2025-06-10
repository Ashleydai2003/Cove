import type { NextApiRequest, NextApiResponse } from 'next';

interface ContactResponse {
  fullName: string;
  contactMethod: string;
  linkedinUrl?: string;
  phoneNumber?: string;
  stanfordEmail?: string;
  instagramHandle?: string;
}

interface TypeformAnswer {
  type: string;
  text?: string;
  choice?: {
    label: string;
  };
  url?: string;
  phone_number?: string;
  email?: string;
  field: {
    id: string;
    ref: string;
  };
}

interface WebhookPayload {
  event_id: string;
  event_type: string;
  form_response: {
    form_id: string;
    token: string;
    answers: TypeformAnswer[];
  };
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === 'GET') {
    try {
      const response = await fetch(
        `https://api.typeform.com/forms/${process.env.TYPEFORM_CONTACT_FORM_ID}/responses`,
        {
          headers: {
            Authorization: `Bearer ${process.env.TYPEFORM_API}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to fetch responses from Typeform');
      }

      const data = await response.json();
      
      // Map the responses to our ContactResponse interface
      const contactResponses: ContactResponse[] = data.items.map((item: any) => {
        const answers = item.answers.reduce((acc: any, answer: TypeformAnswer) => {
          switch (answer.field.id) {
            case 'fAGZCjV72LGX': // Full Name
              acc.fullName = answer.text;
              break;
            case 'NWHDOTIj3rPc': // Contact Method
              acc.contactMethod = answer.choice?.label;
              break;
            case '9vizIJPp50Oz': // LinkedIn URL
              acc.linkedinUrl = answer.url;
              break;
            case 'tpwONkpP7Tz9': // Phone Number
              acc.phoneNumber = answer.phone_number;
              break;
            case 'dbBnStrLZHwR': // Stanford Email
              acc.stanfordEmail = answer.email;
              break;
            case '1UMf07Z0B8iK': // Instagram Handle
              acc.instagramHandle = answer.text;
              break;
          }
          return acc;
        }, {});

        // Only return responses that have at least a name and one contact method
        if (answers.fullName && (
          answers.phoneNumber || 
          answers.stanfordEmail || 
          answers.linkedinUrl || 
          answers.instagramHandle
        )) {
          return answers;
        }
        return null;
      }).filter(Boolean); // Remove null entries

      res.status(200).json({ responses: contactResponses });
    } catch (error) {
      console.error('Error fetching contact form responses:', error);
      res.status(500).json({ error: 'Failed to fetch contact form responses' });
    }
  } else if (req.method === 'POST') {
    try {
      const payload = req.body as WebhookPayload;
      
      // Process the webhook payload
      const contactInfo = payload.form_response.answers.reduce((acc: any, answer: TypeformAnswer) => {
        switch (answer.field.id) {
          case 'fAGZCjV72LGX': // Full Name
            acc.fullName = answer.text;
            break;
          case 'NWHDOTIj3rPc': // Contact Method
            acc.contactMethod = answer.choice?.label;
            break;
          case '9vizIJPp50Oz': // LinkedIn URL
            acc.linkedinUrl = answer.url;
            break;
          case 'tpwONkpP7Tz9': // Phone Number
            acc.phoneNumber = answer.phone_number;
            break;
          case 'dbBnStrLZHwR': // Stanford Email
            acc.stanfordEmail = answer.email;
            break;
          case '1UMf07Z0B8iK': // Instagram Handle
            acc.instagramHandle = answer.text;
            break;
        }
        return acc;
      }, {});

      // Here you can add logic to store the contact info in your database
      console.log('Received contact info:', contactInfo);

      res.status(200).json({ success: true, data: contactInfo });
    } catch (error) {
      console.error('Error processing webhook:', error);
      res.status(500).json({ error: 'Failed to process webhook' });
    }
  } else {
    res.setHeader('Allow', ['GET', 'POST']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
