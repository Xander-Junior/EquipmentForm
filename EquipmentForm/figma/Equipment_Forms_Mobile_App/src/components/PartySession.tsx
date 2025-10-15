import { useState } from "react";
import { Stepper } from "./Stepper";
import { PartyCard } from "./PartyCard";
import { Button } from "./ui/button";
import { ArrowLeft, ArrowRight } from "lucide-react";

interface PartyMember {
  name: string;
  department: string;
  email: string;
  confidence?: {
    name: number;
    department: number;
    email: number;
  };
}

interface ProfileData {
  name: string;
  department: string;
  defaultLocation: string;
}

interface PartyData {
  requestedBy: PartyMember;
  preparedBy: PartyMember;
  receivedBy: PartyMember;
  returnedBy: PartyMember;
}

interface PartySessionProps {
  formType: 'received' | 'returned' | 'replaced';
  profile: ProfileData;
  onComplete: (partyData: PartyData) => void;
  onBack: () => void;
  initialData?: PartyData;
}

const WORKFLOW_STEPS = [
  { id: 1, label: "Party", description: "People involved" },
  { id: 2, label: "Equipment", description: "Device details" },
  { id: 3, label: "Workflow", description: "Dates & process" },
  { id: 4, label: "Review", description: "Verify & export" }
];

export function PartySession({ formType, profile, onComplete, onBack, initialData }: PartySessionProps) {
  const [requestedBy, setRequestedBy] = useState<PartyMember>(
    initialData?.requestedBy || {
      name: "",
      department: "",
      email: ""
    }
  );

  const [preparedBy, setPreparedBy] = useState<PartyMember>(
    initialData?.preparedBy || {
      name: profile.name,
      department: profile.department,
      email: ""
    }
  );

  const [receivedBy, setReceivedBy] = useState<PartyMember>(
    initialData?.receivedBy || {
      name: "",
      department: "",
      email: ""
    }
  );

  const [returnedBy, setReturnedBy] = useState<PartyMember>(
    initialData?.returnedBy || {
      name: "",
      department: "",
      email: ""
    }
  );

  const [receivedByCopied, setReceivedByCopied] = useState(false);
  const [returnedByCopied, setReturnedByCopied] = useState(false);

  const handleCopyToReceived = () => {
    setReceivedBy({ ...requestedBy });
    setReceivedByCopied(true);
  };

  const handleCopyToReturned = () => {
    setReturnedBy({ ...requestedBy });
    setReturnedByCopied(true);
  };

  const handleFieldCapture = (person: string, field: string) => {
    // Mock OCR result with medium confidence
    const mockOCRResult = {
      name: "John Doe",
      department: "IT Support",
      email: "john.doe@tullowoil.com"
    };

    const confidence = {
      name: Math.random() * 0.4 + 0.6, // 60-100%
      department: Math.random() * 0.4 + 0.6,
      email: Math.random() * 0.4 + 0.6
    };

    if (person === 'requested') {
      setRequestedBy(prev => ({
        ...prev,
        [field]: mockOCRResult[field as keyof typeof mockOCRResult],
        confidence: { ...prev.confidence, [field]: confidence[field as keyof typeof confidence] }
      }));
    }
  };

  const handleSectionOCR = (person: string) => {
    // Mock section OCR with all fields
    const mockOCRResult = {
      name: "Jane Smith",
      department: "Operations",
      email: "jane.smith@tullowoil.com",
      confidence: {
        name: Math.random() * 0.4 + 0.6,
        department: Math.random() * 0.4 + 0.6,
        email: Math.random() * 0.4 + 0.6
      }
    };

    if (person === 'requested') {
      setRequestedBy(mockOCRResult);
    }
  };

  const isValid = () => {
    const requiredFields = [requestedBy, preparedBy];
    
    if (formType === 'received' || formType === 'replaced') {
      requiredFields.push(receivedBy);
    }
    
    if (formType === 'returned' || formType === 'replaced') {
      requiredFields.push(returnedBy);
    }

    return requiredFields.every(person => 
      person.name.trim() && person.department.trim() && person.email.trim()
    );
  };

  const handleNext = () => {
    if (isValid()) {
      onComplete({
        requestedBy,
        preparedBy,
        receivedBy,
        returnedBy
      });
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-primary text-primary-foreground p-4">
        <div className="flex items-center space-x-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={onBack}
            className="text-primary-foreground hover:bg-primary-foreground/10"
          >
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h1 className="text-xl">Equipment {formType}</h1>
            <p className="text-sm opacity-90">Party Information</p>
          </div>
        </div>
      </div>

      {/* Stepper */}
      <Stepper currentStep={1} steps={WORKFLOW_STEPS} />

      {/* Content */}
      <div className="p-4 space-y-4 pb-20">
        {/* Requested By */}
        <PartyCard
          title="Requested By"
          member={requestedBy}
          onUpdate={setRequestedBy}
          onFieldCapture={(field) => handleFieldCapture('requested', field)}
          onSectionOCR={() => handleSectionOCR('requested')}
        />

        {/* Prepared By */}
        <PartyCard
          title="Prepared By"
          member={preparedBy}
          onUpdate={setPreparedBy}
        />

        {/* Received By (for received and replaced forms) */}
        {(formType === 'received' || formType === 'replaced') && (
          <PartyCard
            title="Received By"
            member={receivedBy}
            onUpdate={setReceivedBy}
            canCopyFrom={requestedBy}
            onCopyFrom={handleCopyToReceived}
            isCopied={receivedByCopied}
            onFieldCapture={(field) => handleFieldCapture('received', field)}
          />
        )}

        {/* Returned By (for returned and replaced forms) */}
        {(formType === 'returned' || formType === 'replaced') && (
          <PartyCard
            title="Returned By"
            member={returnedBy}
            onUpdate={setReturnedBy}
            canCopyFrom={requestedBy}
            onCopyFrom={handleCopyToReturned}
            isCopied={returnedByCopied}
            onFieldCapture={(field) => handleFieldCapture('returned', field)}
          />
        )}
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-background border-t border-border">
        <Button
          onClick={handleNext}
          disabled={!isValid()}
          className="w-full h-12"
        >
          Next: Equipment
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}