import { useState, useEffect } from "react";
import { Stepper } from "./Stepper";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Checkbox } from "./ui/checkbox";
import { Badge } from "./ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { ArrowLeft, ArrowRight, Calendar, AlertTriangle } from "lucide-react";

interface ProfileData {
  name: string;
  department: string;
  defaultLocation: string;
}

interface WorkflowData {
  formType: 'received' | 'returned' | 'replaced';
  dateReceived?: string;
  dateReturned?: string;
  dataHandlingConfirmed: boolean;
  location: string;
}

interface WorkflowSessionProps {
  formType: 'received' | 'returned' | 'replaced';
  profile: ProfileData;
  onComplete: (workflowData: WorkflowData) => void;
  onBack: () => void;
  initialData?: WorkflowData;
}

const WORKFLOW_STEPS = [
  { id: 1, label: "Party", description: "People involved" },
  { id: 2, label: "Equipment", description: "Device details" },
  { id: 3, label: "Workflow", description: "Dates & process" },
  { id: 4, label: "Review", description: "Verify & export" }
];

const LOCATIONS = [
  { code: "ACC", name: "Accra" },
  { code: "TAK", name: "Takoradi" },
  { code: "LON", name: "London" },
  { code: "ABJ", name: "Abidjan" },
  { code: "DAR", name: "Dar es Salaam" }
];

export function WorkflowSession({ formType, profile, onComplete, onBack, initialData }: WorkflowSessionProps) {
  const [dateReceived, setDateReceived] = useState(initialData?.dateReceived || '');
  const [dateReturned, setDateReturned] = useState(initialData?.dateReturned || '');
  const [dataHandling, setDataHandling] = useState(initialData?.dataHandlingConfirmed || false);
  const [location, setLocation] = useState(initialData?.location || profile.defaultLocation);
  const [receivedAutoSet, setReceivedAutoSet] = useState(false);
  const [returnedAutoSet, setReturnedAutoSet] = useState(false);

  // Auto-set dates based on form type
  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    
    if (formType === 'received') {
      setDateReceived(today);
      setReceivedAutoSet(true);
      setDateReturned('');
    } else if (formType === 'returned') {
      setDateReturned(today);
      setReturnedAutoSet(true);
      setDateReceived('');
    } else if (formType === 'replaced') {
      // For replaced: NEW equipment received today, OLD equipment returned today
      setDateReceived(today);
      setDateReturned(today);
      setReceivedAutoSet(true);
      setReturnedAutoSet(true);
    }
  }, [formType]);

  const isDataHandlingRequired = formType === 'returned' || formType === 'replaced';

  const isValid = () => {
    let valid = true;
    
    if (formType === 'received') {
      valid = dateReceived.trim() !== '';
    } else if (formType === 'returned') {
      valid = dateReturned.trim() !== '' && dataHandling;
    } else if (formType === 'replaced') {
      valid = dateReceived.trim() !== '' && dateReturned.trim() !== '' && dataHandling;
    }
    
    return valid && location.trim() !== '';
  };

  const handleNext = () => {
    if (isValid()) {
      onComplete({
        formType,
        dateReceived: dateReceived || undefined,
        dateReturned: dateReturned || undefined,
        dataHandlingConfirmed: dataHandling,
        location
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
            <p className="text-sm opacity-90">Workflow & Dates</p>
          </div>
        </div>
      </div>

      {/* Stepper */}
      <Stepper currentStep={3} steps={WORKFLOW_STEPS} />

      {/* Content */}
      <div className="p-4 space-y-6 pb-20">
        {/* Location Override */}
        <Card>
          <CardHeader>
            <CardTitle>Location</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <Label>Processing Location</Label>
              <Select value={location} onValueChange={setLocation}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {LOCATIONS.map(loc => (
                    <SelectItem key={loc.code} value={loc.code}>
                      {loc.name} ({loc.code})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">
                This affects asset tag prefixes and form processing
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Date Management */}
        <Card>
          <CardHeader>
            <CardTitle>Date Management</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Date Received */}
            {(formType === 'received' || formType === 'replaced') && (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label>Date Received</Label>
                  {receivedAutoSet && (
                    <Badge variant="secondary" className="text-xs">
                      <Calendar className="w-3 h-3 mr-1" />
                      Auto-set: Today
                    </Badge>
                  )}
                </div>
                <Input
                  type="date"
                  value={dateReceived}
                  onChange={(e) => {
                    setDateReceived(e.target.value);
                    setReceivedAutoSet(false);
                  }}
                />
                {formType === 'replaced' && (
                  <p className="text-xs text-muted-foreground">
                    Date when NEW equipment was received
                  </p>
                )}
              </div>
            )}

            {/* Date Returned */}
            {(formType === 'returned' || formType === 'replaced') && (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label>Date Returned</Label>
                  {returnedAutoSet && (
                    <Badge variant="secondary" className="text-xs">
                      <Calendar className="w-3 h-3 mr-1" />
                      Auto-set: Today
                    </Badge>
                  )}
                </div>
                <Input
                  type="date"
                  value={dateReturned}
                  onChange={(e) => {
                    setDateReturned(e.target.value);
                    setReturnedAutoSet(false);
                  }}
                />
                {formType === 'replaced' && (
                  <p className="text-xs text-muted-foreground">
                    Date when OLD equipment was returned
                  </p>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Data Handling (Required for returns/replacements) */}
        {isDataHandlingRequired && (
          <Card className={`${!dataHandling ? 'border-destructive/50 bg-destructive/5' : ''}`}>
            <CardHeader>
              <div className="flex items-center space-x-2">
                <CardTitle>Data Handling</CardTitle>
                {!dataHandling && (
                  <Badge variant="destructive" className="text-xs">
                    Required
                  </Badge>
                )}
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-start space-x-3">
                  <Checkbox
                    id="data-handling"
                    checked={dataHandling}
                    onCheckedChange={(checked) => setDataHandling(checked as boolean)}
                    className="mt-1"
                  />
                  <div className="space-y-1">
                    <Label 
                      htmlFor="data-handling" 
                      className="text-sm leading-relaxed cursor-pointer"
                    >
                      Personal data removed & OneDrive backup completed
                    </Label>
                    <p className="text-xs text-muted-foreground">
                      Confirm that all personal data has been removed from the device and 
                      any necessary backups have been completed to OneDrive
                    </p>
                  </div>
                </div>

                {!dataHandling && (
                  <div className="flex items-start space-x-2 p-3 bg-destructive/10 rounded-lg border border-destructive/20">
                    <AlertTriangle className="w-4 h-4 text-destructive mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-destructive">
                      <p className="font-medium">Data handling confirmation required</p>
                      <p className="text-xs">
                        This checkbox must be checked before proceeding with equipment {formType}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Form Type Logic Summary */}
        <Card className="bg-muted/50">
          <CardHeader>
            <CardTitle className="text-sm">Workflow Summary</CardTitle>
          </CardHeader>
          <CardContent className="text-sm space-y-2">
            {formType === 'received' && (
              <div>
                <p><strong>Equipment Received:</strong></p>
                <ul className="list-disc list-inside space-y-1 text-muted-foreground">
                  <li>Date Received: {dateReceived || 'Not set'}</li>
                  <li>Date Returned: Not applicable</li>
                  <li>Data Handling: Not required</li>
                </ul>
              </div>
            )}
            
            {formType === 'returned' && (
              <div>
                <p><strong>Equipment Returned:</strong></p>
                <ul className="list-disc list-inside space-y-1 text-muted-foreground">
                  <li>Date Received: Not applicable</li>
                  <li>Date Returned: {dateReturned || 'Not set'}</li>
                  <li>Data Handling: {dataHandling ? 'Confirmed' : 'Required'}</li>
                </ul>
              </div>
            )}
            
            {formType === 'replaced' && (
              <div>
                <p><strong>Equipment Replaced:</strong></p>
                <ul className="list-disc list-inside space-y-1 text-muted-foreground">
                  <li>NEW Equipment Received: {dateReceived || 'Not set'}</li>
                  <li>OLD Equipment Returned: {dateReturned || 'Not set'}</li>
                  <li>Data Handling: {dataHandling ? 'Confirmed' : 'Required'}</li>
                </ul>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-background border-t border-border">
        <Button
          onClick={handleNext}
          disabled={!isValid()}
          className="w-full h-12"
        >
          Next: Review
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}