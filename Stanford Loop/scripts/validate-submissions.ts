const { getFormSubmission } = require('../pages/api/submit');

// Sample response data from your API
const responseData = {
    message: 'Successfully fetched and processed responses',
    total_responses: 13,
    responses: [
        {
            response_id: "i9pyrbwup209buupvnfx2zi9pyrb5t8x",
            submitted_at: "2025-05-16T02:37:14Z",
            firstName: "Aditya",
            lastName: "Tadimeti",
            currentAffiliation: "Senior",
            phoneNumber: "+16508625251",
            city: "San Francisco",
            otherCity: null,
            duration: "Internship",
            roommates: false,
            waitlistInterest: true,
            friendEmails: []
        },
        {
            response_id: "wq84ihkn9po5d2izavfx9wq84ihkisa4",
            submitted_at: "2025-05-16T02:30:29Z",
            firstName: "Ashley",
            lastName: "Celada",
            currentAffiliation: "Senior",
            phoneNumber: "+15623264942",
            city: "Other",
            otherCity: "Washington D.C",
            duration: "Full-time",
            roommates: true,
            waitlistInterest: true,
            friendEmails: []
        },
        {
            response_id: "ylq9fu6lwbdaj09k98ylq9s4gquh5d40",
            submitted_at: "2025-05-16T02:09:39Z",
            firstName: "Noah",
            lastName: "Wong",
            currentAffiliation: "Senior",
            phoneNumber: "+16504417128",
            city: "San Francisco",
            otherCity: null,
            duration: "Full-time",
            roommates: false,
            waitlistInterest: true,
            friendEmails: []
        }
    ]
};

function validateSubmission(submission: any): boolean {
    try {
        // Create a mock Typeform response structure
        const mockTypeformResponse = {
            form_response: {
                response_id: submission.response_id,
                submitted_at: submission.submitted_at,
                answers: [
                    { field: { id: 'MEGys69wiBhi' }, type: 'text', text: submission.firstName },
                    { field: { id: 'GNCi1XAhRQvR' }, type: 'text', text: submission.lastName },
                    { field: { id: 'GFw2tipEzc0O' }, type: 'choice', choice: { label: submission.currentAffiliation } },
                    { field: { id: '5CE3giUnffMe' }, type: 'phone_number', phone_number: submission.phoneNumber },
                    { field: { id: '9ScYiTXOawbz' }, type: 'choice', choice: { label: submission.city } },
                    { field: { id: 'ZJmOLPPNPQvN' }, type: 'text', text: submission.otherCity || '' },
                    { field: { id: 'UXRVjcbY6ftC' }, type: 'choice', choice: { label: submission.duration } },
                    { field: { id: 'MOY2eASoCeWu' }, type: 'boolean', boolean: submission.roommates },
                    { field: { id: 'rbgCT6LAYaqB' }, type: 'choice', choice: { label: submission.waitlistInterest ? 'Sign me up!' : 'No thanks' } }
                ]
            }
        };

        // Process the submission
        const processedSubmission = getFormSubmission(mockTypeformResponse);

        // Validate the processed submission matches the original
        const isValid = 
            processedSubmission.firstName === submission.firstName &&
            processedSubmission.lastName === submission.lastName &&
            processedSubmission.currentAffiliation === submission.currentAffiliation &&
            processedSubmission.phoneNumber === submission.phoneNumber &&
            processedSubmission.city === submission.city &&
            processedSubmission.otherCity === submission.otherCity &&
            processedSubmission.duration === submission.duration &&
            processedSubmission.roommates === submission.roommates &&
            processedSubmission.waitlistInterest === submission.waitlistInterest;

        if (!isValid) {
            console.error('Validation failed for submission:', submission.response_id);
            console.error('Original:', submission);
            console.error('Processed:', processedSubmission);
        }

        return isValid;
    } catch (error) {
        console.error('Error validating submission:', submission.response_id, error);
        return false;
    }
}

// Run validation on all submissions
console.log('Starting validation of submissions...');
const results = responseData.responses.map(submission => ({
    response_id: submission.response_id,
    isValid: validateSubmission(submission)
}));

// Print results
console.log('\nValidation Results:');
results.forEach(result => {
    console.log(`${result.response_id}: ${result.isValid ? '✅ Valid' : '❌ Invalid'}`);
});

// Print summary
const totalValid = results.filter(r => r.isValid).length;
console.log(`\nSummary: ${totalValid}/${results.length} submissions validated successfully`); 