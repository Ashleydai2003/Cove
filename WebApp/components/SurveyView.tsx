'use client';

import { useState } from 'react';

interface SurveyViewProps {
  onComplete: () => void;
}

interface SurveyQuestion {
  id: string;
  question: string;
  subtitle?: string;
  type: 'single' | 'multi';
  options: string[];
  maxSelection?: number;
}

const SURVEY_QUESTIONS: SurveyQuestion[] = [
  {
    id: 'energy_source',
    question: 'where do you get your energy?',
    subtitle: 'after a long week, do you recharge by being around people or having time to yourself?',
    type: 'single',
    options: ['introvert—i recharge alone', 'ambivert—somewhere in between', 'extrovert—i recharge with people']
  },
  {
    id: 'group_size',
    question: "what's your ideal group size when hanging out?",
    subtitle: 'do you prefer intimate gatherings or bigger groups?',
    type: 'single',
    options: ['one-on-one or small group (2-3 people)', 'medium group (5-8 people)', 'large group (8+ people)', "i'm flexible; depends on activity"]
  },
  {
    id: 'valued_traits',
    question: 'what traits do you value most in people?',
    subtitle: 'select your top four:',
    type: 'multi',
    maxSelection: 4,
    options: ['funny & playful', 'loyal & dependable', 'adventurous & driven', 'chill & easygoing', 'thoughtful & empathetic', 'outgoing & social', 'deep & intellectual', 'creative & artistic', 'open-minded', 'honest & authentic']
  },
  {
    id: 'ideal_connection',
    question: 'my ideal connection involves:',
    subtitle: 'what are you looking for in a connection?',
    type: 'multi',
    options: ['deep conversations & emotional support', 'fun & lighthearted energy', 'shared activities & hobbies', 'going out together', 'intellectual discussions', 'adventure & trying new things', 'low-key, chill vibes', 'ambitious / growth-minded conversations']
  },
  {
    id: 'industry',
    question: 'what industry are you in?',
    subtitle: 'what field do you work in?',
    type: 'single',
    options: ['tech / startups', 'finance / consulting', 'creative / media / entertainment', 'healthcare / medicine', 'education / academia', 'legal', 'sales / marketing', 'service / hospitality', 'trades', 'student', 'between jobs / exploring', 'other']
  },
  {
    id: 'relationship_status',
    question: 'relationship status:',
    subtitle: "what's your current relationship status?",
    type: 'single',
    options: ['single', 'casually dating', 'in a relationship', "it's complicated"]
  },
  {
    id: 'sexual_orientation',
    question: 'sexual orientation:',
    subtitle: 'how do you identify?',
    type: 'single',
    options: ['straight', 'gay / lesbian', 'bisexual', 'pansexual', 'questioning', 'prefer not to say']
  },
  {
    id: 'music_genres',
    question: 'music genres you enjoy:',
    subtitle: 'what music do you enjoy?',
    type: 'multi',
    maxSelection: 5,
    options: ['hip-hop / rap', 'edm / house / techno', 'pop / top 40', 'r&b / soul', 'rock / alternative / indie', 'latin / reggaeton', 'country', 'jazz / blues', 'classical', "i'm open to everything"]
  },
  {
    id: 'drinking_habits',
    question: 'drinking habits:',
    subtitle: "what's your relationship with alcohol?",
    type: 'single',
    options: ['i drink regularly and enjoy going out', 'social drinker — occasional nights out', 'drink rarely', "don't drink", 'sober lifestyle']
  }
];

export default function SurveyView({ onComplete }: SurveyViewProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [selectedOptions, setSelectedOptions] = useState<Set<string>>(new Set());
  const [responses, setResponses] = useState<Record<string, any>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const currentQuestion = SURVEY_QUESTIONS[currentIndex];

  const handleOptionClick = (option: string) => {
    if (currentQuestion.type === 'single') {
      // Single select - submit immediately
      submitAnswer(option);
    } else {
      // Multi select - toggle selection
      const newSelected = new Set(selectedOptions);
      if (newSelected.has(option)) {
        newSelected.delete(option);
      } else {
        if (currentQuestion.maxSelection && newSelected.size >= currentQuestion.maxSelection) {
          return; // Don't allow more selections
        }
        newSelected.add(option);
      }
      setSelectedOptions(newSelected);
    }
  };

  const submitAnswer = async (answer: string | string[]) => {
    const newResponses = {
      ...responses,
      [currentQuestion.id]: answer
    };
    setResponses(newResponses);

    if (currentIndex < SURVEY_QUESTIONS.length - 1) {
      // Move to next question
      setCurrentIndex(currentIndex + 1);
      setSelectedOptions(new Set());
    } else {
      // Submit all responses
      await submitSurvey(newResponses);
    }
  };

  const handleContinue = () => {
    if (selectedOptions.size === 0) return;
    submitAnswer(Array.from(selectedOptions));
  };

  const submitSurvey = async (allResponses: Record<string, any>) => {
    setIsSubmitting(true);
    setError('');

    try {
      const formattedResponses = Object.entries(allResponses).map(([questionId, value]) => ({
        questionId,
        value: Array.isArray(value) ? value : value,
        isMustHave: false
      }));

      const response = await fetch('/api/match/survey', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ responses: formattedResponses })
      });

      if (response.ok) {
        onComplete();
      } else {
        const data = await response.json();
        setError(data.message || 'failed to submit survey');
      }
    } catch (err) {
      setError('network error. please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Show loading screen when submitting
  if (isSubmitting) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
        <div className="w-full max-w-md text-center">
          {/* Cove logo */}
          <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
            cove
          </h1>

          {/* Loading card */}
          <div className="bg-[#5E1C1D] rounded-3xl p-8 min-h-[500px] flex flex-col items-center justify-center">
            <div className="flex flex-col items-center">
              {/* Loading spinner */}
              <div className="animate-spin rounded-full h-12 w-12 border-4 border-white border-t-transparent mb-6"></div>
              
              {/* Loading text */}
              <h2 className="font-libre-bodoni text-2xl text-white font-semibold mb-2">
                submitting your responses...
              </h2>
              <p className="font-libre-bodoni text-base text-white opacity-80">
                thank you for completing the survey!
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Cove logo */}
        <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
          cove
        </h1>

        {/* Survey card */}
        <div className="bg-[#5E1C1D] rounded-3xl p-8 min-h-[500px] flex flex-col">
          {/* Question */}
          <div className="mb-6">
            <h2 className="font-libre-bodoni text-2xl text-white font-semibold mb-2">
              {currentQuestion.question}
            </h2>
            {currentQuestion.subtitle && (
              <p className="font-libre-bodoni text-base text-white opacity-80">
                {currentQuestion.subtitle}
              </p>
            )}
          </div>

          {/* Options */}
          <div className="flex-1 space-y-3 overflow-y-auto max-h-[400px]">
            {currentQuestion.options.map((option) => {
              const isSelected = selectedOptions.has(option);
              return (
                <button
                  key={option}
                  onClick={() => handleOptionClick(option)}
                  className={`w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base text-left transition-all ${
                    isSelected
                      ? 'bg-white text-[#5E1C1D]'
                      : 'bg-transparent text-white border border-white hover:bg-white hover:bg-opacity-10'
                  }`}
                >
                  {option}
                </button>
              );
            })}
          </div>

          {/* Continue button for multi-select */}
          {currentQuestion.type === 'multi' && selectedOptions.size > 0 && (
            <button
              onClick={handleContinue}
              disabled={isSubmitting}
              className="mt-6 w-full bg-white text-[#5E1C1D] font-libre-bodoni text-lg font-medium py-4 rounded-2xl hover:shadow-lg transition-all"
            >
              {isSubmitting ? 'submitting...' : 'continue'}
            </button>
          )}

          {/* Error message */}
          {error && (
            <p className="mt-4 text-red-300 font-libre-bodoni text-sm text-center">
              {error}
            </p>
          )}

          {/* Progress indicator */}
          <div className="mt-6 flex justify-center gap-2">
            {SURVEY_QUESTIONS.map((_, index) => (
              <div
                key={index}
                className={`h-2 rounded-full transition-all ${
                  index <= currentIndex ? 'w-8 bg-white' : 'w-2 bg-white bg-opacity-30'
                }`}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

