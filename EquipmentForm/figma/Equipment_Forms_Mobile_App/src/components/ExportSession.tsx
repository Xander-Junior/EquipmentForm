import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Separator } from "./ui/separator";
import { ArrowLeft, FileText, Share, Download, CheckCircle2, Plus, Home } from "lucide-react";

interface FormData {
  profile: any;
  party: any;
  equipment: any;
  workflow: any;
}

interface ExportSessionProps {
  formType: 'received' | 'returned' | 'replaced';
  formData: FormData;
  onBack: () => void;
  onComplete: () => void;
}

export function ExportSession({ 
  formType, 
  formData,
  onBack,
  onComplete
}: ExportSessionProps) {
  const { party: partyData, equipment: equipmentData, workflow: workflowData } = formData;
  const [isGenerating, setIsGenerating] = useState(false);
  const [isGenerated, setIsGenerated] = useState(false);

  const generatePDF = async () => {
    setIsGenerating(true);
    // Simulate PDF generation
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsGenerating(false);
    setIsGenerated(true);
  };

  const getFileName = () => {
    const date = new Date().toISOString().split('T')[0];
    const deviceType = equipmentData?.devices?.[0]?.type?.toUpperCase() || 'DEVICE';
    const location = workflowData.location;
    return `${formType.toUpperCase()}_${deviceType}_${location}_${date}.pdf`;
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: `Equipment ${formType} Form`,
          text: `Equipment ${formType} form for ${equipmentData?.devices?.[0]?.make || ''} ${equipmentData?.devices?.[0]?.model || ''}`,
          // In a real app, this would be a blob URL or file
          url: window.location.href
        });
      } catch (error) {
        console.log('Error sharing:', error);
      }
    } else {
      // Fallback for browsers that don't support Web Share API
      alert('PDF would be shared via native share sheet');
    }
  };

  const auditData = {
    timestamp: new Date().toISOString(),
    formType,
    parties: Object.keys(partyData).filter(key => partyData[key]),
    deviceType: equipmentData.primary.type,
    location: workflowData.location,
    ocrUsed: Object.values(partyData).some((person: any) => person?.confidence),
    templateVersion: "1.0.0",
    deviceInfo: {
      userAgent: navigator.userAgent,
      platform: navigator.platform
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-success text-success-foreground p-4">
        <div className="flex items-center space-x-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={onBack}
            className="text-success-foreground hover:bg-success-foreground/10"
          >
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h1 className="text-xl">Form Complete</h1>
            <p className="text-sm opacity-90">Export & Share</p>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-6">
        {/* Success Message */}
        <Card className="border-success/50 bg-success/5">
          <CardContent className="pt-6">
            <div className="text-center space-y-3">
              <div className="w-16 h-16 bg-success rounded-full flex items-center justify-center mx-auto">
                <CheckCircle2 className="w-8 h-8 text-success-foreground" />
              </div>
              <div>
                <h2 className="text-lg font-medium">Form Successfully Created</h2>
                <p className="text-sm text-muted-foreground">
                  Your equipment {formType} form has been generated and is ready to export
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* PDF Preview */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <FileText className="w-5 h-5" />
              <span>PDF Preview</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="border-2 border-dashed border-muted rounded-lg p-8 bg-muted/20">
              <div className="text-center space-y-4">
                <div className="w-16 h-20 bg-muted rounded border-2 border-border mx-auto flex items-center justify-center">
                  <FileText className="w-8 h-8 text-muted-foreground" />
                </div>
                <div>
                  <p className="font-medium">{getFileName()}</p>
                  <p className="text-sm text-muted-foreground">
                    Equipment {formType} form • {formType === 'replaced' ? '2' : '1'} page(s)
                  </p>
                </div>
                
                {!isGenerated ? (
                  <Button 
                    onClick={generatePDF} 
                    disabled={isGenerating}
                    className="mt-4"
                  >
                    {isGenerating ? 'Generating PDF...' : 'Generate PDF'}
                  </Button>
                ) : (
                  <div className="space-y-2">
                    <Badge variant="outline" className="bg-success text-success-foreground border-success">
                      <CheckCircle2 className="w-3 h-3 mr-1" />
                      PDF Generated
                    </Badge>
                    <div className="flex space-x-2 justify-center">
                      <Button variant="outline" size="sm">
                        <Download className="w-4 h-4 mr-2" />
                        Download
                      </Button>
                      <Button variant="outline" size="sm" onClick={handleShare}>
                        <Share className="w-4 h-4 mr-2" />
                        Share
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Form Summary */}
        <Card>
          <CardHeader>
            <CardTitle>Form Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-sm">
            <div>
              <strong>Form Type:</strong>
              <Badge variant="secondary" className="ml-2">{formType.toUpperCase()}</Badge>
            </div>
            
            <Separator />
            
            <div>
              <strong>Equipment:</strong>
              <div className="text-muted-foreground mt-1">
                {equipmentData.primary.make} {equipmentData.primary.model}
                {equipmentData.accessories.length > 0 && (
                  <span> + {equipmentData.accessories.length} accessory(ies)</span>
                )}
              </div>
            </div>
            
            <Separator />
            
            <div>
              <strong>Parties Involved:</strong>
              <div className="text-muted-foreground mt-1 space-y-1">
                {Object.entries(partyData).map(([role, person]: [string, any]) => {
                  if (!person) return null;
                  return (
                    <div key={role}>
                      {role.replace(/([A-Z])/g, ' $1').trim()}: {person.name}
                    </div>
                  );
                })}
              </div>
            </div>
            
            <Separator />
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>Location:</strong>
                <div className="text-muted-foreground">{workflowData.location}</div>
              </div>
              {workflowData.dateReceived && (
                <div>
                  <strong>Date Received:</strong>
                  <div className="text-muted-foreground">{workflowData.dateReceived}</div>
                </div>
              )}
              {workflowData.dateReturned && (
                <div>
                  <strong>Date Returned:</strong>
                  <div className="text-muted-foreground">{workflowData.dateReturned}</div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Audit Information */}
        <Card className="bg-muted/50">
          <CardHeader>
            <CardTitle className="text-sm">Audit Information</CardTitle>
          </CardHeader>
          <CardContent className="text-xs space-y-2">
            <div><strong>Timestamp:</strong> {auditData.timestamp}</div>
            <div><strong>Template Version:</strong> {auditData.templateVersion}</div>
            <div><strong>OCR Used:</strong> {auditData.ocrUsed ? 'Yes' : 'No'}</div>
            <div><strong>Platform:</strong> {auditData.deviceInfo.platform}</div>
            <p className="text-muted-foreground mt-2">
              A detailed audit.json file has been generated alongside your PDF for compliance tracking.
            </p>
          </CardContent>
        </Card>

        {/* Actions */}
        <div className="space-y-3">
          <Button 
            onClick={onNewSession}
            variant="outline" 
            className="w-full h-12"
          >
            <Plus className="w-4 h-4 mr-2" />
            Create New Form
          </Button>
          
          <Button 
            onClick={onHome}
            className="w-full h-12"
          >
            <Home className="w-4 h-4 mr-2" />
            Return to Home
          </Button>
        </div>
      </div>
    </div>
  );
}