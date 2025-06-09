import type { NextApiRequest, NextApiResponse } from 'next';

interface DirectoryResponse {
  entries: Array<{
    response_id: string;
    submitted_at: string;
    firstName: string;
    lastName: string;
    currentAffiliation: string;
    city: string;
    otherCity: string | null;
    duration: string;
    roommates: boolean;
    waitlistInterest: boolean;
    friendEmails: string[];
    class: string;
  }>;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<DirectoryResponse>
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ entries: [] });
  }

  try {
    const formId = process.env.TYPEFORM_DIRECTORY_FORM_ID;
    const token = process.env.TYPEFORM_API;

    if (!formId || !token) {
      return res.status(500).json({ entries: [] });
    }

    let allEntries: any[] = [];
    let pageSize = 100;
    let page = 1;
    let hasMore = true;

    while (hasMore) {
      const response = await fetch(
        `https://api.typeform.com/forms/${formId}/responses?page_size=${pageSize}&page=${page}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to fetch responses from Typeform');
      }

      const data = await response.json();
      const entries = data.items.map((item: any) => {
        const answers = item.answers.reduce((acc: any, answer: any) => {
          if (answer.type === 'text') {
            acc[answer.field.id] = answer.text;
          } else if (answer.type === 'choice') {
            acc[answer.field.id] = answer.choice.label;
          } else if (answer.type === 'boolean') {
            acc[answer.field.id] = answer.boolean;
          } else if (answer.type === 'phone_number') {
            acc[answer.field.id] = answer.phone_number;
          }
          return acc;
        }, {});

        return {
          response_id: item.response_id,
          submitted_at: item.submitted_at,
          firstName: answers['MEGys69wiBhi'] || '',
          lastName: answers['GNCi1XAhRQvR'] || '',
          currentAffiliation: answers['GFw2tipEzc0O'] || '',
          city: answers['9ScYiTXOawbz'] || '',
          otherCity: null,
          duration: answers['UXRVjcbY6ftC'] || '',
          roommates: answers['MOY2eASoCeWu'] || false,
          waitlistInterest: answers['rbgCT6LAYaqB'] === 'Sign me up!',
          friendEmails: [],
          class: answers['GFw2tipEzc0O'] || ''
        };
      });

      allEntries = [...allEntries, ...entries];
      
      // Check if we have more pages
      hasMore = data.items.length === pageSize;
      page++;
    }

    res.status(200).json({ entries: allEntries });
  } catch (error) {
    console.error('Error fetching directory data:', error);
    res.status(500).json({ entries: [] });
  }
} 