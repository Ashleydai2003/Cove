export function LoadingSpinner() {
  return (
    <div className="min-h-screen bg-faf8f4 flex items-center justify-center">
      <div className="card max-w-md mx-auto text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-dark mx-auto mb-4"></div>
        <p className="font-libre-bodoni text-lg text-k292929">Loading event details...</p>
      </div>
    </div>
  );
} 