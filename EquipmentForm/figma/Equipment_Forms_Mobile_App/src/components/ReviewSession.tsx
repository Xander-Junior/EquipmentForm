import { useState } from "react";
import { Stepper } from "./Stepper";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { Separator } from "./ui/separator";
import { ArrowLeft, ArrowRight, FileText, AlertCircle, CheckCircle2, Edit } from "lucide-react";

interface FormData {
  profile: any;
  party: any;
  equipment: any;
  workflow: any;
}

interface ReviewSessionProps {
  formType: 'received' | 'returned' | 'replaced';
  formData: FormData;
  onComplete: () => void;
  onBack: () => void;
  onEdit: (section: string) => void;
}

const WORKFLOW_STEPS = [
  { id: 1, label: "Party", description: "People involved" },
  { id: 2, label: "Equipment", description: "Device details" },
  { id: 3, label: "Workflow", description: "Dates & process" },
  { id: 4, label: "Review", description: "Verify & export" }
];

export function ReviewSession({ 
  formType, 
  formData, 
  onComplete, 
  onBack, 
  onEdit 
}: ReviewSessionProps) {
  const { party: partyData, equipment: equipmentData, workflow: workflowData } = formData;
  const [validationIssues] = useState<string[]>([]);

  const getConfidenceBadge = (confidence?: number) => {
    if (!confidence) return null;
    
    let color = "bg-success";
    let text = "High";
    
    if (confidence < 0.8) {
      color = "bg-warning";
      text = "Medium";
    }
    if (confidence < 0.6) {
      color = "bg-destructive";
      text = "Low";
    }
    
    return (
      <Badge variant="outline" className={`${color} text-white border-0 text-xs`}>
        {text} ({Math.round(confidence * 100)}%)
      </Badge>
    );
  };

  const renderEquipmentRow = (equipment: any, accessories: any[], type: 'NEW' | 'OLD' | 'DEVICE' = 'DEVICE') => {
    const leftColumn = [
      `${equipment.make || ''} ${equipment.model || ''}`.trim() || 'Unknown Device',
      ...accessories.map(acc => `WITH ${acc.name?.toUpperCase() || ''}`)
    ];

    const rightCells = [];
    
    if (equipment.type === 'laptop') {
      if (equipment.assetTag) rightCells.push(equipment.assetTag);
      if (equipment.serviceTag) rightCells.push(equipment.serviceTag);
      if (equipment.warrantyExpiry) rightCells.push(equipment.warrantyExpiry);
    } else if (equipment.type === 'phone') {
      if (equipment.imei) rightCells.push(equipment.imei);
      if (equipment.serial) rightCells.push(equipment.serial);
      if (equipment.assetTag) rightCells.push(equipment.assetTag);
    }

    return (
      <TableRow key={type}>
        <TableCell className="space-y-1">
          {type !== 'DEVICE' && (
            <Badge variant={type === 'NEW' ? 'default' : 'secondary'} className="text-xs mb-1">
              {type}
            </Badge>
          )}
          {leftColumn.map((line, index) => (
            <div key={index} className={index === 0 ? 'font-medium' : 'text-sm text-muted-foreground'}>
              {line}
            </div>
          ))}
        </TableCell>
        {rightCells.map((cell, index) => (
          <TableCell key={index} className="text-sm">
            {cell}
          </TableCell>
        ))}
      </TableRow>
    );
  };

  const isValid = validationIssues.length === 0;

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
            <p className="text-sm opacity-90">Review & Verify</p>
          </div>
        </div>
      </div>

      {/* Stepper */}
      <Stepper currentStep={4} steps={WORKFLOW_STEPS} />

      {/* Content */}
      <div className="p-4 space-y-6 pb-20">
        {/* Validation Status */}
        {validationIssues.length > 0 ? (
          <Card className="border-destructive/50 bg-destructive/5">
            <CardHeader>
              <div className="flex items-center space-x-2">
                <AlertCircle className="w-5 h-5 text-destructive" />
                <CardTitle className="text-destructive">Validation Issues</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <ul className="space-y-1 text-sm">
                {validationIssues.map((issue, index) => (
                  <li key={index} className="flex items-center space-x-2">
                    <div className="w-1 h-1 bg-destructive rounded-full" />
                    <span>{issue}</span>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        ) : (
          <Card className="border-success/50 bg-success/5">
            <CardContent className="pt-6">
              <div className="flex items-center space-x-2 text-success">
                <CheckCircle2 className="w-5 h-5" />
                <span>All validations passed</span>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Party Information */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle>Party Information</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => onEdit('party')}>
              <Edit className="w-4 h-4" />
            </Button>
          </CardHeader>
          <CardContent className="space-y-4">
            {Object.entries(partyData).map(([role, person]: [string, any]) => {
              if (!person) return null;
              
              return (
                <div key={role} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <h4 className="font-medium capitalize">{role.replace(/([A-Z])/g, ' $1').trim()}</h4>
                    <div className="flex space-x-1">
                      {person.confidence?.name && getConfidenceBadge(person.confidence.name)}
                      {person.confidence?.department && getConfidenceBadge(person.confidence.department)}
                      {person.confidence?.email && getConfidenceBadge(person.confidence.email)}
                    </div>
                  </div>
                  <div className="text-sm text-muted-foreground space-y-1">
                    <div><strong>Name:</strong> {person.name}</div>
                    <div><strong>Department:</strong> {person.department}</div>
                    <div><strong>Email:</strong> {person.email}</div>
                  </div>
                  {role !== 'returnedBy' && <Separator />}
                </div>
              );
            })}
          </CardContent>
        </Card>

        {/* Equipment Preview (PDF WYSIWYG) */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle>Equipment Details</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => onEdit('equipment')}>
              <Edit className="w-4 h-4" />
            </Button>
          </CardHeader>
          <CardContent>
            <div className="border rounded-lg overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Equipment Description</TableHead>
                    {equipmentData?.devices?.[0]?.type === 'laptop' && (
                      <>
                        <TableHead>Asset Tag</TableHead>
                        <TableHead>Service Tag</TableHead>
                        <TableHead>Warranty Expiry</TableHead>
                      </>
                    )}
                    {equipmentData?.devices?.[0]?.type === 'phone' && (
                      <>
                        <TableHead>IMEI</TableHead>
                        <TableHead>Serial</TableHead>
                        <TableHead>Asset Tag</TableHead>
                      </>
                    )}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {formType === 'replaced' ? (
                    <>
                      {renderEquipmentRow(
                        equipmentData?.devices?.[0] || {}, 
                        equipmentData?.devices?.filter(d => d.type === 'accessory') || [], 
                        'NEW'
                      )}
                      {renderEquipmentRow(
                        equipmentData?.devices?.[0] || {}, 
                        equipmentData?.devices?.filter(d => d.type === 'accessory') || [], 
                        'OLD'
                      )}
                    </>
                  ) : (
                    renderEquipmentRow(
                      equipmentData?.devices?.[0] || {}, 
                      equipmentData?.devices?.filter(d => d.type === 'accessory') || [], 
                      'DEVICE'
                    )
                  )}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>

        {/* Workflow Information */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle>Workflow Details</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => onEdit('workflow')}>
              <Edit className="w-4 h-4" />
            </Button>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
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
              {(formType === 'returned' || formType === 'replaced') && (
                <div>
                  <strong>Data Handling:</strong>
                  <div className={`${workflowData.dataHandlingConfirmed ? 'text-success' : 'text-destructive'}`}>
                    {workflowData.dataHandlingConfirmed ? 'Confirmed' : 'Not Confirmed'}
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* PDF Preview Notice */}
        <Card className="bg-muted/50">
          <CardContent className="pt-6">
            <div className="flex items-start space-x-3">
              <FileText className="w-5 h-5 text-muted-foreground mt-0.5" />
              <div>
                <p className="font-medium">PDF Preview</p>
                <p className="text-sm text-muted-foreground">
                  The table above shows exactly how your form will appear in the generated PDF. 
                  Review all information carefully before proceeding.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-background border-t border-border">
        <Button
          onClick={onComplete}
          disabled={!isValid}
          className="w-full h-12"
        >
          Generate PDF & Export
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}