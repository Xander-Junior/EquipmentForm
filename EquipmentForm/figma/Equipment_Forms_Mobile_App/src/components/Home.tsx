import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Stepper } from "./Stepper";
import { Package, PackageCheck, RotateCcw, Settings, User } from "lucide-react";

interface HomeProps {
  onFormTypeSelect: (type: 'received' | 'returned' | 'replaced') => void;
  onProfileEdit: () => void;
  onShowDiagnostics: () => void;
  profileName: string;
}

const WORKFLOW_STEPS = [
  { id: 1, label: "Party", description: "People involved" },
  { id: 2, label: "Equipment", description: "Device details" },
  { id: 3, label: "Workflow", description: "Dates & process" },
  { id: 4, label: "Review", description: "Verify & export" }
];

export function Home({ onFormTypeSelect, onProfileEdit, onShowDiagnostics, profileName }: HomeProps) {
  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-primary text-primary-foreground p-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl">Equipment Forms</h1>
            <p className="text-sm opacity-90">Tullow Oil</p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={onProfileEdit}
            className="text-primary-foreground hover:bg-primary-foreground/10"
          >
            <User className="w-4 h-4 mr-2" />
            {profileName}
          </Button>
        </div>
      </div>

      {/* Stepper */}
      <Stepper currentStep={1} steps={WORKFLOW_STEPS} />

      {/* Form Type Selection */}
      <div className="p-4 space-y-4">
        <div className="text-center mb-6">
          <h2 className="text-lg mb-2">Select Form Type</h2>
          <p className="text-muted-foreground text-sm">Choose the type of equipment form you need to fill out</p>
        </div>

        <div className="space-y-4 max-w-md mx-auto">
          {/* Equipment Received */}
          <Card 
            className="cursor-pointer transition-all duration-200 hover:shadow-lg hover:scale-[1.02] border-2 hover:border-[rgb(75,160,70)] active:scale-[0.98]"
            onClick={() => onFormTypeSelect('received')}
          >
            <CardHeader className="pb-3">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-[rgb(75,160,70)]/10 rounded-lg flex items-center justify-center">
                  <Package className="w-6 h-6 text-[rgb(75,160,70)]" />
                </div>
                <div className="flex-1">
                  <CardTitle>Equipment Received</CardTitle>
                  <CardDescription>New equipment issued to staff</CardDescription>
                </div>
              </div>
            </CardHeader>
          </Card>

          {/* Equipment Returned */}
          <Card 
            className="cursor-pointer transition-all duration-200 hover:shadow-lg hover:scale-[1.02] border-2 hover:border-[rgb(250,150,30)] active:scale-[0.98]"
            onClick={() => onFormTypeSelect('returned')}
          >
            <CardHeader className="pb-3">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-[rgb(250,150,30)]/10 rounded-lg flex items-center justify-center">
                  <PackageCheck className="w-6 h-6 text-[rgb(250,150,30)]" />
                </div>
                <div className="flex-1">
                  <CardTitle>Equipment Returned</CardTitle>
                  <CardDescription>Equipment returned by staff</CardDescription>
                </div>
              </div>
            </CardHeader>
          </Card>

          {/* Equipment Replaced */}
          <Card 
            className="cursor-pointer transition-all duration-200 hover:shadow-lg hover:scale-[1.02] border-2 hover:border-[rgb(255,190,20)] active:scale-[0.98]"
            onClick={() => onFormTypeSelect('replaced')}
          >
            <CardHeader className="pb-3">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-[rgb(255,190,20)]/10 rounded-lg flex items-center justify-center">
                  <RotateCcw className="w-6 h-6 text-[rgb(255,190,20)]" />
                </div>
                <div className="flex-1">
                  <CardTitle>Equipment Replaced</CardTitle>
                  <CardDescription>Replace existing equipment</CardDescription>
                </div>
              </div>
            </CardHeader>
          </Card>
        </div>

        {/* Footer */}
        <div className="fixed bottom-4 right-4">
          <Button
            variant="outline"
            size="sm"
            className="rounded-full border-primary/20 hover:bg-primary/5"
            onClick={onShowDiagnostics}
          >
            <Settings className="w-4 h-4 mr-2" />
            Diagnostics
          </Button>
        </div>
      </div>
    </div>
  );
}