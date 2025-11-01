#!/bin/bash
#
# Run batch matcher worker
# Can be triggered manually or via cron
#

cd "$(dirname "$0")/.."

echo "🔄 Running batch matcher..."
echo "Time: $(date)"

# Load environment variables
if [ -f "env.development" ]; then
  export $(cat env.development | grep -v '^#' | xargs)
fi

# Run the worker
npx ts-node src/workers/batchMatcher.ts

echo "✅ Batch matcher completed at $(date)"

