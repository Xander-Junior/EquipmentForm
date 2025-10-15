import { useState } from "react";
import { Button } from "./ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Switch } from "./ui/switch";
import { Label } from "./ui/label";
import { 
  Camera, 
  FileText, 
  Crop, 
  Zap, 
  X, 
  Check,
  Upload
} from "lucide-react";

interface FieldCaptureSheetProps {
  fieldName: string;
  onExtract: (text: string, confidence: number) => void;
  onClose: () => void;
}

export function FieldCaptureSheet({ fieldName, onExtract, onClose }: FieldCaptureSheetProps) {
  const [step, setStep] = useState<'capture' | 'preview' | 'crop' | 'result'>('capture');
  const [improveLegibility, setImproveLegibility] = useState(false);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [extractedText, setExtractedText] = useState('');
  const [confidence, setConfidence] = useState(0);

  const handleCapture = (method: 'camera' | 'file') => {
    // Mock image capture
    setCapturedImage('/api/placeholder/300/200');
    setStep('preview');
  };

  const handleCrop = () => {
    setStep('crop');
  };

  const handleExtract = () => {
    // Mock OCR extraction
    const mockTexts = {
      name: "John Doe",
      department: "IT Support",
      email: "john.doe@tullowoil.com"
    };
    
    const mockText = mockTexts[fieldName as keyof typeof mockTexts] || "Sample Text";
    const mockConfidence = Math.random() * 0.4 + 0.6; // 60-100%
    
    setExtractedText(mockText);
    setConfidence(mockConfidence);
    setStep('result');
  };

  const handleConfirm = () => {
    onExtract(extractedText, confidence);
    onClose();
  };

  const getConfidenceColor = (conf: number) => {
    if (conf >= 0.8) return "bg-success text-success-foreground";
    if (conf >= 0.6) return "bg-warning text-warning-foreground";
    return "bg-destructive text-destructive-foreground";
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Capture {fieldName}</CardTitle>
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
                  Choose how to capture the {fieldName} information
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
                    <span className="text-xs">File</span>
                  </Button>
                </div>

                <div className="flex items-center space-x-2 pt-4 border-t">
                  <Switch
                    checked={improveLegibility}
                    onCheckedChange={setImproveLegibility}
                  />
                  <Label className="text-sm">Improve Legibility</Label>
                  <Badge variant="outline" className="text-xs">
                    Preprocessing
                  </Badge>
                </div>
              </div>
            </>
          )}

          {step === 'preview' && (
            <>
              <div className="space-y-4">
                <div className="text-center">
                  <h3 className="font-medium">Image Captured</h3>
                  <p className="text-sm text-muted-foreground">
                    Review the captured image and crop if needed
                  </p>
                </div>

                <div className="border rounded-lg overflow-hidden">
                  <img 
                    src={capturedImage || ''} 
                    alt="Captured image" 
                    className="w-full h-32 object-cover"
                  />
                </div>

                {improveLegibility && (
                  <div className="text-center">
                    <Badge variant="secondary" className="text-xs">
                      <Zap className="w-3 h-3 mr-1" />
                      Image enhanced for better OCR
                    </Badge>
                  </div>
                )}

                <div className="flex space-x-2">
                  <Button variant="outline" onClick={handleCrop} className="flex-1">
                    <Crop className="w-4 h-4 mr-2" />
                    Crop
                  </Button>
                  <Button onClick={handleExtract} className="flex-1">
                    Extract Text
                  </Button>
                </div>
              </div>
            </>
          )}

          {step === 'crop' && (
            <>
              <div className="space-y-4">
                <div className="text-center">
                  <h3 className="font-medium">Crop to Field</h3>
                  <p className="text-sm text-muted-foreground">
                    Drag to select the {fieldName} area
                  </p>
                </div>

                <div className="border rounded-lg overflow-hidden relative">
                  <img 
                    src={capturedImage || ''} 
                    alt="Image to crop" 
                    className="w-full h-32 object-cover"
                  />
                  <div className="absolute inset-4 border-2 border-primary border-dashed bg-primary/10" />
                </div>

                <div className="flex space-x-2">
                  <Button variant="outline" onClick={() => setStep('preview')} className="flex-1">
                    Back
                  </Button>
                  <Button onClick={handleExtract} className="flex-1">
                    Extract Text
                  </Button>
                </div>
              </div>
            </>
          )}

          {step === 'result' && (
            <>
              <div className="space-y-4">
                <div className="text-center">
                  <h3 className="font-medium">Extraction Result</h3>
                  <div className="flex items-center justify-center space-x-2 mt-2">
                    <Badge 
                      className={`text-xs ${getConfidenceColor(confidence)}`}
                    >
                      {Math.round(confidence * 100)}% Confidence
                    </Badge>
                  </div>
                </div>

                <div className="border rounded-lg p-3">
                  <Label className="text-xs text-muted-foreground">Extracted {fieldName}:</Label>
                  <div className="mt-1 font-medium">{extractedText}</div>
                </div>

                <div className="flex space-x-2">
                  <Button variant="outline" onClick={() => setStep('capture')} className="flex-1">
                    Retake
                  </Button>
                  <Button onClick={handleConfirm} className="flex-1">
                    <Check className="w-4 h-4 mr-2" />
                    Use This
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