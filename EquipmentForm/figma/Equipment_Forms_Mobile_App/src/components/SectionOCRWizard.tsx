import { useState } from "react";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Checkbox } from "./ui/checkbox";
import { 
  Camera, 
  Upload, 
  Zap, 
  X, 
  Check,
  AlertCircle,
  Eye,
  EyeOff
} from "lucide-react";

interface OCRCandidate {
  field: 'name' | 'department' | 'email';
  value: string;
  confidence: number;
  alternatives: { value: string; confidence: number }[];
}

interface SectionOCRWizardProps {
  onApply: (results: Record<string, { value: string; confidence: number }>) => void;
  onClose: () => void;
}

export function SectionOCRWizard({ onApply, onClose }: SectionOCRWizardProps) {
  const [step, setStep] = useState<'capture' | 'mapping'>('capture');
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [showEvidence, setShowEvidence] = useState(false);
  const [candidates] = useState<OCRCandidate[]>([
    {
      field: 'name',
      value: 'Jane Smith',
      confidence: 0.92,
      alternatives: [
        { value: 'Jane Smith', confidence: 0.92 },
        { value: 'Jane Snith', confidence: 0.78 },
        { value: 'J. Smith', confidence: 0.65 }
      ]
    },
    {
      field: 'department',
      value: 'Operations',
      confidence: 0.85,
      alternatives: [
        { value: 'Operations', confidence: 0.85 },
        { value: 'Operations Dept', confidence: 0.73 },
        { value: 'Op erations', confidence: 0.45 }
      ]
    },
    {
      field: 'email',
      value: 'jane.smith@tullowoil.com',
      confidence: 0.88,
      alternatives: [
        { value: 'jane.smith@tullowoil.com', confidence: 0.88 },
        { value: 'jane.smith@tullowoil.co.uk', confidence: 0.72 },
        { value: 'jane@tullowoil.com', confidence: 0.69 }
      ]
    }
  ]);

  const [selectedValues, setSelectedValues] = useState<Record<string, { value: string; confidence: number }>>({
    name: { value: candidates[0].value, confidence: candidates[0].confidence },
    department: { value: candidates[1].value, confidence: candidates[1].confidence },
    email: { value: candidates[2].value, confidence: candidates[2].confidence }
  });

  const handleCapture = (method: 'camera' | 'file') => {
    setCapturedImage('/api/placeholder/400/250');
    // Simulate processing time
    setTimeout(() => {
      setStep('mapping');
    }, 1500);
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 0.8) return "bg-success text-success-foreground";
    if (confidence >= 0.6) return "bg-warning text-warning-foreground";
    return "bg-destructive text-destructive-foreground";
  };

  const handleValueSelect = (field: string, value: string, confidence: number) => {
    setSelectedValues(prev => ({
      ...prev,
      [field]: { value, confidence }
    }));
  };

  const handleApply = () => {
    onApply(selectedValues);
    onClose();
  };

  const hasLowConfidence = Object.values(selectedValues).some(item => item.confidence < 0.7);

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Zap className="w-5 h-5 text-accent" />
              <CardTitle>Section OCR Wizard</CardTitle>
            </div>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="w-4 h-4" />
            </Button>
          </div>
        </CardHeader>

        <CardContent className="space-y-4">
          {step === 'capture' && (
            <>
              <div className="text-center space-y-4">
                <p className="text-sm text-muted-foreground">
                  Capture an image containing name, department, and email information
                </p>
                
                <div className="grid grid-cols-2 gap-3">
                  <Button
                    variant="outline"
                    className="h-20 flex-col space-y-2"
                    onClick={() => handleCapture('camera')}
                  >
                    <Camera className="w-6 h-6" />
                    <span className="text-xs">Camera</span>
                  </Button>
                  
                  <Button
                    variant="outline"
                    className="h-20 flex-col space-y-2"
                    onClick={() => handleCapture('file')}
                  >
                    <Upload className="w-6 h-6" />
                    <span className="text-xs">Pick File</span>
                  </Button>
                </div>

                <div className="text-xs text-muted-foreground">
                  Works best with business cards, email signatures, or forms
                </div>
              </div>
            </>
          )}

          {step === 'mapping' && (
            <>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-medium">OCR Results</h3>
                  <div className="flex items-center space-x-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setShowEvidence(!showEvidence)}
                    >
                      {showEvidence ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      <span className="ml-1 text-xs">
                        {showEvidence ? 'Hide' : 'Show'} Evidence
                      </span>
                    </Button>
                  </div>
                </div>

                {showEvidence && capturedImage && (
                  <div className="border rounded-lg overflow-hidden">
                    <img 
                      src={capturedImage} 
                      alt="OCR source" 
                      className="w-full h-32 object-cover"
                    />
                  </div>
                )}

                <div className="space-y-4">
                  {candidates.map((candidate) => (
                    <div key={candidate.field} className="space-y-2">
                      <div className="flex items-center justify-between">
                        <label className="font-medium capitalize">{candidate.field}</label>
                        <Badge 
                          className={`text-xs ${getConfidenceColor(selectedValues[candidate.field].confidence)}`}
                        >
                          {Math.round(selectedValues[candidate.field].confidence * 100)}%
                        </Badge>
                      </div>
                      
                      <div className="space-y-2">
                        {candidate.alternatives.map((alt, index) => (
                          <div key={index} className="flex items-center space-x-2">
                            <Checkbox
                              checked={selectedValues[candidate.field].value === alt.value}
                              onCheckedChange={(checked) => {
                                if (checked) {
                                  handleValueSelect(candidate.field, alt.value, alt.confidence);
                                }
                              }}
                            />
                            <div className="flex-1 flex items-center justify-between">
                              <span className={`text-sm ${index === 0 ? 'font-medium' : 'text-muted-foreground'}`}>
                                {alt.value}
                              </span>
                              <Badge variant="outline" className="text-xs">
                                {Math.round(alt.confidence * 100)}%
                              </Badge>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>

                {hasLowConfidence && (
                  <div className="flex items-start space-x-2 p-3 bg-warning/10 rounded-lg border border-warning/20">
                    <AlertCircle className="w-4 h-4 text-warning mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-warning">
                      <p className="font-medium">Low confidence detected</p>
                      <p className="text-xs">
                        Some extractions have low confidence. Please review carefully.
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex space-x-2 pt-4 border-t">
                  <Button variant="outline" onClick={() => setStep('capture')} className="flex-1">
                    Retake
                  </Button>
                  <Button onClick={handleApply} className="flex-1">
                    <Check className="w-4 h-4 mr-2" />
                    Apply Results
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}