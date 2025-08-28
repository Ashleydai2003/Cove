import { Client } from '@notionhq/client';

// Initialize Notion client with API key from environment variables
const notion = new Client({
  auth: process.env.NOTION_API_KEY,
});

export { notion }; 