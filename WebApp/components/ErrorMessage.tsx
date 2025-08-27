interface ErrorMessageProps {
  message: string;
}

function getErrorTitle(message: string): string {
  if (message.toLowerCase().includes('not found') || message.toLowerCase().includes('404')) {
    return 'Event not found';
  }
  if (message.toLowerCase().includes('network') || message.toLowerCase().includes('fetch')) {
    return 'Connection error';
  }
  if (message.toLowerCase().includes('cors') || message.toLowerCase().includes('blocked')) {
    return 'Access blocked';
  }
  return 'Something went wrong';
}

function getErrorIcon(message: string): string {
  if (message.toLowerCase().includes('not found') || message.toLowerCase().includes('404')) {
    return '🔍';
  }
  if (message.toLowerCase().includes('network') || message.toLowerCase().includes('fetch')) {
    return '📡';
  }
  return '⚠️';
}

export function ErrorMessage({ message }: ErrorMessageProps) {
  const title = getErrorTitle(message);
  const icon = getErrorIcon(message);
  
  return (
    <div className="min-h-screen bg-faf8f4 flex items-center justify-center">
      <div className="card max-w-md mx-auto text-center">
        <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-red-100 flex items-center justify-center">
          <span className="text-red-500 text-2xl">{icon}</span>
        </div>
        <h2 className="font-libre-bodoni text-xl font-semibold text-primary-dark mb-2">
          {title}
        </h2>
        <p className="font-libre-bodoni text-lg text-k6F6F73">
          {message}
        </p>
        {title === 'Event not found' && (
          <p className="font-libre-bodoni text-sm text-k6F6F73 mt-2">
            This event may have been deleted or the link is incorrect.
          </p>
        )}
      </div>
    </div>
  );
} 