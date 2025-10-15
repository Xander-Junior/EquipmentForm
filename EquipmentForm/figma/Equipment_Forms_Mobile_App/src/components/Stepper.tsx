import { CheckCircle2, Circle } from "lucide-react";

interface StepperProps {
  currentStep: number;
  steps: { id: number; label: string; description?: string }[];
  onStepClick?: (step: number) => void;
}

export function Stepper({ currentStep, steps, onStepClick }: StepperProps) {
  return (
    <div className="w-full px-4 py-6 bg-white border-b border-border">
      <div className="flex items-center justify-between max-w-md mx-auto">
        {steps.map((step, index) => {
          const isCompleted = step.id < currentStep;
          const isCurrent = step.id === currentStep;
          const isClickable = onStepClick && step.id <= currentStep;
          
          return (
            <div key={step.id} className="flex items-center">
              <button
                onClick={() => isClickable && onStepClick(step.id)}
                disabled={!isClickable}
                className={`
                  flex flex-col items-center space-y-2 transition-all duration-200
                  ${isClickable ? 'cursor-pointer hover:scale-105' : 'cursor-default'}
                `}
              >
                <div className={`
                  flex items-center justify-center w-8 h-8 rounded-full border-2 transition-all duration-200
                  ${isCompleted 
                    ? 'bg-[rgb(75,160,70)] border-[rgb(75,160,70)] text-white' 
                    : isCurrent 
                    ? 'bg-primary border-primary text-primary-foreground'
                    : 'bg-background border-muted-foreground text-muted-foreground'
                  }
                `}>
                  {isCompleted ? (
                    <CheckCircle2 className="w-5 h-5" />
                  ) : (
                    <Circle className="w-5 h-5" />
                  )}
                </div>
                <span className={`
                  text-sm transition-colors duration-200
                  ${isCurrent 
                    ? 'text-primary' 
                    : isCompleted 
                    ? 'text-[rgb(75,160,70)]' 
                    : 'text-muted-foreground'
                  }
                `}>
                  {step.label}
                </span>
              </button>
              
              {index < steps.length - 1 && (
                <div className={`
                  w-8 h-0.5 mx-2 transition-colors duration-200
                  ${step.id < currentStep ? 'bg-[rgb(75,160,70)]' : 'bg-muted'}
                `} />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}